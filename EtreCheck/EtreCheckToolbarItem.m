/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import "EtreCheckToolbarItem.h"
#import "AppDelegate.h"

@implementation EtreCheckToolbarItem

@synthesize control = myControl;
@synthesize appDelegate = myAppDelegate;

- (void) validate
  {
  self.enabled = self.appDelegate.reportAvailable;
  [self.control setEnabled: self.appDelegate.reportAvailable];
  }

@end
