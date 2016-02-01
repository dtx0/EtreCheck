/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface UnknownFilesManager : NSObject
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSWindow * myWindow;
  NSTextView * myTextView;
  NSTableView * myTableView;
  NSButton * myDownloadButton;
  NSMutableArray * myWhitelistIndicators;
  NSArray * myUnknownFiles;
  NSAttributedString * myWhitelistDescription;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The text view.
@property (retain) IBOutlet NSTextView * textView;

// The table view.
@property (retain) IBOutlet NSTableView * tableView;

// The Adware Medic download button.
@property (retain) IBOutlet NSButton * downloadButton;

// Array of NSNumber booleans to indicate known files.
@property (retain) NSMutableArray * whitelistIndicators;

// Array of unknown files.
@property (retain) NSArray * unknownFiles;

// User's whitelist description.
@property (retain) NSAttributedString * whitelistDescription;

// Show the window.
- (void) show;

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender;

// Contact Etresoft to add to whitelist.
- (IBAction) addToWhitelist: (id) sender;

@end
