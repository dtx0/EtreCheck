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
#import "NSDate+Etresoft.h"

@implementation LaunchdCollector

// These need to be shared by all launchd collector objects.
@dynamic launchdStatus;
@dynamic appleLaunchd;
@synthesize showExecutable = myShowExecutable;
@synthesize pressureKilledCount = myPressureKilledCount;
@synthesize AppleNotLoadedCount = myAppleNotLoadedCount;
@synthesize AppleLoadedCount = myAppleLoadedCount;
@synthesize AppleRunningCount = myAppleRunningCount;
@synthesize AppleKilledCount = myAppleKilledCount;
@dynamic knownAppleFailures;
@dynamic knownAppleSignatureFailures;

#pragma mark - Properties

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

#pragma mark - Launchd routines

// Collect the status of all launchd items.
- (void) collect
  {
  // Don't do this more than once.
  if([self.launchdStatus count])
    return;
    
  [self
    updateStatus: NSLocalizedString(@"Checking launchd information", NULL)];
  
  // Collect all launchd items.
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
    
    if(label)
      if(![self.launchdStatus objectForKey: label])
        {
        NSMutableDictionary * jobData =
          [NSMutableDictionary dictionaryWithDictionary: job];
        
        // I don't want all of the keys, only a few.
        NSNumber * lastExitStatus =
          [jobData objectForKey: @"LastExitStatus"];
        NSNumber * PID =
          [jobData objectForKey: @"PID"];
        
        NSMutableDictionary * status = [NSMutableDictionary new];
        
        [status setObject: label forKey: kLabel];
        [status setObject: [NSNumber numberWithBool: NO] forKey: kPrinted];
        [status setObject: [NSNumber numberWithBool: NO] forKey: kIgnored];
        
        if(lastExitStatus)
          [status setObject: lastExitStatus forKey: @"LastExitStatus"];
    
        if(PID)
          [status setObject: PID forKey: @"PID"];

        [self.launchdStatus setObject: status forKey: label];
        
        [status release];
        }
    }
    
  CFRelease(jobs);
  }

#pragma mark - Expected items

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
  [failures addObject: @"com.apple.SafariNotificationAgent.plist"];

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
  [failures addObject: @"com.apple.photostream-agent"];
  [failures addObject: @"com.apple.MRTd.plist"];
  [failures addObject: @"com.apple.MRTa.plist"];
  [failures addObject: @"com.apple.java.InstallOnDemand.plist"];

  return failures;
  }

#pragma mark - Collection

// Collect property list files.
// Returns an array of labels for printing.
- (NSArray *) collectPropertyListFiles: (NSArray *) paths
  {
  NSMutableArray * plists = [NSMutableArray array];
  
  for(NSString * path in paths)
    {
    NSMutableDictionary * plist = [self collectPropertyListFile: path];
    
    if(plist)
      [plists addObject: plist];
    }
    
  return plists;
  }

// Collect a single property list file.
- (NSMutableDictionary *) collectPropertyListFile: (NSString *) path
  {
  NSString * file = [path lastPathComponent];
  
  // Ignore .DS_Store files.
  if([file isEqualToString: @".DS_Store"])
    return nil;
    
  // Ignore zero-byte files.
  NSDictionary * attributes =
    [[NSFileManager defaultManager]
      attributesOfItemAtPath: path error: NULL];
  
  if([attributes fileSize] == 0)
    return nil;
    
  // Collect the info.
  return [self collectLaunchdItemInfo: path];
  }

// Collect the status of a launchd item.
- (NSMutableDictionary *) collectLaunchdItemInfo: (NSString *) path
  {
  // I need this.
  NSString * filename = [path lastPathComponent];
  
  // Get the status and plist and use them to seed the info.
  NSMutableDictionary * info =
    [NSMutableDictionary
      dictionaryWithDictionary: [self collectJobStatus: path]];
    
  // See if the executable is valid.
  // Don't bother with this.
  //if(![self isValidExecutable: executable])
  //  jobStatus = kStatusInvalid;
    
  // Set attributes.
  [info setObject: path forKey: kPath];
  
  [info
    setObject: [NSNumber numberWithBool: [self isAppleFile: filename]]
    forKey: kApple];
  
  [info
    setObject: [Utilities sanitizeFilename: filename] forKey: kFilename];
  
  [info
    setObject: [self getSupportURL: nil bundleID: path]
    forKey: kSupportURL];
  
  if([filename hasPrefix: @"."])
    [info setObject: [NSNumber numberWithBool: YES] forKey: kHidden];
    
  [self setDetailsURL: info];
  [self setExecutable: info];
  
  // For now, don't bother checking Apple files for unknown or adware
  // status.
  if([[info objectForKey: kApple] boolValue])
    return [self collectAppleLaunchdItemInfo: info];
    
  [self setUnknownForPath: path info: info];
  [self setAdwareForPath: path info: info];

  return info;
  }

// Get the job status.
- (NSMutableDictionary *) collectJobStatus: (NSString *) path
  {
  // Get the properties.
  NSDictionary * plist = [NSDictionary readPropertyList: path];

  if(plist)
    {
    NSMutableDictionary * info =
      [NSMutableDictionary dictionaryWithDictionary: plist];
    
    NSString * label = [plist objectForKey: @"Label"];
      
    if(label)
      {
      NSMutableDictionary * status =
        [self collectJobStatusForLabel: label];
      
      [info addEntriesFromDictionary: status];
      
      return info;
      }
    }
    
  return nil;
  }

// Collect the job status for a label.
- (NSMutableDictionary *) collectJobStatusForLabel: (NSString *) label
  {
  NSMutableDictionary * status =
    [self.launchdStatus objectForKey: label];

  NSNumber * pid = [status objectForKey: @"PID"];
  NSNumber * lastExitStatus = [status objectForKey: @"LastExitStatus"];

  long exitStatus = [lastExitStatus intValue];
  
  NSString * jobStatus = kStatusUnknown;

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
    
  // I need to check for status == nil for "not loaded", so I have
  // to wait to create a new status in that case.
  if(!status)
    {
    status = [NSMutableDictionary new];
    [self.launchdStatus setObject: status forKey: label];
    [status release];
    }
    
  [status setObject: jobStatus forKey: kStatus];
  [status setObject: label forKey: kLabel];
  
  return status;
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
    if([bundleID hasPrefix: @"0x"])
      if([bundleID rangeOfString: @".mach_init."].location != NSNotFound)
        return YES;
    }

  return NO;
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

// Set the details URL.
- (void) setDetailsURL: (NSMutableDictionary *) info
  {
  NSAttributedString * detailsURL = nil;
  
  NSString * jobStatus = [info objectForKey: kStatus];
  
  if([jobStatus isEqualToString: kStatusFailed])
    {
    NSString * executableName =
      [[info objectForKey: kExecutable] lastPathComponent];

    if([[Model model] hasLogEntries: executableName])
      detailsURL = [[Model model] getDetailsURLFor: executableName];
    }
    
  if(detailsURL)
    [info setObject: detailsURL forKey: kDetailsURL];
  }

// Set command and executable information.
- (void) setExecutable: (NSMutableDictionary *) info
  {
  // Get the command.
  NSArray * command = [self collectLaunchdItemCommand: info];
  
  if([command count])
    {
    // Get the executable.
    NSString * executable = [self collectLaunchdItemExecutable: command];
  
    [info setObject: command forKey: kCommand];
    [info setObject: executable forKey: kExecutable];
    }
  }

// Collect the command of the launchd item.
- (NSArray *) collectLaunchdItemCommand: (NSDictionary *) info
  {
  NSMutableArray * command = [NSMutableArray array];
  
  if(info)
    {
    NSString * program = [info objectForKey: @"Program"];
    
    if(program)
      [command addObject: program];
      
    NSArray * arguments = [info objectForKey: @"ProgramArguments"];
    
    if([arguments respondsToSelector: @selector(isEqualToArray:)])
      if(arguments.count > 0)
        {
        NSString * argument = [arguments objectAtIndex: 0];
        
        if(![argument isEqualToString: [program lastPathComponent]])
          [command addObject: argument];
          
        for(int i = 1; i < arguments.count; ++i)
          [command addObject: [arguments objectAtIndex: i]];
      }
    }
    
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
        {
        executable = argument;
        break;
        }
      }
    }
    
  return executable;
  }

// Collect the status of an Apple launchd item.
- (NSMutableDictionary *) collectAppleLaunchdItemInfo:
  (NSMutableDictionary *) info
  {
  if(![info objectForKey: kSignature])
    {
    NSString * executable = [info objectForKey: kExecutable];

    [info
      setObject: [Utilities checkAppleExecutable: executable]
      forKey: kSignature];
    }
    
  return info;
  }

// Set the unknown flag for a file.
- (void) setUnknownForPath: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  // I need this.
  NSString * filename = [path lastPathComponent];
  
  // See if this file is known (whitelist or adware). If not, double-check
  // to see if it should be exempted from unknown files.
  // This will record adware as a side effect.
  bool knownFile = [[Model model] isKnownFile: filename path: path];
  
  if(!knownFile)
    if([self isWhitelistException: info path: path])
      knownFile = YES;
    
  [info
    setObject: [NSNumber numberWithBool: !knownFile] forKey: kUnknown];
  }

// Remove any files from the list of unknown files if they match certain
// criteria.
- (bool) isWhitelistException: (NSDictionary *) info
  path: (NSString *) path
  {
  bool whitelist = NO;
  
  // Special case for Folder Actions Dispatcher.
  NSArray * command = [info objectForKey: kCommand];

  for(NSString * part in command)
    {
    NSRange foundRange = [part rangeOfString: @"Folder Actions Dispatcher"];
    
    if(foundRange.location != NSNotFound)
      whitelist = true;
    }
    
  if(whitelist)
    [[[Model model] unknownFiles] removeObject: path];
    
  return whitelist;
  }

// Set adware status for a file.
- (void) setAdwareForPath: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  BOOL adware = [[Model model] isAdware: path];
    
  [info setObject: [NSNumber numberWithBool: adware] forKey: kAdware];
  }

#pragma mark - Print property lists

// Print property lists files.
- (void) printPropertyLists: (NSArray *) plists
  {
  NSMutableAttributedString * formattedOutput =
    [self formatPropertyLists: plists];

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
- (NSMutableAttributedString *) formatPropertyLists: (NSArray *) plists
  {
  NSMutableAttributedString * formattedOutput =
    [NSMutableAttributedString new];

  [formattedOutput autorelease];
  
  bool haveOutput = NO;
  
  NSArray * sortedPlists =
    [plists
      sortedArrayUsingComparator:
        ^NSComparisonResult(id obj1, id obj2)
          {
          NSString * name1 = [obj1 objectForKey: kPath];
          NSString * name2 = [obj2 objectForKey: kPath];

          return [name1 compare: name2];
          }];
    
  for(NSMutableDictionary * plist in sortedPlists)
    if([self formatPropertyList: plist output: formattedOutput])
      haveOutput = YES;
      
  if([[Model model] hideAppleTasks])
    if([self formatAppleCounts: formattedOutput])
      haveOutput = YES;
  
  if(!haveOutput)
    return nil;
    
  return formattedOutput;
  }

// Format property list file.
// Return YES if there was any output.
- (bool) formatPropertyList: (NSMutableDictionary *) info
  output: (NSMutableAttributedString *) output
  {
  NSString * path = [info objectForKey: kPath];

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
    
  // It is a plist file at least.
  return
    [self
      formatValidPropertyListFile: path
      info: (NSMutableDictionary *) info
      output: output];
  }

// Format a valid property list file.
- (bool) formatValidPropertyListFile: (NSString *) path
  info: (NSMutableDictionary *) info
  output: (NSMutableAttributedString *) output
  {
  [info
    setObject: [self modificationDate: path] forKey: kModificationDate];

  // Apples file get special treatment.
  if([[info objectForKey: kApple] boolValue])
    if(![self formatApplePropertyListFile: path info: info])
      return NO;
    
  NSString * filename = [info objectForKey: kFilename];

  // Save the command.
  NSArray * command = [info objectForKey: kCommand];
  
  if([command count])
    [[[Model model] launchdCommands]
      setObject: [command componentsJoinedByString: @" "] forKey: path];
    
  // Format the status.
  [output appendAttributedString: [self formatPropertyListStatus: info]];
  
  // Add the name.
  [output appendString: filename];
  
  // Add any extra content.
  [output
    appendAttributedString: [self formatExtraContent: info for: path]];
  
  [output appendString: @"\n"];
  
  NSString * label = [info objectForKey: kLabel];
  
  NSMutableDictionary * status = [self.launchdStatus objectForKey: label];
  
  [status setObject: [NSNumber numberWithBool: YES] forKey: kPrinted];
  
  return YES;
  }

// Format an Apple property list file.
// Returns NO if the Apple task should be hidden.
- (bool) formatApplePropertyListFile: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  NSString * file = [path lastPathComponent];

  bool hideAppleTasks = [[Model model] hideAppleTasks];

  [self updateAppleCounts: info];
  
  NSString * signatureStatus = [info objectForKey: kSignature];
  NSNumber * ignore = [NSNumber numberWithBool: hideAppleTasks];
    
  NSString * label = [info objectForKey: kLabel];
  NSMutableDictionary * status = [self.launchdStatus objectForKey: label];
  
  // I may want to report a failure.
  if([[info objectForKey: kStatus] isEqualToString: kStatusFailed])
    {
    // Should I ignore this failure?
    if([self ignoreFailuresOnFile: file])
      {
      [status setObject: ignore forKey: kIgnored];

      if(hideAppleTasks)
        return NO;
      }
    }
    
  else if([[info objectForKey: kStatus] isEqualToString: kStatusKilled])
    {
    [status setObject: ignore forKey: kIgnored];
    
    if(hideAppleTasks)
      return NO;
    }
    
  else if([signatureStatus isEqualToString: kSignatureValid])
    {
    [status setObject: ignore forKey: kIgnored];
    
    if(hideAppleTasks)
      return NO;
    }
    
  // Should I ignore this failure?
  else if([self ignoreInvalidSignatures: file])
    {
    [status setObject: ignore forKey: kIgnored];

    if(hideAppleTasks)
      return NO;
    }
    
  return YES;
  }

// Format Apple counts.
// Return YES if there was any output.
- (bool) formatAppleCounts: (NSMutableAttributedString *) output
  {
  bool haveOutput = NO;
  
  haveOutput =
    [self
      formatAppleCount: self.AppleNotLoadedCount
      output: output
      status: kStatusNotLoaded]
      || haveOutput;
  
  haveOutput =
    [self
      formatAppleCount: self.AppleLoadedCount
      output: output
      status: kStatusLoaded]
      || haveOutput;

  haveOutput =
    [self
      formatAppleCount: self.AppleRunningCount
      output: output
      status: kStatusRunning]
      || haveOutput;

  haveOutput =
    [self
      formatAppleCount: self.AppleKilledCount
      output: output
      status: kStatusKilled]
      || haveOutput;

  return haveOutput;
  }

// Format Apple counts for a given status.
// Return YES if there was any output.
- (bool) formatAppleCount: (NSUInteger) count
  output: (NSMutableAttributedString *) output
  status: (NSString *) statusString
  {
  if(count)
    {
    NSDictionary * status =
      [NSDictionary
        dictionaryWithObjectsAndKeys: statusString, kStatus, nil];
      
    [output
      appendAttributedString: [self formatPropertyListStatus: status]];
    
    [output
      appendString: TTTLocalizedPluralString(count, @"applecount", nil)];
    
    [output appendString: @"\n"];
      
    return YES;
    }
    
  return NO;
  }

// Handle whitelist exceptions.
- (void) updateAppleCounts: (NSDictionary *) info
  {
  if([[info objectForKey: kStatus] isEqualToString: kStatusNotLoaded])
    self.AppleNotLoadedCount = self.AppleNotLoadedCount + 1;
  else if([[info objectForKey: kStatus] isEqualToString: kStatusLoaded])
    self.AppleLoadedCount = self.AppleLoadedCount + 1;
  else if([[info objectForKey: kStatus] isEqualToString: kStatusRunning])
    self.AppleRunningCount = self.AppleRunningCount + 1;
  else if([[info objectForKey: kStatus] isEqualToString: kStatusKilled])
    self.AppleKilledCount = self.AppleKilledCount + 1;
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
    
  // Xcode is too big to even check unless you have an SSD.
  if([file hasPrefix: @"com.apple.dt.Xcode"])
    return YES;
    
  // No point in checking what always fails.
  if([file hasPrefix: @"com.apple.photostream-agent"])
    return YES;

  return [self.knownAppleSignatureFailures containsObject: file];
  }

// Update a funky new dynamic task.
- (void) updateDynamicTask: (NSMutableDictionary *) info
  domain: (NSString *) domain
  {
  if([[Model model] majorOSVersion] < kYosemite)
    return;
    
  NSString * label = [info objectForKey: kLabel];
  
  unsigned int UID = getuid();

  NSString * serviceName =
    [NSString stringWithFormat: @"%@/%d/%@", domain, UID, label];
  
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
      [info setObject: [NSNumber numberWithBool: YES] forKey: kApp];
    else if([trimmedLine hasPrefix: @"program = "])
      {
      NSString * executable = [trimmedLine substringFromIndex: 10];
      
      [info setObject: executable forKey: kExecutable];
      
      [self updateModificationDate: info path: executable];
      }
    else if([trimmedLine hasPrefix: @"parent bundle identifier = "])
      [self
        updateModificationDate: info
        bundleID: [trimmedLine substringFromIndex: 27]];
    else if([trimmedLine hasPrefix: @"pid = "])
      [[self.launchdStatus objectForKey: label]
        setObject: kStatusRunning forKey: label];
    }
  }

// Update the modification date.
- (void) updateModificationDate: (NSMutableDictionary *) status
  path: (NSString *) path
  {
  NSDate * currentModificationDate =
    [status objectForKey: kModificationDate];
  
  NSDate * modificationDate = [self modificationDate: path];
  
  if([modificationDate isLaterThan: currentModificationDate])
    [status setObject: modificationDate forKey: kModificationDate];
  }

// Update the modification date.
- (void) updateModificationDate: (NSMutableDictionary *) info
  bundleID: (NSString *) bundleID
  {
  NSURL * url =
    [[NSWorkspace sharedWorkspace]
      URLForApplicationWithBundleIdentifier: bundleID];
    
  if(url)
    [self updateModificationDate: info path: [url path]];
  }

// Get the modification date of a file.
- (NSDate *) modificationDate: (NSString *) path
  {
  NSRange appRange = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(appRange.location != NSNotFound)
    path = [path substringToIndex: appRange.location + 4];

  return [Utilities modificationDate: path];
  }

// Format a codesign response.
- (NSString *) formatAppleSignature: (NSDictionary *) info
  {
  NSString * message = @"";
  
  NSString * signature = [info objectForKey: kSignature];
  
  NSString * path = [info objectForKey: kExecutable];
  
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
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) info
  {
  NSString * statusString = NSLocalizedString(@"[not loaded]", NULL);
  NSColor * color = [[Utilities shared] gray];
  
  NSString * statusCode = [info objectForKey: kStatus];
  
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
- (NSAttributedString *) formatExtraContent: (NSMutableDictionary *) info
  for: (NSString *) path
  {
  // I need to check again for adware due to the agent/daemon/helper adware
  // trio.
  if([[Model model] isAdware: path])
    [info setObject: [NSNumber numberWithBool: YES] forKey: kAdware];
    
  if([[info objectForKey: kApple] boolValue])
    return [self formatApple: info for: path];
    
  else if([[info objectForKey: kAdware] boolValue])
    return [self formatAdware: info for: path];
    
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  NSDate * modificationDate =
    [info objectForKey: kModificationDate];

  NSString * modificationDateString =
    [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"];
  
  if(modificationDateString)
    [extra
      appendString:
        [NSString stringWithFormat: @" (%@)", modificationDateString]];

  [extra appendAttributedString: [self formatSupportLink: info]];
  
  return [extra autorelease];
  }

// Format adware.
- (NSAttributedString *) formatAdware: (NSDictionary *) info
  for: (NSString *) path
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  NSDate * modificationDate =
    [info objectForKey: kModificationDate];

  NSString * modificationDateString =
    [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"];
  
  if(modificationDateString)
    [extra
      appendString:
        [NSString stringWithFormat: @" (%@)", modificationDateString]];

  [extra appendString: @" "];

  [extra
    appendString: NSLocalizedString(@"Adware!", NULL)
    attributes:
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
    
  NSAttributedString * removeLink = [self generateRemoveAdwareLink];

  if(removeLink)
    {
    [extra appendString: @" "];
    
    [extra appendAttributedString: removeLink];
    }
    
  NSString * executable = [info objectForKey: kExecutable];
  
  if([executable length] > 0)
    if([[NSFileManager defaultManager] fileExistsAtPath: executable])
      {
      [extra appendString: @"\n        "];
      [extra appendString: [Utilities cleanPath: executable]];
      }
    
  return [extra autorelease];
  }

// Format Apple software.
- (NSAttributedString *) formatApple: (NSDictionary *) info
  for: (NSString *) path
  {
  NSString * signatureStatus = [info objectForKey: kSignature];
  
  if(![signatureStatus isEqualToString: kSignatureValid])
    {
    NSMutableAttributedString * extra =
      [[NSMutableAttributedString alloc] init];

    NSDate * modificationDate =
      [info objectForKey: kModificationDate];

    NSString * modificationDateString =
      [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"];
    
    if(modificationDateString)
      [extra
        appendString:
          [NSString stringWithFormat: @" (%@)", modificationDateString]];

    NSString * message = [self formatAppleSignature: info];
      
    [extra
      appendString: message
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    return [extra autorelease];
    }
    
  return [self formatSupportLink: info];
  }

// Create a support link for a plist dictionary.
- (NSAttributedString *) formatSupportLink: (NSDictionary *) info
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  // Get the support link.
  if([[info objectForKey: kSupportURL] length])
    {
    [extra appendString: @" "];

    [extra
      appendString: NSLocalizedString(@"[Support]", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : [info objectForKey: kSupportURL]
        }];
    }
    
  // Get the details link.
  NSAttributedString * detailsURL = [info objectForKey: kDetailsURL];
  
  if([detailsURL length])
    {
    [extra appendString: @" "];

    [extra appendAttributedString: detailsURL];
    }

  // Show what is being hidden.
  if([[info objectForKey: kHidden] boolValue] || self.showExecutable)
    [extra appendString:
      [NSString
        stringWithFormat:
          @"\n        %@",
          [Utilities
            formatExecutable: [info objectForKey: kCommand]]]];
    
  return [extra autorelease];
  }

@end
