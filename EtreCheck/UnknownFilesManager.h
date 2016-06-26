/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "AdminManager.h"

@interface UnknownFilesManager : AdminManager
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSMutableDictionary * myUnknownTasks;
  NSMutableArray * myUnknownFiles;
  NSMutableArray * myRemoveIndicators;
  NSMutableArray * myWhitelistIndicators;
  NSAttributedString * myWhitelistDescription;
  }

// Dictionary of unknown tasks.
@property (retain) NSMutableDictionary * unknownTasks;

// Array of unknown files.
@property (retain) NSMutableArray * unknownFiles;

// Array of NSNumber booleans to indicate files to be removed.
@property (retain) NSMutableArray * removeIndicators;

// Array of NSNumber booleans to indicate known files.
@property (retain) NSMutableArray * whitelistIndicators;

// User's whitelist description.
@property (retain) NSAttributedString * whitelistDescription;

// Is the report button enabled?
@property (readonly) BOOL canReport;

// Remove an unknown file.
- (IBAction) remove: (id) sender;

// Contact Etresoft to add to whitelist.
- (IBAction) report: (id) sender;

@end
