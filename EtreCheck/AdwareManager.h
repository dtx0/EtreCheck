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
  NSMutableArray * myAdwareLaunchdFiles;
  NSMutableArray * myAdwareProcesses;
  }

// Can I delete something?
@property (readonly) BOOL canDelete;

// Array of adware files.
@property (retain) NSMutableArray * adwareFiles;

// Array of adware launchd files.
@property (retain) NSMutableArray * adwareLaunchdFiles;

// Array of adware processes.
@property (retain) NSMutableArray * adwareProcesses;

@end
