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

@end

@implementation AdwareManager

@synthesize adwareFiles = myAdwareFiles;

@dynamic canDelete;

// Can I delete something?
- (BOOL) canDelete
  {
  return [self.adwareFiles count] > 0;
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
  
  [self willChangeValueForKey: @"canDelete"];
  
  myAdwareFiles = [NSMutableArray new];
  
  for(NSString * adware in [[Model model] adwareFiles])
    [myAdwareFiles addObject: [Utilities makeURLPath: adware]];
    
  [myAdwareFiles sortUsingSelector: @selector(compare:)];

  [self.tableView reloadData];
  
  [self didChangeValueForKey: @"canDelete"];
  }

// Remove the adware.
- (IBAction) removeAdware: (id) sender
  {
  if(![self canRemoveAdware])
    return;
    
  [self reportAdware];
  
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
              [[[Model model] adwareFiles] removeObjectForKey: path];
              [deletedFiles addObject: path];
              [indexSet addIndex: i];
              }
            }
            
          [self willChangeValueForKey: @"canDelete"];
          
          [self.adwareFiles removeObjectsAtIndexes: indexSet];
          
          [self.tableView reloadData];

          [self didChangeValueForKey: @"canDelete"];
          
          if([self.adwareFiles count] > 0)
            [self reportDeletedFilesFailed: deletedFiles];
          else
            [self reportDeletedFiles: deletedFiles];
          }];
  }

// Report the adware.
- (void) reportAdware
  {
  if([[Model model] oldEtreCheckVersion])
    {
    [self reportOldEtreCheckVersion];
    return;
    }
    
  if(![[Model model] verifiedEtreCheckVersion])
    {
    [self reportUnverifiedEtreCheckVersion];
    return;
    }
    
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"{\"action\":\"addtoblacklist\","];
  [json appendString: @"\"files\":["];
  
  bool first = YES;
  
  NSUInteger index = 0;
  
  for(; index < [self.adwareFiles count]; ++index)
    {
    NSString * path =
      [[self.adwareFiles objectAtIndex: index]
        stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
    
    NSString * name = [path lastPathComponent];
    NSString * cmd = @"";
    
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json appendString: @"{"];
    
    [json appendFormat: @"\"name\":\"%@\",", name];
    [json appendFormat: @"\"path\":\"%@\",", path];
    [json appendFormat: @"\"cmd\":\"%@\"", cmd];
    
    [json appendString: @"}"];
    }
    
  [json appendString: @"]}"];
  
  NSString * server = @"http://etrecheck.com/server/adware_detection.php";
  
  NSArray * args =
    @[
      @"--data",
      json,
      server
    ];

  [Utilities execute: @"/usr/bin/curl" arguments: args];

  NSData * result = [Utilities execute: @"/usr/bin/curl" arguments: args];

  if(result)
    {
    NSString * status =
      [[NSString alloc]
        initWithData: result encoding: NSUTF8StringEncoding];
      
    if([status isEqualToString: @"OK"])
      NSLog(@"adware report successful");
    else
      NSLog(@"adware report failed");
      
    [status release];
    }
  }

// Can I remove adware?
- (BOOL) canRemoveAdware
  {
  if([[Model model] oldEtreCheckVersion])
    return [self reportOldEtreCheckVersion];
    
  if(![[Model model] verifiedEtreCheckVersion])
    return [self reportUnverifiedEtreCheckVersion];

  if([[Model model] majorOSVersion] < kMountainLion)
    return [self warnBackup];
    
  if(![[Model model] backupExists])
    {
    [self reportNoBackup];
    
    return NO;
    }
    
  return YES;
  }

// Warn the user to make a backup.
- (BOOL) warnBackup
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Cannot verify Time Machine backup!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(@"cannotverifytimemachinebackup", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle:
      NSLocalizedString(@"No, I don't have a backup", NULL)];

  [alert
    addButtonWithTitle: NSLocalizedString(@"Yes, I have a backup", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  return (result == NSAlertSecondButtonReturn);
  }

// Tell the user that EtreCheck won't delete files without a backup.
- (void) reportNoBackup
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"No Time Machine backup!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"notimemachinebackup", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

// Restart failed.
- (void) restartFailed
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Restart failed", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"restartfailed", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];
  
  [alert runModal];

  [alert release];
  }

// Report which files were deleted.
- (void) reportDeletedFiles: (NSArray *) paths
  {
  NSUInteger count = [paths count];
  
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: TTTLocalizedPluralString(count, @"file deleted", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
  for(NSString * path in paths)
    [message appendFormat: @"%@\n", path];
    
  [alert setInformativeText: message];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Restart", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Restart later", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  if(result == NSAlertFirstButtonReturn)
    {
    if(![Utilities restart])
      [self restartFailed];
    }
  }

// Report which files were deleted.
- (void) reportDeletedFilesFailed: (NSArray *) paths
  {
  NSUInteger count = [paths count];
  
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: TTTLocalizedPluralString(count, @"file deleted", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  if([paths count] == 0)
    {
    [message appendString: NSLocalizedString(@"nofilesdeleted", NULL)];

    [alert setInformativeText: message];
    
    [alert runModal];
    }
  else
    {
    [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
    for(NSString * path in paths)
      [message appendFormat: @"%@\n", path];
      
    [message appendString: NSLocalizedString(@"filesdeletedfailed", NULL)];
    
    [alert setInformativeText: message];

    // This is the rightmost, first, default button.
    [alert addButtonWithTitle: NSLocalizedString(@"Restart", NULL)];

    [alert addButtonWithTitle: NSLocalizedString(@"Restart later", NULL)];

    NSInteger result = [alert runModal];

    [alert release];

    if(result == NSAlertFirstButtonReturn)
      {
      if(![Utilities restart])
        [self restartFailed];
      }
    }
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
