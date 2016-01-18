/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "AdwareCollector.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"
#define kExtensionsKey @"extensions"
#define kGroup2Key @"group2"
#define kGroup3Key @"group3"
#define kGroup4Key @"group4"

// Collect information about adware.
@implementation AdwareCollector

@synthesize adwareSignatures = myAdwareSignatures;
@synthesize adwareFound = myAdwareFound;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"adware";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    
    myAdwareSignatures = [NSMutableDictionary new];
    myAdwareFound = [NSMutableDictionary new];
  
    [self loadSignatures];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.adwareFound = nil;
  self.adwareSignatures = nil;
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking for adware", NULL)];

  [self collectAdware];
  
  [self printAdware];
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect adware.
- (void) collectAdware
  {
  [self searchForAdware: kGroup2Key];
  [self searchForAdware: kGroup3Key];
  [self searchForAdware: kGroup4Key];
  }

// Load signatures from an obfuscated list of signatures.
- (void) loadSignatures
  {
  NSString * signaturePath =
    [[NSBundle mainBundle] pathForResource: @"adware" ofType: @"plist"];
    
  NSData * partialData = [NSData dataWithContentsOfFile: signaturePath];
  
  if(partialData)
    {
    NSMutableData * plistGzipData = [NSMutableData data];
    
    char buf[] = { 0x1F, 0x8B, 0x08 };
    
    [plistGzipData appendBytes: buf length: 3];
    [plistGzipData appendData: partialData];
    
    [plistGzipData writeToFile: @"/tmp/out.bin" atomically: YES];
    
    NSData * plistData = [Utilities ungzip: plistGzipData];
    
    [[NSFileManager defaultManager]
      removeItemAtPath: @"/tmp/out.bin" error: NULL];
    
    NSDictionary * plist = [Utilities readPropertyListData: plistData];
  
    if(plist)
      {
      [self
        addSignatures: [plist objectForKey: kWhitelistKey]
          forKey: kWhitelistKey];
      
      [self
        addSignatures: [plist objectForKey: kWhitelistPrefixKey]
          forKey: kWhitelistPrefixKey];

      [self
        addSignatures: [plist objectForKey: @"item1"]
          forKey: kExtensionsKey];
      
      [self
        addSignatures: [plist objectForKey: @"item2"] forKey: kGroup2Key];
      
      [self
        addSignatures: [plist objectForKey: @"item3"] forKey: kGroup3Key];
      
      [self
        addSignatures: [plist objectForKey: @"item4"] forKey: kGroup4Key];
      }
    }
  }

// Add signatures that match a given key.
- (void) addSignatures: (NSArray *) signatures forKey: (NSString *) key
  {
  if(signatures)
    {
    NSString * localizedKey = NSLocalizedString(key, NULL);
    
    if([key isEqualToString: kWhitelistKey])
      [[Model model] appendToWhitelist: signatures];

    else if([key isEqualToString: kWhitelistPrefixKey])
      [[Model model] appendToWhitelistPrefixes: signatures];

    if([key isEqualToString: @"extensions"])
      [[Model model] setAdwareExtensions: signatures];
      
    else
      [myAdwareSignatures
        setObject: [self expandSignatures: signatures]
        forKey: localizedKey];
    }
  }

// Expand adware signatures.
- (NSArray *) expandSignatures: (NSArray *) signatures
  {
  NSMutableArray * expandedSignatures = [NSMutableArray array];
  
  for(NSString * signature in signatures)
    [expandedSignatures
      addObject: [signature stringByExpandingTildeInPath]];
    
  return expandedSignatures;
  }

// Search for existing adware files.
- (void) searchForAdware: (NSString *) adware
  {
  NSArray * files = [self.adwareSignatures objectForKey: adware];
  
  NSMutableArray * foundFiles = [NSMutableArray array];
  
  [foundFiles addObjectsFromArray: [self identifyAdwareFiles: files]];
  
  if([foundFiles count])
    {
    [[Model model] setAdwareFound: YES];

    [self.adwareFound setObject: foundFiles forKey: adware];
    
    for(NSString * path in foundFiles)
      [[[Model model] adwareFiles]
        setObject: [adware lowercaseString] forKey: path];
    }
  }

// Identify adware files.
- (NSArray *) identifyAdwareFiles: (NSArray *) files
  {
  NSMutableArray * adwareFiles = [NSMutableArray array];
  
  for(NSString * file in files)
    {
    NSString * fullPath = [file stringByExpandingTildeInPath];
    
    bool exists =
      [[NSFileManager defaultManager] fileExistsAtPath: fullPath];
      
    if(exists)
      [adwareFiles addObject: fullPath];
    }
    
  return adwareFiles;
  }

// Print any adware found.
- (void) printAdware
  {
  if([self.adwareFound count])
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    __block int adwareCount = 0;
    
    [[[Model model] adwareFiles]
      enumerateKeysAndObjectsUsingBlock:
        ^(id key, id obj, BOOL * stop)
          {
          ++adwareCount;
          [self.result appendString: @"    "];
          [self.result
            appendString: [Utilities sanitizeFilename: key]
            attributes:
              @{
                NSFontAttributeName : [[Utilities shared] boldFont],
                NSForegroundColorAttributeName : [[Utilities shared] red],
              }];
          [self.result appendString: @"\n"];
          }];
      
    NSString * message =
      TTTLocalizedPluralString(adwareCount, @"adware file", NULL);

    [self.result appendString: @"    "];
    [self.result
      appendString: message
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
    
    NSAttributedString * removeLink = [self generateRemoveAdwareLink];

    if(removeLink)
      {
      [self.result appendAttributedString: removeLink];
      [self.result appendString: @"\n"];
      }
    
    [self.result appendCR];
    }
  }
  
@end
