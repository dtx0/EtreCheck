/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UnknownFilesCollector.h"
#import "Model.h"
#import "DiagnosticEvent.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "UnknownFilesManager.h"
#import "TTTLocalizedPluralString.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"

// Collect information about unknown files.
@implementation UnknownFilesCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"unknownfiles";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking for unknown files", NULL)];

  [self printUnknownFiles];
  
  dispatch_semaphore_signal(self.complete);
  }

// Print any unknown files.
- (void) printUnknownFiles
  {
  NSUInteger unknownFileCount = [[[Model model] unknownFiles] count];
  
  if(unknownFileCount > 0)
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    NSArray * sortedUnknownFiles =
      [[[[Model model] unknownFiles] allObjects]
        sortedArrayUsingSelector: @selector(compare:)];
      
    [sortedUnknownFiles
      enumerateObjectsUsingBlock:
        ^(id obj, NSUInteger idx, BOOL * stop)
          {
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  @"    %@", [Utilities sanitizeFilename: obj]]];

          NSString * cmd =
            [obj length] > 0
              ? [[[Model model] launchdCommands] objectForKey: obj]
              : nil;
          
          if([cmd length] > 0)
            {
            [self.result appendString: @"\n        "];
            [self.result appendString: [Utilities sanitizeFilename: cmd]];
            }

          [self.result appendString: @"\n"];
          }];
      
    NSString * message =
      TTTLocalizedPluralString(unknownFileCount, @"unknown file", NULL);

    [self.result appendString: @"    "];
    
    [self.result
      appendString: message
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    NSAttributedString * checkLink = [self generateCheckFilesLink: @"files"];

    if(checkLink)
      {
      [self.result appendAttributedString: checkLink];
      [self.result appendString: @"\n"];
      }
    
    [self.result appendCR];
    }
  }

@end
