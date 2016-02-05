/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface AdminManager : NSObject
  {
  NSWindow * myWindow;
  NSTextView * myTextView;
  NSTableView * myTableView;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The text view.
@property (retain) IBOutlet NSTextView * textView;

// The table view.
@property (retain) IBOutlet NSTableView * tableView;

// Show the window.
- (void) show;

// Close the window.
- (IBAction) close: (id) sender;

@end
