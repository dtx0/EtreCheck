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

@interface AdminManager ()

// Show the window with content.
- (void) show: (NSString *) content;

// Report which files were deleted.
- (void) reportDeletedFiles: (NSArray *) paths;

// Report which files were deleted.
- (void) reportDeletedFilesFailed: (NSArray *) paths;

// Restart failed.
- (void) restartFailed;

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
  
  myAdwareFiles = [NSMutableArray new];
  
  for(NSString * adware in [[Model model] adwareFiles])
    [myAdwareFiles addObject: adware];
    
  [self.tableView reloadData];
  }

// Remove the adware.
- (IBAction) removeAdware: (id) sender
  {
  if(![super canRemoveAdware])
    return;
    
  [Utilities
    removeFiles: self.adwareFiles
      completionHandler:
        ^(NSDictionary * newURLs, NSError * error)
          {
          NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
          NSMutableArray * deletedFiles = [NSMutableArray array];
          
          NSUInteger count = [self.adwareFiles count];
          
          for(NSUInteger i = 0; i < count; ++i)
            {
            NSString * path = [self.adwareFiles objectAtIndex: i];
            NSURL * url = [NSURL fileURLWithPath: path];
            
            if([newURLs objectForKey: url])
              {
              [[[Model model] unknownFiles] removeObject: path];
              [deletedFiles addObject: path];
              [indexSet addIndex: i];
              }
            }
            
          [self.adwareFiles removeObjectsAtIndexes: indexSet];
          
          [self.tableView reloadData];

          if([self.adwareFiles count] > 0)
            [self reportDeletedFilesFailed: deletedFiles];
          else
            [self reportDeletedFiles: deletedFiles];
          }];
  }

// Notify Etresoft.
- (void) reportDeletedFilesToEtresoft
  {
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"{\"files\":["];
  
  bool first = YES;
  
  NSUInteger index = 0;
  
  for(; index < self.adwareFiles.count; ++index)
    {
    NSString * path =
      [[self.adwareFiles objectAtIndex: index]
        stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
    
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json appendString: [NSString stringWithFormat: @"\"%@\"", path]];
    }
    
  NSString * server = @"http://etrecheck.com/server/addtoblacklist.php";
  
  NSArray * args =
    @[
      @"--data",
      json,
      server
    ];

  [Utilities execute: @"/usr/bin/curl" arguments: args];
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
