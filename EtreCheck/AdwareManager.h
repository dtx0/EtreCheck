/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

#define kAdwareFound @"adwarefound"
#define kAdwarePossible @"adwarepossible"

@interface AdwareManager : PopoverManager
  {
  NSButton * myDownloadButton;
  }

// The Adware Medic download button.
@property (retain) IBOutlet NSButton * downloadButton;

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender;

@end
