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
  
  for(NSString * bundleID in self.launchdStatus)
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
  bool isApple = [self isAppleFile: bundleID];
  
  status[kApple] = [NSNumber numberWithBool: isApple];

  if(isApple && ([[Model model] majorOSVersion] < kYosemite))
    {
    status[kIgnored] = @YES;
    return;
    }
    
  NSString * executable =
    [self getExecutableForBundle: bundleID status: status];
    
  if(isApple && executable)
    {
    status[kSignature] = [Utilities checkAppleExecutable: executable];
    
    if([status[kSignature] isEqualToString: kSignatureValid])
      status[kIgnored] = @YES;
      
    // Should I ignore this failure?
    if([self ignoreInvalidSignatures: bundleID])
      status[kIgnored] = @YES;
    }
  else if([self isSandboxApp: bundleID])
    status[kIgnored] = @YES;
  }

// Get the executable for the app.
- (NSString *) getExecutableForBundle: (NSString *) bundleID
  status: (NSMutableDictionary *) status
  {
  NSArray * command = status[kExecutable];
  
  if(!command)
    {
    command = [self collectLaunchdItemExecutable: status];
    
    if(command)
      {
      status[kCommand] = command;
      status[kExecutable] = command[0];
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
- (bool) isSandboxApp: (NSString *) bundleID
  {
  if([[Model model] majorOSVersion] < kYosemite)
    return NO;
    
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
