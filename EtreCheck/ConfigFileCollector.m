/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ConfigFileCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"

// Collect changes to config files like /etc/sysctl.conf and /etc/hosts.
@implementation ConfigFileCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"configurationfiles";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking configuration files", NULL)];

  NSArray * configFiles = [self existingConfigFiles];
  
  bool haveChanges = [configFiles count] > 0;

  NSArray * modifiedFiles = [self modifiedConfigFiles];

  if([modifiedFiles count] > 0)
    haveChanges = YES;
    
  // See if /etc/hosts has any changes or is corrupt.
  bool corrupt = NO;
  
  NSUInteger hostsCount = [self hostsStatus: & corrupt];
  
  if(hostsCount || corrupt)
    haveChanges = YES;
    
  // Only print this section if I have changes.
  if(haveChanges)
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    // Print modified configFiles.
    for(NSString * modifiedFile in modifiedFiles)
      [self.result
        appendString: modifiedFile
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];

    // Print existing configFiles.
    for(NSString * configFile in configFiles)
      [self.result
        appendString:
          [NSString stringWithFormat:
            NSLocalizedString(
              @"    %@ - File exists but not expected\n", NULL),
            configFile]];
      
    // Print changes to /etc/hosts.
    [self printHostsStatus: corrupt count: hostsCount];
      
    [self.result appendCR];
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Find modified configuration files.
- (NSArray *) modifiedConfigFiles
  {
  NSMutableArray * files = [NSMutableArray array];
  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  
  NSDictionary * attributes =
    [fileManager attributesOfItemAtPath: @"/etc/sudoers" error: NULL];
  
  // See if /etc/sudoers has been modified.
  if(attributes)
    {
    int version = [[Model model] majorOSVersion];
    unsigned long long expectedSize = attributes.fileSize;
    
    switch(version)
      {
      case kSnowLeopard:
        expectedSize = 1242;
        break;
      case kLion:
        expectedSize = 1275;
        break;
      case kMountainLion:
        expectedSize = 1275;
        break;
      case kMavericks:
        expectedSize = 1275;
        break;
      case kYosemite:
        expectedSize = 1275;
        break;
      }
    
    if(attributes.fileSize != expectedSize)
      [files
        addObject:
          [NSString
            stringWithFormat:
              NSLocalizedString(
                @"    %@, File size %llu but expected %llu\n",
                NULL),
              @"/etc/sudoers",
              attributes.fileSize,
              expectedSize]];
    }
  
  return files;
  }

// Find existing configuration files.
- (NSArray *) existingConfigFiles
  {
  NSMutableArray * files = [NSMutableArray array];
  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  
  // See if /etc/sysctl.conf exists.
  if([fileManager fileExistsAtPath: @"/etc/sysctl.conf"])
    [files addObject: @"/etc/sysctl.conf"];
  
  // See if /etc/launchd.conf exists.
  if([fileManager fileExistsAtPath: @"/etc/launchd.conf"])
    [files addObject: @"/etc/launchd.conf"];
    
  return files;
  }

// Collect the number of changes to /etc/hosts and its status.
- (NSUInteger) hostsStatus: (bool *) corrupt
  {
  NSUInteger count = 0;
  
  NSString * hosts =
    [NSString
      stringWithContentsOfFile:
        @"/etc/hosts" encoding: NSUTF8StringEncoding error: nil];
  
  NSArray * lines = [hosts componentsSeparatedByString: @"\n"];
  
  for(NSString * line in lines)
    {
    if(![line length])
      continue;
      
    if([line hasPrefix: @"#"])
      continue;
      
    NSString * hostname = [self readHostname: line];
      
    if(corrupt && !hostname)
      *corrupt = YES;
      
    if([hostname length] < 1)
      continue;
      
    if([hostname isEqualToString: @"localhost"])
      continue;

    if([hostname isEqualToString: @"broadcasthost"])
      continue;
            
    ++count;
    }
    
  return count;
  }

// Read a name from /etc/hosts.
// Return nil if the name is invalid or the file is corrupt.
- (NSString *) readHostname: (NSString *) line
  {
  NSString * trimmedLine =
    [line
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if([trimmedLine hasPrefix: @"#"])
    return @"";
    
  if([trimmedLine length] < 1)
    return @"";
    
  NSScanner * scanner = [NSScanner scannerWithString: trimmedLine];
  
  NSString * address = nil;
  
  bool scanned =
    [scanner
      scanUpToCharactersFromSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]
      intoString: & address];
  
  if(!scanned)
    return nil;
    
  NSString * name = nil;

  scanned =
    [scanner
      scanUpToCharactersFromSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]
      intoString: & name];

  if(!scanned)
    return nil;
    
  return name;
  }

// Print the status of the hosts file.
- (void) printHostsStatus: (bool) corrupt count: (NSUInteger) count
  {
  NSString * corruptString = @"";
  
  if(corrupt)
    corruptString = NSLocalizedString(@" - Corrupt!", NULL);
    
  NSString * countString = @"";
  
  if(count > 0)
    countString =
      [NSString
        stringWithFormat:
          NSLocalizedString(@" - Count: %d", NULL), count];
    
  if((count > 10) || corrupt)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"    /etc/hosts%@%@\n", NULL),
            countString, corruptString]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  else if(count > 0)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"    /etc/hosts%@%@\n", NULL),
            countString, corruptString]];
  }

@end
