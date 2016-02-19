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
  NSMutableArray * myWhitelistIndicators;
  NSMutableArray * myUnknownFiles;
  NSAttributedString * myWhitelistDescription;
  }

// Array of NSNumber booleans to indicate known files.
@property (retain) NSMutableArray * whitelistIndicators;

// Array of unknown files.
@property (retain) NSMutableArray * unknownFiles;

// User's whitelist description.
@property (retain) NSAttributedString * whitelistDescription;

// Contact Etresoft to add to whitelist.
- (IBAction) report: (id) sender;

@end
