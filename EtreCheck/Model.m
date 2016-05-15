/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Model.h"
#import "DiagnosticEvent.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

@implementation Model

@synthesize majorOSVersion = myMajorOSVersion;
@synthesize minorOSVersion = myMinorOSVersion;
@synthesize volumes = myVolumes;
@synthesize coreStorageVolumes = myCoreStorageVolumes;
@synthesize diskErrors = myDiskErrors;
@synthesize gpuErrors = myGPUErrors;
@synthesize logEntries = myLogEntries;
@synthesize applications = myApplications;
@synthesize physicalRAM = myPhysicalRAM;
@synthesize machineIcon = myMachineIcon;
@synthesize processes = myProcesses;
@synthesize model = myModel;
@synthesize serialCode = mySerialCode;
@synthesize diagnosticEvents = myDiagnosticEvents;
@synthesize adwareFiles = myAdwareFiles;
@synthesize potentialAdwareTrioFiles = myPotentialAdwareTrioFiles;
@synthesize adwareExtensions = myAdwareExtensions;
@synthesize whitelistFiles = myWhitelistFiles;
@synthesize whitelistPrefixes = myWhitelistPrefixes;
@synthesize blacklistFiles = myBlacklistFiles;
@synthesize blacklistMatches = myBlacklistMatches;
@synthesize blacklistSuffixes = myBlacklistSuffixes;
@synthesize computerName = myComputerName;
@synthesize hostName = myHostName;
@synthesize adwareFound = myAdwareFound;
@synthesize terminatedTasks = myTerminatedTasks;
@synthesize unknownFiles = myUnknownFiles;
@synthesize seriousProblems = mySeriousProblems;
@synthesize backupExists = myBackupExists;
@synthesize launchdCommands = myLaunchdCommands;
@synthesize launchdContents = myLaunchdContents;
@synthesize ignoreKnownAppleFailures = myIgnoreKnownAppleFailures;
@synthesize checkAppleSignatures = myCheckAppleSignatures;
@synthesize hideAppleTasks = myHideAppleTasks;
@synthesize oldEtreCheckVersion = myOldEtreCheckVersion;
@synthesize verifiedEtreCheckVersion = myVerifiedEtreCheckVersion;
@dynamic haveUnknownFiles;

- (bool) haveUnknownFiles
  {
  return self.unknownFiles.count > 0;
  }

// Return the singeton of shared values.
+ (Model *) model
  {
  static Model * model = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      model = [[Model alloc] init];
    });
    
  return model;
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myUnknownFiles = [NSMutableSet new];
    myVolumes = [NSMutableDictionary new];
    myCoreStorageVolumes = [NSMutableDictionary new];
    myDiskErrors = [NSMutableDictionary new];
    myDiagnosticEvents = [NSMutableDictionary new];
    myAdwareFiles = [NSMutableDictionary new];
    myPotentialAdwareTrioFiles = [NSMutableDictionary new];
    myTerminatedTasks = [NSMutableArray new];
    mySeriousProblems = [NSMutableSet new];
    myIgnoreKnownAppleFailures = YES;
    myCheckAppleSignatures = YES;
    myHideAppleTasks = YES;
    myWhitelistFiles = [NSMutableSet new];
    myWhitelistPrefixes = [NSMutableSet new];
    myBlacklistFiles = [NSMutableSet new];
    myBlacklistSuffixes = [NSMutableSet new];
    myBlacklistMatches = [NSMutableSet new];
    myLaunchdCommands = [NSMutableDictionary new];
    myLaunchdContents = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myLaunchdCommands release];
  [myLaunchdContents release];
  [myBlacklistSuffixes release];
  [myBlacklistMatches release];
  [myBlacklistFiles release];
  [myWhitelistFiles release];
  [myWhitelistPrefixes release];
  
  self.unknownFiles = nil;
  self.seriousProblems = nil;
  self.terminatedTasks = nil;
  self.potentialAdwareTrioFiles = nil;
  self.adwareFiles = nil;
  self.diagnosticEvents = nil;
  self.diskErrors = nil;
  self.volumes = nil;
  self.applications = nil;
  self.machineIcon = nil;
  self.processes = nil;
  
  [super dealloc];
  }

// Return true if there are log entries for a process.
- (bool) hasLogEntries: (NSString *) name
  {
  if(!name)
    return NO;
  
  __block bool matching = NO;
  __block NSMutableString * result = [NSMutableString string];
  
  [[self logEntries]
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        DiagnosticEvent * event = (DiagnosticEvent *)obj;
        
        if([event.details rangeOfString: name].location != NSNotFound)
          matching = YES;

        else
          {
          NSRange found =
            [event.details
              rangeOfCharacterFromSet:
                [NSCharacterSet whitespaceCharacterSet]];
            
          if(matching && (found.location == 0))
            matching = YES;
          else
            matching = NO;
          }
        
        if(matching)
          {
          [result appendString: event.details];
          [result appendString: @"\n"];
          }
        }];
    
  if([result length])
    {
    DiagnosticEvent * event = [DiagnosticEvent new];

    event.type = kLog;
    event.name = name;
    event.details = result;
      
    [[[Model model] diagnosticEvents] setObject: event forKey: name];
    
    [event release];

    return YES;
    }

  return NO;
  }

// Collect log entires matching a date.
- (NSString *) logEntriesAround: (NSDate *) date
  {
  NSDate * startDate = [date dateByAddingTimeInterval: -60*5];
  NSDate * endDate = [date dateByAddingTimeInterval: 60*5];
  
  NSArray * lines = [[Model model] logEntries];
  
  __block NSMutableString * result = [NSMutableString string];
  
  [lines
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        DiagnosticEvent * event = (DiagnosticEvent *)obj;
        
        if([endDate compare: event.date] == NSOrderedAscending)
          *stop = YES;
        
        else if([startDate compare: event.date] == NSOrderedAscending)
          if([event.details length])
            {
            [result appendString: event.details];
            [result appendString: @"\n"];
            }
        }];
    
  return result;
  }

// Create a details URL for a query string.
- (NSAttributedString *) getDetailsURLFor: (NSString *) query
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * url =
    [NSString stringWithFormat: @"etrecheck://detail/%@", query];
  
  [urlString
    appendString: NSLocalizedString(@"[Details]", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Is this file an adware file?
- (bool) isAdware: (NSString *) path
  {
  if([path length] == 0)
    return NO;
    
  bool adware = NO;
  
  if([self.adwareFiles objectForKey: path])
    adware = YES;
  else if([self isAdwareSuffix: path])
    adware = YES;
  else if([self isAdwareMatch: path])
    adware = YES;
  else if([self isAdwareTrio: path])
    adware = YES;
    
  if(adware)
    self.adwareFound = YES;
  
  return adware;
  }

// Is this an adware suffix file?
- (bool) isAdwareSuffix: (NSString *) path
  {
  for(NSString * suffix in self.blacklistSuffixes)
    if([path hasSuffix: suffix])
      {
      NSString * name = [path lastPathComponent];
      
      NSString * tag =
        [name substringToIndex: [name length] - [suffix length]];
      
      [self.adwareFiles setObject: [tag lowercaseString] forKey: path];
      
      return YES;
      }
    
  return NO;
  }

// Is this an adware match file?
- (bool) isAdwareMatch: (NSString *) path
  {
  NSString * name = [path lastPathComponent];
  
  for(NSString * match in self.blacklistFiles)
    {
    if([name isEqualToString: match])
      {
      [self.adwareFiles setObject: name forKey: path];
      
      return YES;
      }
    }
    
  for(NSString * match in self.blacklistMatches)
    {
    NSRange range = [name rangeOfString: match];
    
    if(range.location != NSNotFound)
      {
      NSString * tag = [name substringWithRange: range];
      
      [self.adwareFiles setObject: [tag lowercaseString] forKey: path];
      
      return YES;
      }
    }
    
  return NO;
  }

// Is this an adware trio of daemon/agent/helper?
- (bool) isAdwareTrio: (NSString *) path
  {
  NSString * name = [path lastPathComponent];
  
  NSString * prefix = name;
  
  if([name hasSuffix: @".daemon.plist"])
    {
    prefix = [name substringToIndex: [name length] - 13];
    
    [self addPotentialAdwareTrioFile: path prefix: prefix type: @"daemon"];
    }
    
  if([name hasSuffix: @".agent.plist"])
    {
    prefix = [name substringToIndex: [name length] - 12];
    
    [self addPotentialAdwareTrioFile: path prefix: prefix type: @"agent"];
    }
    
  if([name hasSuffix: @".helper.plist"])
    {
    prefix = [name substringToIndex: [name length] - 13];
    
    [self addPotentialAdwareTrioFile: path prefix: prefix type: @"helper"];
    }
    
  NSDictionary * trioFiles =
    [self.potentialAdwareTrioFiles objectForKey: prefix];

  BOOL hasDaemon = [trioFiles objectForKey: @"daemon"] != nil;
  BOOL hasAgent = [trioFiles objectForKey: @"agent"] != nil;
  BOOL hasHelper = [trioFiles objectForKey: @"helper"] != nil;
  
  if(hasDaemon && hasAgent && hasHelper)
    {
    NSArray * parts = [prefix componentsSeparatedByString: @"."];
    
    if([parts count] > 1)
      prefix = [parts objectAtIndex: 1];
      
    for(NSString * type in trioFiles)
      {
      NSString * trioPath = [trioFiles objectForKey: type];
      
      [self.adwareFiles
        setObject: [prefix lowercaseString] forKey: trioPath];
        
      [self.unknownFiles removeObject: trioPath];
      }

    return YES;
    }
    
  return NO;
  }

// Add a potential adware trio file.
- (void) addPotentialAdwareTrioFile: (NSString *) path
  prefix: (NSString *) prefix type: (NSString *) type
  {
  NSMutableDictionary * trioFiles =
    [self.potentialAdwareTrioFiles objectForKey: prefix];
    
  if(!trioFiles)
    {
    trioFiles = [NSMutableDictionary dictionary];
    
    [self.potentialAdwareTrioFiles setObject: trioFiles forKey: prefix];
    }
  
  [trioFiles setObject: path forKey: type];
  }

// Is this file an adware extension?
- (bool) isAdwareExtension: (NSString *) name path: (NSString *) path
  {
  if(([name length] > 0) && ([path length] > 0))
    {
    NSString * search = [path lowercaseString];
    
    for(NSString * extension in self.adwareExtensions)
      if([search rangeOfString: extension].location != NSNotFound)
        return YES;

    for(NSString * match in self.blacklistMatches)
      {
      NSRange range = [path rangeOfString: match];
      
      if(range.location != NSNotFound)
        return YES;

      range = [name rangeOfString: match];
      
      if(range.location != NSNotFound)
        return YES;
      }
    }
    
  return NO;
  }

// Add files to the whitelist.
- (void) appendToWhitelist: (NSArray *) names;
  {
  [self.whitelistFiles addObjectsFromArray: names];
  }
  
// Add files to the whitelist prefixes.
- (void) appendToWhitelistPrefixes: (NSArray *) names;
  {
  [self.whitelistPrefixes addObjectsFromArray: names];
  }
  
// Add files to the blacklist.
- (void) appendToBlacklist: (NSArray *) names
  {
  [self.blacklistFiles addObjectsFromArray: names];
  }

// Set the blacklist suffixes.
- (void) appendToBlacklistSuffixes: (NSArray *) names
  {
  [self.blacklistSuffixes addObjectsFromArray: names];
  }

// Set the blacklist matches.
- (void) appendToBlacklistMatches: (NSArray *) names
  {
  [self.blacklistMatches addObjectsFromArray: names];
  }

// Is this file known?
- (bool) isKnownFile: (NSString *) name path: (NSString *) path
  {
  if([self isWhitelistFile: name])
    return YES;
    
  if([self isAdware: path])
    return YES;
    
  [self.unknownFiles addObject: path];

  return NO;
  }

// Is this file in the whitelist?
- (bool) isWhitelistFile: (NSString *) name
  {
  if([self.whitelistFiles count] < kMinimumWhitelistSize)
    return YES;
    
  if([self.whitelistFiles containsObject: name])
    return YES;
    
  for(NSString * whitelistPrefix in self.whitelistPrefixes)
    if([name hasPrefix: whitelistPrefix])
      return YES;
      
  return NO;
  }

// What kind of adware is this?
- (NSString *) adwareType: (NSString *) path
  {
  return [self.adwareFiles objectForKey: path];
  }

// Handle a task that takes too long to complete.
- (void) taskTerminated: (NSString *) program arguments: (NSArray *) args
  {
  NSMutableString * command = [NSMutableString string];
  
  [command appendString: program];
  
  for(NSString * argument in args)
    {
    [command appendString: @" "];
    [command appendString: [Utilities cleanPath: argument]];
    }
    
  [self.terminatedTasks addObject: command];
  }

@end
