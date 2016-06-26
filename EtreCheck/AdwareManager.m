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

// Handle removal of files.
- (void) handleFileRemoval: (NSDictionary *) newURLs
  error: (NSError *) error;

// Suggest a restart.
- (void) suggestRestart;

@end

@implementation AdwareManager

@synthesize adwareFiles = myAdwareFiles;

// Can I remove files?
- (BOOL) canRemoveFiles
  {
  if([self.adwareFiles count] == 0)
    return NO;
    
  return [super canRemoveFiles];
  }

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

  for(NSString * path in [[Model model] adwareLaunchdFiles])
    {
    NSDictionary * info = [[[Model model] launchdFiles] objectForKey: path];

    NSNumber * PID = [info objectForKey: kPID];
      
    if(PID)
      {
      [self.launchdTasksToUnload addObject: path];
    
      [self.processesToKill addObject: PID];
      }
    }
    
  for(NSString * path in [[Model model] adwareFiles])
    {
    // Double-check to make sure the file is still there.
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: path];
    
    if(exists)
      {
      NSString * pathToRemove = [Utilities makeURLPath: path];
      
      [self.filesToRemove addObject: pathToRemove];
      [self.adwareFiles addObject: pathToRemove];
      }
    }
    
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

// Handle removal of files.
- (void) handleFileRemoval: (NSDictionary *) newURLs
  error: (NSError *) error
  {
  [self willChangeValueForKey: @"canRemoveFiles"];
  
  for(NSURL * url in newURLs)
    [self.adwareFiles removeObject: [url path]];

  self.filesDeleted =
    [self.adwareFiles count] != [self.filesToRemove count];
  
  [self.tableView reloadData];

  [self didChangeValueForKey: @"canRemoveFiles"];
  
  [super handleFileRemoval: newURLs error: error];
        
  for(NSURL * url in newURLs)
    [self.filesToRemove removeObject: [url path]];
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
