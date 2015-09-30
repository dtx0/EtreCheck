/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

@interface EtreCheckToolbarItem : NSToolbarItem
  {
  NSControl * myControl;
  }

@property (assign) IBOutlet NSControl * control;

@end
