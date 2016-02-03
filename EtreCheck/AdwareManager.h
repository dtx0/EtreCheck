/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "AdminManager.h"

@interface AdwareManager : AdminManager
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSMutableArray * myAdwareFiles;
  }

// Can I delete something?
@property (readonly) BOOL canDelete;

// Array of adware files.
@property (retain) NSMutableArray * adwareFiles;

@end
