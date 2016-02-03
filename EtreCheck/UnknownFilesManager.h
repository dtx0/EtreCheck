/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface UnknownFilesManager : NSObject
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSWindow * myWindow;
  NSTextView * myTextView;
  NSTableView * myTableView;
  NSMutableArray * myDeleteIndicators;
  NSMutableArray * myWhitelistIndicators;
  NSMutableArray * myUnknownFiles;
  NSAttributedString * myWhitelistDescription;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The text view.
@property (retain) IBOutlet NSTextView * textView;

// The table view.
@property (retain) IBOutlet NSTableView * tableView;

// Array of NSNumber booleans to indicate adware files.
@property (retain) NSMutableArray * deleteIndicators;

// Array of NSNumber booleans to indicate known files.
@property (retain) NSMutableArray * whitelistIndicators;

// Array of unknown files.
@property (retain) NSMutableArray * unknownFiles;

// User's whitelist description.
@property (retain) NSAttributedString * whitelistDescription;

// Can I delete something?
@property (readonly) BOOL canDelete;

// Can I add something to the whitelist?
@property (readonly) BOOL canAddToWhitelist;

// Show the window.
- (void) show;

// Close the window.
- (IBAction) close: (id) sender;

// Remove the adware.
- (IBAction) removeAdware: (id) sender;

// Contact Etresoft to add to whitelist.
- (IBAction) addToWhitelist: (id) sender;

@end
