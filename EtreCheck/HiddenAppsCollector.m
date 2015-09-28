/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "HiddenAppsCollector.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "NSMutableAttributedString+Etresoft.h"

@implementation HiddenAppsCollector

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

// Collect user launch agents.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking for hidden apps", NULL)];

  // Make sure the base class is setup.
  [super collect];

  [self printHiddenApps];
  
  dispatch_semaphore_signal(self.complete);
  }

// Print apps that weren't printed elsewhere.
- (void) printHiddenApps
  {
  bool titlePrinted = NO;
  bool unprintedItems = NO;
  
  for(NSString * bundleID in self.launchdStatus)
    {
    NSMutableDictionary * status = self.launchdStatus[bundleID];
    
    if(![status[kPrinted] boolValue])
      {
      if(!titlePrinted)
        {
        [self.result appendAttributedString: [self buildTitle]];
        titlePrinted = YES;
        }
        
      [self.result
        appendAttributedString: [self formatPropertyListStatus: status]];
      
      [self.result appendString: bundleID];
      
      [self.result appendString: @"\n"];
    
      unprintedItems = YES;
      }
    }
    
  if(unprintedItems)
    [self.result appendCR];
  }

@end
