/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "AdwareManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

@interface PopoverManager ()

// Show detail.
- (void) showDetail: (NSString *) title
  content: (NSAttributedString *) content;

@end

@implementation AdwareManager

// Show detail.
- (void) showDetail: (NSString *) name
  {
  NSMutableAttributedString * details = [NSMutableAttributedString new];
  
  if([name isEqualToString: kAdwareFound])
    [details appendString: NSLocalizedString(@"definiteadware", NULL)];
  
  else
    [details appendString: NSLocalizedString(@"probableadware", NULL)];
    
  [super
    showDetail: NSLocalizedString(@"About adware", NULL) content: details];
    
  [details release];
  }

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL
        URLWithString: @"https://www.malwarebytes.org/antimalware/mac/"]];
  }

@end
