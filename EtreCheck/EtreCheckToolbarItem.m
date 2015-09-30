/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012. All rights reserved.
 **********************************************************************/

#import "EtreCheckToolbarItem.h"
#import "AppDelegate.h"

@implementation EtreCheckToolbarItem

@synthesize control = myControl;

- (void) validate
  {
  AppDelegate * appDelegate = (AppDelegate *)self.target;
  
  self.enabled = appDelegate.reportAvailable;
  [self.control setEnabled: appDelegate.reportAvailable];
  }

@end
