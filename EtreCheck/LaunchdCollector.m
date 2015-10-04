/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchdCollector.h"
#import <ServiceManagement/ServiceManagement.h>
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"
#import "TTTLocalizedPluralString.h"

@implementation LaunchdCollector

// These need to be shared by all launchd collector objects.
@dynamic launchdStatus;
@dynamic appleLaunchd;
@synthesize showExecutable = myShowExecutable;
@synthesize pressureKilledCount = myPressureKilledCount;
@dynamic knownAppleFailures;
@dynamic knownAppleSignatureFailures;

// Property accessors to route through a singleton.
- (NSMutableDictionary *) launchdStatus
  {
  return [LaunchdCollector launchdStatus];
  }

- (NSMutableSet *) appleLaunchd
  {
  return [LaunchdCollector appleLaunchd];
  }

- (NSMutableSet *) knownAppleFailures
  {
  return [LaunchdCollector knownAppleFailures];
  }

- (NSMutableSet *) knownAppleSignatureFailures
  {
  return [LaunchdCollector knownAppleSignatureFailures];
  }

// Singleton accessor for launchd status.
+ (NSMutableDictionary *) launchdStatus
  {
  static NSMutableDictionary * dictionary = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     dictionary = [NSMutableDictionary new];
    });
    
  return dictionary;
  }

// Singleton access for Apple launchd items.
+ (NSMutableSet *) appleLaunchd
  {
  static NSMutableSet * set = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     set = [NSMutableSet new];
    });
    
  return set;
  }

// Singleton access for Apple known filure items.
+ (NSMutableSet *) knownAppleFailures
  {
  static NSMutableSet * set = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     set = [NSMutableSet new];
    });
    
  return set;
  }

// Singleton access for Apple known signature failure items.
+ (NSMutableSet *) knownAppleSignatureFailures
  {
  static NSMutableSet * set = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     set = [NSMutableSet new];
    });
    
  return set;
  }

// Release memory.
+ (void) cleanup
  {
  [[LaunchdCollector launchdStatus] release];
  [[LaunchdCollector appleLaunchd] release];
  }

// Collect the status of all launchd items.
- (void) collect
  {
  if([self.launchdStatus count])
    return;
    
  [self
    updateStatus: NSLocalizedString(@"Checking launchd information", NULL)];
  
  [self collectLaunchdStatus: kSMDomainSystemLaunchd];

  [self collectLaunchdStatus: kSMDomainUserLaunchd];
  
  // Add expected items that ship with the OS.
  [self setupExpectedItems];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect launchd status for a particular domain.
- (void) collectLaunchdStatus: (CFStringRef) domain
  {
  // Get the last exist result for all jobs in this domain.
  CFArrayRef jobs = SMCopyAllJobDictionaries(domain);

  if(!jobs)
    return;

  for(NSDictionary * job in (NSArray *)jobs)
    {
    NSString * label = [job objectForKey: @"Label"];
    
    NSMutableDictionary * jobData =
      [NSMutableDictionary dictionaryWithDictionary: job];
    
    jobData[kPrinted] = @NO;
    jobData[kHidden] = @NO;
    
    if(label)
      [self.launchdStatus setObject: jobData forKey: label];
    }
    
  CFRelease(jobs);
  }

// Setup launchd items that are expected because they ship with the OS.
- (void) setupExpectedItems
  {
  [self setupOtherAppleFiles];
  [self setupKnownAppleFailures];
  [self setupKnownAppleSignatureFailures];
  }

// Setup Apple files files with 3rd party labels.
- (void) setupOtherAppleFiles
  {
  [self.appleLaunchd addObject: @"org.openbsd.ssh-agent.plist"];
  [self.appleLaunchd addObject: @"bootps.plist"];
  [self.appleLaunchd addObject: @"com.danga.memcached.plist"];
  [self.appleLaunchd addObject: @"com.vix.cron.plist"];
  [self.appleLaunchd addObject: @"exec.plist"];
  [self.appleLaunchd addObject: @"finger.plist"];
  [self.appleLaunchd addObject: @"ftp.plist"];
  [self.appleLaunchd addObject: @"ftp-proxy.plist"];
  [self.appleLaunchd addObject: @"login.plist"];
  [self.appleLaunchd addObject: @"ntalk.plist"];
  [self.appleLaunchd addObject: @"org.apache.httpd.plist"];
  [self.appleLaunchd addObject: @"org.cups.cups-lpd.plist"];
  [self.appleLaunchd addObject: @"org.cups.cupsd.plist"];
  [self.appleLaunchd addObject: @"org.freeradius.radiusd.plist"];
  [self.appleLaunchd addObject: @"org.isc.named.plist"];
  [self.appleLaunchd addObject: @"org.net-snmp.snmpd.plist"];
  [self.appleLaunchd addObject: @"org.ntp.ntpd.plist"];
  [self.appleLaunchd addObject: @"org.openldap.slapd.plist"];
  [self.appleLaunchd addObject: @"org.postfix.master.plist"];
  [self.appleLaunchd addObject: @"org.postfix.newaliases.plist"];
  [self.appleLaunchd addObject: @"org.postgresql.postgres_alt.plist"];
  [self.appleLaunchd addObject: @"shell.plist"];
  [self.appleLaunchd addObject: @"ssh.plist"];
  [self.appleLaunchd addObject: @"telnet.plist"];
  [self.appleLaunchd addObject: @"tftp.plist"];
  [self.appleLaunchd addObject: @"com.apple.appleseed.feedbackhelper"];

  // Snow Leopard.
  [self.appleLaunchd addObject: @"comsat.plist"];
  [self.appleLaunchd addObject: @"distccd.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.kadmind.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.krb5kdc.plist"];
  [self.appleLaunchd addObject: @"nmbd.plist"];
  [self.appleLaunchd addObject: @"org.amavis.amavisd.plist"];
  [self.appleLaunchd addObject: @"org.amavis.amavisd_cleanup.plist"];
  [self.appleLaunchd addObject: @"org.apache.httpd.plist"];
  [self.appleLaunchd addObject: @"org.x.privileged_startx.plist"];
  [self.appleLaunchd addObject: @"smbd.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.CCacheServer.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.KerberosAgent.plist"];
  [self.appleLaunchd addObject: @"org.x.startx.plist"];
  [self.appleLaunchd addObject: @"org.samba.winbindd.plist"];
  }

// Setup known Apple failures.
- (void) setupKnownAppleFailures
  {
  [self.knownAppleFailures addObject: @"com.apple.mtrecorder.plist"];
  [self.knownAppleFailures addObject: @"com.apple.spirecorder.plist"];
  [self.knownAppleFailures addObject: @"com.apple.MRTd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.MRTa.plist"];
  [self.knownAppleFailures addObject: @"com.apple.logd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.xprotectupdater.plist"];
  [self.knownAppleFailures addObject: @"com.apple.xprotectupdater.plist"];
  [self.knownAppleFailures addObject: @"com.apple.afpstat.plist"];
  [self.knownAppleFailures
    addObject: @"com.apple.KerberosHelper.LKDCHelper.plist"];
  [self.knownAppleFailures addObject: @"com.apple.emond.aslmanager.plist"];
  [self.knownAppleFailures addObject: @"com.apple.mrt.uiagent.plist"];
  [self.knownAppleFailures addObject: @"com.apple.accountsd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.wdhelper.plist"];
  [self.knownAppleFailures addObject: @"com.apple.suhelperd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.Kerberos.renew.plist"];
  [self.knownAppleFailures addObject: @"org.samba.winbindd.plist"];
  }

// Setup known Apple signature failures.
- (void) setupKnownAppleSignatureFailures
  {
  // Common to all OS versions.
  [self.knownAppleSignatureFailures
    addObject: @"com.apple.configureLocalKDC.plist"];
  [self.knownAppleSignatureFailures addObject: @"com.apple.efax.plist"];
  [self.knownAppleSignatureFailures
    addObject: @"com.apple.FileSyncAgent.sshd.plist"];
  [self.knownAppleSignatureFailures addObject: @"com.apple.locate.plist"];
  [self.knownAppleSignatureFailures addObject: @"org.cups.cupsd.plist"];
  [self.knownAppleSignatureFailures addObject: @"org.ntp.ntpd.plist"];
  [self.knownAppleSignatureFailures addObject: @"ssh.plist"];
    
  switch([[Model model] majorOSVersion])
    {
    case kSnowLeopard:
      [self.knownAppleSignatureFailures
        addObjectsFromArray: [self knownAppleSignatureFailures1006]];
      break;
    case kLion:
      [self.knownAppleSignatureFailures
        addObjectsFromArray: [self knownAppleSignatureFailures1007]];
      break;
    case kMountainLion:
      [self.knownAppleSignatureFailures
        addObjectsFromArray: [self knownAppleSignatureFailures1008]];
      break;
    case kMavericks:
      [self.knownAppleSignatureFailures
        addObjectsFromArray: [self knownAppleSignatureFailures1009]];
      break;
    case kYosemite:
      [self.knownAppleSignatureFailures
        addObjectsFromArray: [self knownAppleSignatureFailures1010]];
      break;
    case kElCapitan:
      [self.knownAppleSignatureFailures
        addObjectsFromArray: [self knownAppleSignatureFailures1011]];
      break;
    }
  }

// Setup known Apple signature failures.
- (NSArray *) knownAppleSignatureFailures1006
  {
  NSMutableArray * failures = [NSMutableArray array];

  [failures addObject: @"com.apple.pcastuploader.plist"];
  [failures addObject: @"com.apple.RemoteDesktop.plist"];
  [failures addObject: @"org.x.startx.plist"];
  [failures addObject: @"com.apple.AppleFileServer.plist"];
  [failures addObject: @"com.apple.NotificationServer.plist"];
  [failures addObject: @"com.apple.periodic-daily.plist"];
  [failures addObject: @"com.apple.periodic-monthly.plist"];
  [failures addObject: @"com.apple.periodic-weekly.plist"];
  [failures addObject: @"com.apple.smb.sharepoints.plist"];
  [failures addObject: @"com.apple.systemkeychain.plist"];
  [failures addObject: @"org.amavis.amavisd.plist"];
  [failures addObject: @"org.amavis.amavisd_cleanup.plist"];
  [failures addObject: @"org.samba.winbindd.plist"];

  return failures;
  }

// Setup known Apple signature failures.
- (NSArray *) knownAppleSignatureFailures1007
  {
  NSMutableArray * failures = [NSMutableArray array];

  [failures addObject: @"com.apple.AirPortBaseStationAgent.plist"];
  [failures addObject: @"com.apple.pcastuploader.plist"];
  [failures addObject: @"com.apple.screensharing.MessagesAgent.plist"];
  [failures addObject: @"com.apple.xgridd.keepalive.plist"];
  [failures addObject: @"org.x.startx.plist"];
  [failures addObject: @"com.apple.AppleFileServer.plist"];
  [failures addObject: @"com.apple.collabd.podcast-cache-updater.plist"];
  [failures addObject: @"com.apple.efilogin-helper.plist"];
  [failures addObject: @"com.apple.emlog.plist"];
  [failures addObject: @"com.apple.NotificationServer.plist"];
  [failures addObject: @"com.apple.pcastlibraryd.plist"];
  [failures addObject: @"com.apple.periodic-daily.plist"];
  [failures addObject: @"com.apple.periodic-monthly.plist"];
  [failures addObject: @"com.apple.periodic-weekly.plist"];
  [failures addObject: @"org.amavis.amavisd.plist"];
  [failures addObject: @"org.amavis.amavisd_cleanup.plist"];

  return failures;
  }

// Setup known Apple signature failures.
- (NSArray *) knownAppleSignatureFailures1008
  {
  NSMutableArray * failures = [NSMutableArray array];

  [failures addObject: @"com.apple.AirPortBaseStationAgent.plist"];
  [failures addObject: @"com.apple.emlog.plist"];
  [failures addObject: @"com.apple.gkreport.plist"];
  [failures addObject: @"com.apple.periodic-daily.plist"];
  [failures addObject: @"com.apple.periodic-monthly.plist"];
  [failures addObject: @"com.apple.periodic-weekly.plist"];
  [failures addObject: @"org.postgresql.postgres_alt.plist"];

  return failures;
  }

// Setup known Apple signature failures.
- (NSArray *) knownAppleSignatureFailures1009
  {
  NSMutableArray * failures = [NSMutableArray array];

  [failures addObject: @"com.apple.emlog.plist"];
  [failures addObject: @"com.apple.gkreport.plist"];
  [failures addObject: @"com.apple.postgres.plist"];
  [failures addObject: @"org.apache.httpd.plist"];
  [failures addObject: @"org.net-snmp.snmpd.plist"];

  return failures;
  }

// Setup known Apple signature failures.
- (NSArray *) knownAppleSignatureFailures1010
  {
  NSMutableArray * failures = [NSMutableArray array];

  [failures addObject: @"com.apple.Dock.plist"];
  [failures addObject: @"com.apple.Spotlight.plist"];
  [failures addObject: @"com.apple.systemprofiler.plist"];
  [failures addObject: @"com.apple.emlog.plist"];
  [failures addObject: @"com.apple.gkreport.plist"];
  [failures addObject: @"com.apple.ManagedClient.enroll.plist"];
  [failures addObject: @"com.apple.ManagedClient.plist"];
  [failures addObject: @"com.apple.ManagedClient.startup.plist"];
  [failures addObject: @"com.apple.postgres.plist"];
  [failures addObject: @"org.apache.httpd.plist"];
  [failures addObject: @"org.net-snmp.snmpd.plist"];

  return failures;
  }

// Setup known Apple signature failures.
- (NSArray *) knownAppleSignatureFailures1011
  {
  NSMutableArray * failures = [NSMutableArray array];
 
  [failures addObject: @"com.apple.emlog.plist"];
  [failures addObject: @"com.apple.gkreport.plist"];
  [failures addObject: @"org.apache.httpd.plist"];
  [failures addObject: @"org.net-snmp.snmpd.plist"];
  [failures addObject: @"org.postfix.newaliases.plist"];
  [failures addObject: @"com.apple.airplaydiagnostics.server.mac.plist"];

  return failures;
  }

// Format a list of files.
- (void) printPropertyListFiles: (NSArray *) paths
  {
  NSMutableAttributedString * formattedOutput =
    [self formatPropertyListFiles: paths];

  if(formattedOutput)
    {
    [self.result appendAttributedString: [self buildTitle]];

    [self.result appendAttributedString: formattedOutput];

    if(self.pressureKilledCount)
      [self.result
        appendString:
          TTTLocalizedPluralString(
            self.pressureKilledCount, @"pressurekilledcount", nil)
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    
    if(!self.launchdStatus)
      [self.result
        appendString:
          NSLocalizedString(
            @"    Launchd job status not available.\n", NULL)
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    [self.result appendCR];
    }
  }

// Format a list of files.
- (NSMutableAttributedString *) formatPropertyListFiles: (NSArray *) paths
  {
  NSMutableAttributedString * formattedOutput =
    [NSMutableAttributedString new];

  [formattedOutput autorelease];
  
  bool haveOutput = NO;
  
  NSArray * sortedPaths =
    [paths sortedArrayUsingSelector: @selector(compare:)];
  
  for(NSString * path in sortedPaths)
    if([self formatPropertyListFile: path output: formattedOutput])
      haveOutput = YES;
  
  if(!haveOutput)
    return nil;
    
  return formattedOutput;
  }

// Format property list file.
// Return YES if there was any output.
- (bool) formatPropertyListFile: (NSString *) path
  output: (NSMutableAttributedString *) output
  {
  NSString * file = [path lastPathComponent];
  
  // Ignore .DS_Store files.
  if([file isEqualToString: @".DS_Store"])
    return NO;
    
  // Ignore zero-byte files.
  NSDictionary * attributes =
    [[NSFileManager defaultManager]
      attributesOfItemAtPath: path error: NULL];
  
  if([attributes fileSize] == 0)
    return NO;
    
  // Get the status.
  NSMutableDictionary * status = [self collectLaunchdItemStatus: path];
    
  if(!status)
    return NO;
    
  bool hideAppleTasks = [[Model model] hideAppleTasks];
  NSNumber * ignore = [NSNumber numberWithBool: hideAppleTasks];

  // Apple file get special treatment.
  if([[status objectForKey: kApple] boolValue])
    {
    // I may want to report a failure.
    if([[status objectForKey: kStatus] isEqualToString: kStatusFailed])
      {
      // Should I ignore this failure?
      if([self ignoreFailuresOnFile: file])
        {
        status[kIgnored] = ignore;

        if(hideAppleTasks)
          return NO;
        }
      }
      
    else if([[status objectForKey: kStatus] isEqualToString: kStatusKilled])
      {
      }
      
    else if([status[kSignature] isEqualToString: kSignatureValid])
      {
      status[kIgnored] = ignore;
      
      if(hideAppleTasks)
        return NO;
      }
      
    // Should I ignore this failure?
    else if([self ignoreInvalidSignatures: file])
      {
      status[kIgnored] = ignore;

      if(hideAppleTasks)
        return NO;
      }
    }

  [output appendAttributedString: [self formatPropertyListStatus: status]];
  
  [output appendString: [status objectForKey: kFilename]];
  
  [output
    appendAttributedString: [self formatExtraContent: status for: path]];
  
  [output appendString: @"\n"];
    
  status[kPrinted] = @YES;
  
  return YES;
  }

// Collect the status of a launchd item.
- (NSMutableDictionary *) collectLaunchdItemStatus: (NSString *) path
  {
  // I need this.
  NSString * file = [path lastPathComponent];
  
  // Get the properties.
  NSDictionary * plist = [NSDictionary readPropertyList: path];

  // Get the status.
  NSMutableDictionary * status = [self collectJobStatus: plist];
    
  NSString * jobStatus = status[kStatus];
  
  // Get the command.
  NSArray * command = [self collectLaunchdItemCommand: plist];
  
  // See if the executable is valid.
  // Don't bother with this.
  //if(![self isValidExecutable: executable])
  //  jobStatus = kStatusInvalid;
    
  NSString * executable = [self collectLaunchdItemExecutable: command];
  NSString * name = [executable lastPathComponent];
  
  NSAttributedString * detailsURL = nil;
  
  if([jobStatus isEqualToString: kStatusFailed])
    if([[Model model] hasLogEntries: name])
      detailsURL = [[Model model] getDetailsURLFor: name];
  
  bool isApple = [self isAppleFile: file];
  
  status[kApple] = [NSNumber numberWithBool: isApple];
  status[kFilename] = [Utilities sanitizeFilename: file];
  status[kCommand] = command;
  status[kExecutable] = executable;
  status[kSupportURL] = [self getSupportURL: nil bundleID: path];
  
  if(detailsURL)
    status[kDetailsURL] = detailsURL;
    
  if([file hasPrefix: @"."])
    status[kHidden] = @YES;
    
  if(isApple && !status[kSignature])
    status[kSignature] = [Utilities checkAppleExecutable: executable];

  return status;
  }

// Get the job status.
- (NSMutableDictionary *) collectJobStatus: (NSDictionary *) plist
  {
  NSString * jobStatus = kStatusUnknown;

  if(plist)
    {
    NSString * label = [plist objectForKey: @"Label"];
      
    if(label)
      {
      NSMutableDictionary * status =
        [self.launchdStatus objectForKey: label];
    
      if(status == nil)
        status = [NSMutableDictionary new];
        
      NSNumber * pid = [status objectForKey: @"PID"];
      NSNumber * lastExitStatus = [status objectForKey: @"LastExitStatus"];

      long exitStatus = [lastExitStatus intValue];
      
      if(pid)
        jobStatus = kStatusRunning;
      else if(exitStatus == 172)
        {
        jobStatus = kStatusKilled;
        
        self.pressureKilledCount = self.pressureKilledCount + 1;
        }
      else if(exitStatus != 0)
        jobStatus = kStatusFailed;
      else if(status)
        jobStatus = kStatusLoaded;
      else
        jobStatus = kStatusNotLoaded;
        
      [status setObject: jobStatus forKey: kStatus];
      [status setObject: label forKey: kBundleID];
      
      return status;
      }
    }
    
  return nil;
  }

// Should I ignore failures?
- (bool) ignoreFailuresOnFile: (NSString *) file
  {
  if(![[Model model] ignoreKnownAppleFailures])
    return NO;
    
  return [self.knownAppleFailures containsObject: file];
  }

// Should I ignore these invalid signatures?
- (bool) ignoreInvalidSignatures: (NSString *) file
  {
  if(![[Model model] ignoreKnownAppleFailures])
    return NO;
    
  switch([[Model model] majorOSVersion])
    {
    case kSnowLeopard:
      break;
    case kLion:
      break;
    case kMountainLion:
      break;
    case kMavericks:
      break;
    case kYosemite:
      if([file hasPrefix: @"com.apple.mail"])
        return YES;
      else if([file hasPrefix: @"com.apple.Safari"])
        return YES;
      else if([file hasPrefix: @"com.apple.ActivityMonitor"])
        return YES;
      break;
    case kElCapitan:
      break;
    }
    
  return [self.knownAppleSignatureFailures containsObject: file];
  }

// Is this an Apple file that I expect to see?
- (bool) isAppleFile: (NSString *) bundleID
  {
  if([bundleID hasPrefix: @"com.apple."])
    return YES;
    
  if([self.appleLaunchd containsObject: bundleID])
    return YES;
    
  if([[Model model] majorOSVersion] < kYosemite)
    {
    if([bundleID hasPrefix: @"0x"])
      {
      if([bundleID rangeOfString: @".anonymous."].location != NSNotFound)
        return YES;
      }
    else if([bundleID hasPrefix: @"[0x"])
      {
      if([bundleID rangeOfString: @".com.apple."].location != NSNotFound)
        return YES;
      }
    }
    
  if([[Model model] majorOSVersion] < kLion)
    {
    if([bundleID hasPrefix: @"0x1"])
      if([bundleID rangeOfString: @".mach_init."].location != NSNotFound)
        return YES;
    }

  return NO;
  }

// Update a funky new dynamic task.
- (void) updateDynamicTask: (NSMutableDictionary *) status
  {
  if([[Model model] majorOSVersion] < kYosemite)
    return;
    
  NSString * bundleID = [status objectForKey: kBundleID];
  
  unsigned int UID = getuid();

  NSString * serviceName =
    [NSString stringWithFormat: @"gui/%d/%@", UID, bundleID];
  
  NSArray * args =
    @[
      @"print",
      serviceName
    ];
  
  NSData * data =
    [Utilities execute: @"/bin/launchctl" arguments: args];
  
  NSArray * lines = [Utilities formatLines: data];

  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      
    if([trimmedLine isEqualToString: @"app = 1"])
      status[kApp] = @YES;
    else if([trimmedLine hasPrefix: @"bundle id = "])
      status[kBundleID] = [trimmedLine substringFromIndex: 12];
    }
  }

// Format a codesign response.
- (NSString *) formatAppleSignature: (NSDictionary *) status
  {
  NSString * message = @"";
  
  NSString * signature = status[kSignature];
  
  NSString * path = status[kExecutable];
  
  if(![signature isEqualToString: kSignatureValid])
    {
    message = NSLocalizedString(@" - Invalid signature!", NULL);
  
    if([signature isEqualToString: kNotSigned])
      message = NSLocalizedString(@" - No signature!", NULL);
    else if([signature isEqualToString: kExecutableMissing])
      {
      if([path length])
        message =
          [NSString
            stringWithFormat:
              NSLocalizedString(@" - %@: Executable not found!", NULL),
              path];
      else
        message =
          [NSString
            stringWithFormat:
              NSLocalizedString(@" - Executable not found!", NULL)];
      }
    }
    
  return message;
  }

// Collect the command of the launchd item.
- (NSArray *) collectLaunchdItemCommand: (NSDictionary *) plist
  {
  NSMutableArray * command = [NSMutableArray array];
  
  if(plist)
    {
    NSString * program = [plist objectForKey: @"Program"];
    
    if(program)
      [command addObject: program];
      
    NSArray * arguments = [plist objectForKey: @"ProgramArguments"];
    
    if([arguments respondsToSelector: @selector(isEqualToArray:)])
      if(arguments.count > 0)
        {
        NSString * argument = arguments[0];
        
        if(![argument isEqualToString: [program lastPathComponent]])
          [command addObject: argument];
          
        for(int i = 1; i < arguments.count; ++i)
          [command addObject: arguments[i]];
      }
    }
    
  if(![command count])
    [command addObject: @""];
    
  return command;
  }

// Collect the actual executable from a command.
- (NSString *) collectLaunchdItemExecutable: (NSArray *) command
  {
  NSString * executable = [command firstObject];
  
  BOOL sandboxExec = NO;
  
  if([executable isEqualToString: @"sandbox-exec"])
    sandboxExec = YES;

  if([executable isEqualToString: @"/usr/bin/sandbox-exec"])
    sandboxExec = YES;
    
  if(sandboxExec)
    {
    NSUInteger argumentCount = command.count;
    
    for(NSUInteger i = 1; i < argumentCount; ++i)
      {
      NSString * argument = [command objectAtIndex: i];
      
      if([argument isEqualToString: @"-f"])
        ++i;
      else if([argument isEqualToString: @"-n"])
        ++i;
      else if([argument isEqualToString: @"-p"])
        ++i;
      else if([argument isEqualToString: @"-D"])
        ++i;
      else
        executable = argument;
      }
    }
    
  return executable;
  }

// Is the executable valid?
- (bool) isValidExecutable: (NSArray *) executable
  {
  NSString * program = [executable firstObject];
  
  if(program)
    {
    NSDictionary * attributes = [Utilities lookForFileAttributes: program];
    
    if(attributes)
      {
      NSUInteger permissions = attributes.filePosixPermissions;
      
      if(permissions & S_IXUSR)
        return YES;
        
      if(permissions & S_IXGRP)
        return YES;

      if(permissions & S_IXOTH)
        return YES;
      }
      //if([[NSFileManager defaultManager] isExecutableFileAtPath: program])
      //  return YES;
    }
    
  return NO;
  }

// Format a status string.
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) status
  {
  NSString * statusString = NSLocalizedString(@"[not loaded]", NULL);
  NSColor * color = [[Utilities shared] gray];
  
  NSString * statusCode = [status objectForKey: kStatus];
  
  if([statusCode isEqualToString: kStatusLoaded])
    {
    statusString = NSLocalizedString(@"[loaded]", NULL);
    color = [[Utilities shared] blue];
    }
  else if([statusCode isEqualToString: kStatusRunning])
    {
    statusString = NSLocalizedString(@"[running]", NULL);
    color = [[Utilities shared] green];
    }
  else if([statusCode isEqualToString: kStatusFailed])
    {
    statusString = NSLocalizedString(@"[failed]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusUnknown])
    {
    statusString = NSLocalizedString(@"[unknown]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusInvalid])
    {
    statusString = NSLocalizedString(@"[invalid?]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusKilled])
    {
    statusString = NSLocalizedString(@"[killed]", NULL);
    color = [[Utilities shared] red];
    }
  
  NSMutableAttributedString * output =
    [[NSMutableAttributedString alloc] init];
    
  [output
    appendString: [NSString stringWithFormat: @"    %@    ", statusString]
    attributes:
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          color, NSForegroundColorAttributeName, nil]];
  
  return [output autorelease];
  }

// Include any extra content that may be useful.
- (NSAttributedString *) formatExtraContent: (NSDictionary *) status
  for: (NSString *) path
  {
  if([[Model model] isAdware: path])
    {
    NSMutableAttributedString * extra =
      [[NSMutableAttributedString alloc] init];

    [extra appendString: @" "];

    NSString * adware = [[[Model model] adwareFiles] objectForKey: path];
    
    NSAttributedString * removeLink =
      [self generateRemoveAdwareLink: adware];

    if(removeLink)
      [extra appendAttributedString: removeLink];
    else
      [extra
        appendString: NSLocalizedString(@"Adware!", NULL)
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];      
      
    return [extra autorelease];
    }
  else if([status[kApple] boolValue])
    {
    if(![status[kSignature] isEqualToString: kSignatureValid])
      {
      NSMutableAttributedString * extra =
        [[NSMutableAttributedString alloc] init];

      NSString * message = [self formatAppleSignature: status];
        
      [extra
        appendString: message
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      return [extra autorelease];
      }
    }
    
  return [self formatSupportLink: status];
  }

// Create a support link for a plist dictionary.
- (NSAttributedString *) formatSupportLink: (NSDictionary *) status
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  // Get the support link.
  if([[status objectForKey: kSupportURL] length])
    {
    [extra appendString: @" "];

    [extra
      appendString: NSLocalizedString(@"[Click for support]", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : [status objectForKey: kSupportURL]
        }];
    }
    
  // Get the details link.
  NSAttributedString * detailsURL = [status objectForKey: kDetailsURL];
  
  if([detailsURL length])
    {
    [extra appendString: @" "];

    [extra appendAttributedString: detailsURL];
    }

  // Show what is being hidden.
  if([[status objectForKey: kHidden] boolValue] || self.showExecutable)
    [extra appendString:
      [NSString
        stringWithFormat:
          @"\n        %@",
          [Utilities
            formatExecutable: [status objectForKey: kCommand]]]];
    
  return [extra autorelease];
  }

// Try to construct a support URL.
- (NSString *) getSupportURL: (NSString *) name bundleID: (NSString *) path
  {
  NSString * bundleID = [path lastPathComponent];
  
  // If the file is from Apple, the user is already on ASC.
  if([self isAppleFile: bundleID])
    return @"";
    
  // See if I can construct a real web host.
  NSString * host = [self convertBundleIdToHost: bundleID];
  
  if(host)
    {
    // If I seem to have a web host, construct a support URL just for that
    // site.
    NSString * nameParameter =
      [name length]
        ? name
        : bundleID;

    return
      [NSString
        stringWithFormat:
          @"http://www.google.com/search?q=%@+support+site:%@",
          nameParameter, host];
    }
  
  // This file isn't following standard conventions. Look for uninstall
  // instructions.
  return
    [NSString
      stringWithFormat:
        @"http://www.google.com/search?q=%@+uninstall+support", bundleID];
  }

@end
