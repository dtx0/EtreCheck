/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchDaemonsCollector.h"
#import "Utilities.h"

@implementation LaunchDaemonsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"launchdaemons";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Collect 3rd party launch daemons.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking launch daemons", NULL)];

  // Make sure the base class is setup.
  [super collect];
  
  NSArray * args =
    @[
      @"/Library/LaunchDaemons",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  NSData * result = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: result];
  
  NSArray * plists = [self collectPropertyListFiles: files];
  
  [self printPropertyLists: plists];
    
  dispatch_semaphore_signal(self.complete);
  }
  
// There shouldn't be any Apple files here. So, if there are, print them.
- (bool) isAppleFile: (NSString *) bundleID
  {
  return NO;
  }

// Since I am printing all Apple items, no need for counts.
- (bool) formatAppleCounts: (NSMutableAttributedString *) output
  {
  return NO;
  }

@end
