/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "HiddenAppsCollector.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"

// Collect "other" files like modern login items.
@implementation HiddenAppsCollector

@synthesize processes = myProcesses;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"hiddenapps";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.processes = nil;
  
  [super dealloc];
  }

// Collect user launch agents.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking for hidden apps", NULL)];

  // Make sure the base class is setup.
  [super collect];

  [self collectProcesses];
  
  [self printHiddenApps];
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect all running processes.
- (void) collectProcesses
  {
  NSArray * args = @[ @"-raxww", @"-o", @"pid, comm" ];
  
  NSData * result = [Utilities execute: @"/bin/ps" arguments: args];
  
  NSArray * lines = [Utilities formatLines: result];
  
  NSMutableDictionary * currentProcesses = [NSMutableDictionary dictionary];
  
  for(NSString * line in lines)
    {
    if([line hasPrefix: @"STAT"])
      continue;

    NSNumber * pid = nil;
    NSString * command = nil;

    [self parsePs: line pid: & pid command: & command];
    
    if(pid && command)
      currentProcesses[pid] = command;
    }
    
  myProcesses = [currentProcesses copy];
  }

// Parse a line from the ps command.
- (void) parsePs: (NSString *) line
  pid: (NSNumber **) pid
  command: (NSString **) command
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];

  NSInteger pidValue;
  
  bool found = [scanner scanInteger: & pidValue];

  if(!found)
    return;

  *pid = [NSNumber numberWithInteger: pidValue];
  
  [scanner scanUpToString: @"\n" intoString: command];
  }

// Print apps that weren't printed elsewhere.
- (void) printHiddenApps
  {
  bool titlePrinted = NO;
  bool unprintedItems = NO;
  
  NSArray * sortedBundleIDs =
    [[self.launchdStatus allKeys]
      sortedArrayUsingSelector: @selector(compare:)];

  for(NSString * bundleID in sortedBundleIDs)
    {
    NSMutableDictionary * status =
      [self collectJobStatus: self.launchdStatus[bundleID]];
    
    if([status[kPrinted] boolValue])
      continue;
      
    if([status[kIgnored] boolValue])
      continue;
      
    [self updateStatus: status forBundle: bundleID];
    
    if([status[kIgnored] boolValue])
      continue;
      
    if(!titlePrinted)
      {
      [self.result appendAttributedString: [self buildTitle]];
      titlePrinted = YES;
      }
      
    [self.result
      appendAttributedString: [self formatPropertyListStatus: status]];
    
    [self.result appendString: bundleID];
    
    [self.result
      appendAttributedString: [self formatExtraContent: status]];
    
    [self.result appendString: @"\n"];
  
    unprintedItems = YES;
    }
    
  if(unprintedItems)
    [self.result appendCR];
  }

// Get a status and expand with all the information I can find.
- (void) updateStatus: (NSMutableDictionary *) status
  forBundle: (NSString *) bundleID
  {
  NSNumber * ignore =
    [NSNumber numberWithBool: [[Model model] hideAppleTasks]];
  
  bool isApple = [self isAppleFile: bundleID];
  
  status[kApple] = [NSNumber numberWithBool: isApple];

  if(isApple && ([[Model model] majorOSVersion] < kYosemite))
    {
    status[kIgnored] = ignore;
    return;
    }
    
  NSString * executable =
    [self getExecutableForBundle: bundleID status: status];
    
  if(isApple && executable)
    {
    status[kSignature] = [Utilities checkAppleExecutable: executable];
    
    if([status[kSignature] isEqualToString: kSignatureValid])
      status[kIgnored] = ignore;
      
    // Should I ignore this failure?
    if([self ignoreInvalidSignatures: bundleID])
      status[kIgnored] = ignore;
    }
  else if([self isApp: bundleID])
    status[kIgnored] = ignore;
  }

// Get the executable for the app.
- (NSString *) getExecutableForBundle: (NSString *) bundleID
  status: (NSMutableDictionary *) status
  {
  NSArray * command = status[kCommand];
  
  if(!command)
    {
    command = [self collectLaunchdItemCommand: status];
    
    if(command)
      {
      status[kCommand] = command;
      status[kExecutable] = [self collectLaunchdItemExecutable: command];
      }
    }
    
  NSString * executable = status[kExecutable];
  
  // Next try NSWorkspace.
  if(!executable)
    executable =
      [[NSWorkspace sharedWorkspace]
        absolutePathForAppBundleWithIdentifier: bundleID];
    
  // Now try ps.
  if(!executable)
    executable = self.processes[status[kPID]];
    
  if(executable && !command)
    {
    status[kExecutable] = executable;
    status[kCommand] = @[ executable ];
    }
    
  return executable;
  }

// Is the bundle an App Store item?
- (bool) isApp: (NSString *) bundleID
  {
  if([[Model model] majorOSVersion] < kYosemite)
    return [self isEtreCheck: bundleID];
    
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
      return YES;
    }
    
  return NO;
  }

// Is the bundle EtreCheck itself?
- (bool) isEtreCheck: (NSString *) bundleID
  {
  if([[Model model] majorOSVersion] >= kYosemite)
    return NO;
    
  NSArray * args =
    @[
      @"list",
      bundleID
    ];
  
  NSData * data =
    [Utilities execute: @"/bin/launchctl" arguments: args];
  
  NSArray * lines = [Utilities formatLines: data];

  NSProcessInfo *processInfo = [NSProcessInfo processInfo];

  int processID = [processInfo processIdentifier];

  NSString * PIDLine =
    [NSString stringWithFormat: @"\"PID\" = %d;", processID];
    
  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      
    if([trimmedLine isEqualToString: PIDLine])
      return YES;
    }
    
  return NO;
  }

// Include any extra content that may be useful.
- (NSAttributedString *) formatExtraContent: (NSDictionary *) status
  {
  if([status[kApple] boolValue])
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

@end
