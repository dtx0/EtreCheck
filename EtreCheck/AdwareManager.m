/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "AdwareManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"

@interface AdminManager ()

// Show the window with content.
- (void) show: (NSString *) content;

// Verify removal of files.
- (void) verifyRemoveFiles;

// Suggest a restart.
- (void) suggestRestart;

@end

@implementation AdwareManager

@synthesize adwareFiles = myAdwareFiles;

// Destructor.
- (void) dealloc
  {
  [super dealloc];
  
  self.adwareFiles = nil;
  }

// Show the window.
- (void) show
  {
  [super show: NSLocalizedString(@"adware", NULL)];
  
  self.filesDeleted = NO;
  
  [self willChangeValueForKey: @"canRemoveFiles"];
  
  myAdwareFiles = [NSMutableArray new];

  NSMutableSet * filesToRemove = [NSMutableSet new];
  
  for(NSString * path in [[Model model] adwareLaunchdFiles])
    {
    NSDictionary * info = [[[Model model] launchdFiles] objectForKey: path];

    NSNumber * PID = [info objectForKey: kPID];
      
    if(PID)
      [self.launchdTasksToUnload addObject: path];
    else
      [filesToRemove addObject: path];
    }
    
  for(NSString * path in [[Model model] adwareFiles])
    {
    // Double-check to make sure the file is still there.
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: path];
    
    if(exists)
      {
      NSString * pathToRemove = [Utilities makeURLPath: path];
      
      [filesToRemove addObject: pathToRemove];
      [self.adwareFiles addObject: pathToRemove];
      }
    }
    
  [self.filesToRemove addObjectsFromArray: [filesToRemove allObjects]];
  
  [self.tableView reloadData];
  
  [self didChangeValueForKey: @"canRemoveFiles"];
  }

// Close the window.
- (IBAction) close: (id) sender
  {
  self.adwareFiles = nil;

  [super close: sender];
  }

// Suggest a restart.
- (void) suggestRestart
  {
  [super suggestRestart];
  }

// Verify removal of files.
- (void) verifyRemoveFiles
  {
  [self willChangeValueForKey: @"canRemoveFiles"];
  
  for(NSString * path in self.filesToRemove)
    [self.adwareFiles removeObject: path];

  self.filesDeleted =
    [self.adwareFiles count] != [self.filesToRemove count];
  
  [self.tableView reloadData];

  [self didChangeValueForKey: @"canRemoveFiles"];
  
  [super verifyRemoveFiles];
        
  for(NSString * path in self.filesToRemove)
    [self.filesToRemove removeObject: path];
  }

#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView: (NSTableView *) aTableView
  {
  return self.adwareFiles.count;
  }

- (id) tableView: (NSTableView *) aTableView
  objectValueForTableColumn: (NSTableColumn *) aTableColumn
  row: (NSInteger) rowIndex
  {
  return [self.adwareFiles objectAtIndex: rowIndex];
  }

@end
