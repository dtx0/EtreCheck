/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

@class AppDelegate;

// A toolbar item that uses a view and behaves properly.
@interface EtreCheckToolbarItem : NSToolbarItem
  {
  NSControl * myControl;
  AppDelegate * myAppDelegate;
  }

@property (assign) IBOutlet NSControl * control;
@property (assign) IBOutlet AppDelegate * appDelegate;

@end
