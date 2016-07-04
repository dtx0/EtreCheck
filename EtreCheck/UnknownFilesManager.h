/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "UninstallManager.h"

@interface UnknownFilesManager : UninstallManager
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSAttributedString * myWhitelistDescription;
  NSButton * myRemoveButton;
  }

// User's whitelist description.
@property (retain) NSAttributedString * whitelistDescription;

// The table view.
@property (retain) IBOutlet NSButton * removeButton;

@end
