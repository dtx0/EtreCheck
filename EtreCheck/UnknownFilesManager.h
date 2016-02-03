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
  NSMutableArray * myDeleteIndicators;
  NSMutableArray * myWhitelistIndicators;
  NSMutableArray * myUnknownFiles;
  NSAttributedString * myWhitelistDescription;
  }

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

// Contact Etresoft to add to whitelist.
- (IBAction) addToWhitelist: (id) sender;

@end
