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
  
  NSMutableArray * myLaunchdTasksToUnload;
  NSMutableArray * myFilesToRemove;
  
  BOOL myFilesDeleted;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The text view.
@property (retain) IBOutlet NSTextView * textView;

// The table view.
@property (retain) IBOutlet NSTableView * tableView;

// Can the manager remove any files?
@property (readonly) BOOL canRemoveFiles;

// Launchd tasks to unload.
@property (retain) NSMutableArray * launchdTasksToUnload;

// Files to remove.
@property (retain) NSMutableArray * filesToRemove;

// Were any files deleted?
@property (assign) BOOL filesDeleted;

// Show the window.
- (void) show;

// Close the window.
- (IBAction) close: (id) sender;

// Tell the user that EtreCheck is too old.
- (BOOL) reportOldEtreCheckVersion;

// Tell the user that the EtreCheck version is unverified.
- (BOOL) reportUnverifiedEtreCheckVersion;

// Remove files.
- (IBAction) removeFiles: (id) sender;

@end
