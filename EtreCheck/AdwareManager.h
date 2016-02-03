/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface AdwareManager : NSObject
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSWindow * myWindow;
  NSTextView * myTextView;
  NSTableView * myTableView;
  NSMutableArray * myAdwareFiles;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The text view.
@property (retain) IBOutlet NSTextView * textView;

// The table view.
@property (retain) IBOutlet NSTableView * tableView;

// Array of adware files.
@property (retain) NSMutableArray * adwareFiles;

// Show the window.
- (void) show;

// Close the window.
- (IBAction) close: (id) sender;

// Remove the adware.
- (IBAction) removeAdware: (id) sender;

@end
