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

// Property accessors to route through a singleton.
- (NSMutableDictionary *) launchdStatus
  {
  return [LaunchdCollector launchdStatus];
  }

- (NSMutableSet *) appleLaunchd
  {
  return [LaunchdCollector appleLaunchd];
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
  
  for(NSString * path in paths)
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
    
  // Apple file get special treatment.
  if([[status objectForKey: kApple] boolValue])
    {
    // I may want to report a failure.
    if([[status objectForKey: kStatus] isEqualToString: kStatusFailed])
      {
      // Should I ignore this failure?
      if([self ignoreFailuresOnFile: file])
        {
        status[kIgnored] = @YES;

        return NO;
        }
      }
      
    else if([[status objectForKey: kStatus] isEqualToString: kStatusKilled])
      {
      }
      
    else if([status[kSignature] isEqualToString: kSignatureValid])
      {
      status[kIgnored] = @YES;
      
      return NO;
      }
      
    // Should I ignore this failure?
    else if([self ignoreInvalidSignatures: file])
      {
      status[kIgnored] = @YES;

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
  
  // Get the executable.
  NSArray * command = [self collectLaunchdItemExecutable: plist];
  
  // See if the executable is valid.
  // Don't bother with this.
  //if(![self isValidExecutable: executable])
  //  jobStatus = kStatusInvalid;
    
  NSString * executable = [command firstObject];
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
      
      return status;
      }
    }
    
  return nil;
  }

// Should I ignore failures?
- (bool) ignoreFailuresOnFile: (NSString *) file
  {
  if([file isEqualToString: @"com.apple.mtrecorder.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.spirecorder.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.MRTd.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.MRTa.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.logd.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.xprotectupdater.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.xprotectupdater.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.afpstat.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.KerberosHelper.LKDCHelper.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.emond.aslmanager.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.mrt.uiagent.plist"])
    return YES;

  // Mountain Lion
  else if([file isEqualToString: @"com.apple.accountsd.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.wdhelper.plist"])
    return YES;

  // Snow Leopard
  else if([file isEqualToString: @"com.apple.suhelperd.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.Kerberos.renew.plist"])
    return YES;
  
  else if([file isEqualToString: @"org.samba.winbindd.plist"])
    return YES;
    
  return NO;
  }

// Should I ignore these invalid signatures?
- (bool) ignoreInvalidSignatures: (NSString *) file
  {
  switch([[Model model] majorOSVersion])
    {
    case kSnowLeopard:
      if([file isEqualToString: @"com.apple.pcastuploader.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.RemoteDesktop.plist"])
        return YES;
      else if([file isEqualToString: @"org.x.startx.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.AppleFileServer.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.configureLocalKDC.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.efax.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.FileSyncAgent.sshd.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.locate.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.NotificationServer.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-daily.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-monthly.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-weekly.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.smb.sharepoints.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.systemkeychain.plist"])
        return YES;
      else if([file isEqualToString: @"org.amavis.amavisd.plist"])
        return YES;
      else if([file isEqualToString: @"org.amavis.amavisd_cleanup.plist"])
        return YES;
      else if([file isEqualToString: @"org.cups.cupsd.plist"])
        return YES;
      else if([file isEqualToString: @"org.ntp.ntpd.plist"])
        return YES;
      else if([file isEqualToString: @"org.samba.winbindd.plist"])
        return YES;
      else if([file isEqualToString: @"ssh.plist"])
        return YES;
      break;
    case kLion:
      if([file isEqualToString: @"com.apple.AirPortBaseStationAgent.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.pcastuploader.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.screensharing.MessagesAgent.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.xgridd.keepalive.plist"])
        return YES;
      else if([file isEqualToString: @"org.x.startx.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.AppleFileServer.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.collabd.podcast-cache-updater.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.configureLocalKDC.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.efax.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.efilogin-helper.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.emlog.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.FileSyncAgent.sshd.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.locate.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.NotificationServer.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.pcastlibraryd.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-daily.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-monthly.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-weekly.plist"])
        return YES;
      else if([file isEqualToString: @"org.amavis.amavisd.plist"])
        return YES;
      else if([file isEqualToString: @"org.amavis.amavisd_cleanup.plist"])
        return YES;
      else if([file isEqualToString: @"org.cups.cupsd.plist"])
        return YES;
      else if([file isEqualToString: @"org.ntp.ntpd.plist"])
        return YES;
      else if([file isEqualToString: @"ssh.plist"])
        return YES;
      break;
    case kMountainLion:
      if([file isEqualToString: @"com.apple.AirPortBaseStationAgent.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.configureLocalKDC.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.efax.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.emlog.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.FileSyncAgent.sshd.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.gkreport.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.locate.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-daily.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-monthly.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.periodic-weekly.plist"])
        return YES;
      else if([file isEqualToString: @"org.cups.cupsd.plist"])
        return YES;
      else if([file isEqualToString: @"org.ntp.ntpd.plist"])
        return YES;
      else if([file isEqualToString: @"org.postgresql.postgres_alt.plist"])
        return YES;
      else if([file isEqualToString: @"ssh.plist"])
        return YES;
      break;
    case kMavericks:
      if([file isEqualToString: @"com.apple.configureLocalKDC.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.efax.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.emlog.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.FileSyncAgent.sshd.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.gkreport.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.locate.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.postgres.plist"])
        return YES;
      else if([file isEqualToString: @"org.apache.httpd.plist"])
        return YES;
      else if([file isEqualToString: @"org.cups.cupsd.plist"])
        return YES;
      else if([file isEqualToString: @"org.apache.httpd.plist"])
        return YES;
      else if([file isEqualToString: @"org.net-snmp.snmpd.plist"])
        return YES;
      else if([file isEqualToString: @"org.ntp.ntpd.plist"])
        return YES;
      else if([file isEqualToString: @"ssh.plist"])
        return YES;
      break;
    case kYosemite:
      if([file isEqualToString: @"com.apple.Dock.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.Spotlight.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.systemprofiler.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.configureLocalKDC.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.efax.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.emlog.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.FileSyncAgent.sshd.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.gkreport.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.locate.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.ManagedClient.enroll.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.ManagedClient.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.ManagedClient.startup.plist"])
        return YES;
      else if([file isEqualToString: @"com.apple.postgres.plist"])
        return YES;
      else if([file isEqualToString: @"org.cups.cupsd.plist"])
        return YES;
      else if([file isEqualToString: @"org.apache.httpd.plist"])
        return YES;
      else if([file isEqualToString: @"org.net-snmp.snmpd.plist"])
        return YES;
      else if([file isEqualToString: @"org.ntp.ntpd.plist"])
        return YES;
      else if([file isEqualToString: @"ssh.plist"])
        return YES;
        
      else if([file hasPrefix: @"com.apple.mail"])
        return YES;
      else if([file hasPrefix: @"com.apple.Safari"])
        return YES;

      break;
    case kElCapitan:
      break;
    }
    
  return NO;
  }

// Is this an Apple file that I expect to see?
- (bool) isAppleFile: (NSString *) file
  {
  if([file hasPrefix: @"com.apple."])
    return YES;
    
  if([self.appleLaunchd containsObject: file])
    return YES;
    
  if([[Model model] majorOSVersion] < kYosemite)
    {
    if([file hasPrefix: @"0x"])
      if([file rangeOfString: @".anonymous."].location != NSNotFound)
        return YES;
    if([file hasPrefix: @"[0x"])
      if([file rangeOfString: @".com.apple."].location != NSNotFound)
        return YES;
    }
    
  if([[Model model] majorOSVersion] < kLion)
    {
    if([file hasPrefix: @"0x1"])
      if([file rangeOfString: @".mach_init."].location != NSNotFound)
        return YES;
    }

  return NO;
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
      message =
        [NSString
          stringWithFormat:
            NSLocalizedString(@" - %@: Executable not found!", NULL), path];
    }
    
  return message;
  }

// Collect the executable of the launchd item.
- (NSArray *) collectLaunchdItemExecutable: (NSDictionary *) plist
  {
  NSMutableArray * executable = [NSMutableArray array];
  
  if(plist)
    {
    NSString * program = [plist objectForKey: @"Program"];
    
    if(program)
      [executable addObject: program];
      
    NSArray * arguments = [plist objectForKey: @"ProgramArguments"];
    
    if([arguments respondsToSelector: @selector(isEqualToArray:)])
      [executable addObjectsFromArray: arguments];
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
            formatExecutable: [status objectForKey: kExecutable]]]];
    
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
