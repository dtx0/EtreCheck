/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "UnknownFilesManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"
#import "SubProcess.h"

#define kRemove @"remove"
#define kWhitelist @"whitelist"
#define kPath @"path"

@interface AdminManager ()

// Show the window with content.
- (void) show: (NSString *) content;

// Verify removal of files.
- (void) verifyRemoveFiles;

// Suggest a restart.
- (void) suggestRestart;

@end

@implementation UnknownFilesManager

@synthesize unknownTasks = myUnknownTasks;
@synthesize unknownFiles = myUnknownFiles;
@synthesize removeIndicators = myRemoveIndicators;
@synthesize whitelistIndicators = myWhitelistIndicators;
@synthesize whitelistDescription = myWhitelistDescription;

// Is the report button enabled?
- (BOOL) canReport
  {
  BOOL canReport = NO;
  
  for(NSNumber * whitelistIndicator in self.whitelistIndicators)
    if([whitelistIndicator boolValue])
      canReport = YES;
    
  return canReport;
  }

// Constructor.
- (id) init
  {
  if(self = [super init])
    {
    myWhitelistDescription = [NSAttributedString new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [super dealloc];
  
  self.unknownTasks = nil;
  self.unknownFiles = nil;
  self.removeIndicators = nil;
  self.whitelistIndicators = nil;
  self.whitelistDescription = nil;
  }

// Show the window.
- (void) show
  {
  [super show: NSLocalizedString(@"unknownfiles", NULL)];
  
  self.filesDeleted = NO;
  
  myUnknownTasks = [NSMutableDictionary new];
  myUnknownFiles = [NSMutableArray new];
  myRemoveIndicators = [NSMutableArray new];
  myWhitelistIndicators = [NSMutableArray new];
  
  for(NSString * path in [[Model model] unknownLaunchdFiles])
    {
    NSDictionary * info = [[[Model model] launchdFiles] objectForKey: path];
    
    if(info)
      {
      [myUnknownTasks setObject: info forKey: path];
      [myUnknownFiles addObject: path];
      [myRemoveIndicators addObject: [NSNumber numberWithBool: NO]];
      [myWhitelistIndicators addObject: [NSNumber numberWithBool: NO]];
      }
    }
    
  [myUnknownFiles sortUsingSelector: @selector(compare:)];
  
  [self.tableView reloadData];
  }

// Close the window.
- (IBAction) close: (id) sender
  {
  self.unknownTasks = nil;
  self.unknownFiles = nil;
  self.removeIndicators = nil;
  self.whitelistIndicators = nil;
  self.whitelistDescription = nil;

  [super close: sender];
  }

// Suggest a restart.
- (void) suggestRestart
  {
  [super suggestRestart];
  }

// Remove an unknown file.
- (IBAction) remove: (id) sender
  {
  NSUInteger index = [[self tableView] clickedRow];
  
  NSString * path = [self.unknownFiles objectAtIndex: index];
    
  NSDictionary * info = [[[Model model] launchdFiles] objectForKey: path];
  
  NSNumber * PID = [info objectForKey: kPID];
    
  if(PID)
    [self.launchdTasksToUnload addObject: info];
  else
    [self.filesToRemove addObject: path];
    
  [super removeFiles: sender];
  }

// Verify removal of files.
- (void) verifyRemoveFiles
  {
  for(NSString * path in self.filesToRemove)
    {
    NSUInteger index = [self.unknownFiles indexOfObject: path];
    
    [self.unknownFiles removeObjectAtIndex: index];
    [self.removeIndicators removeObjectAtIndex: index];
    [self.whitelistIndicators removeObjectAtIndex: index];
    
    [[[Model model] launchdFiles] removeObjectForKey: path];
    
    self.filesDeleted = YES;
    }
    
  [self.tableView reloadData];

  [super verifyRemoveFiles];
  
  [self.filesToRemove removeAllObjects];
  }

// Contact Etresoft to add to whitelist.
- (IBAction) report: (id) sender
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
  
  [json appendString: @"{\"action\":\"report\","];
  [json appendString: @"\"files\":["];
  
  bool first = YES;
  
  NSUInteger index = 0;
  
  for(; index < self.whitelistIndicators.count; ++index)
    {
    NSString * path = [self.unknownFiles objectAtIndex: index];
    
    if(!path)
      continue;
      
    NSDictionary * info = [self.unknownTasks objectForKey: path];
    
    if(!info)
      continue;
      
    NSString * cmd =
      [path length] > 0
        ? [info objectForKey: path]
        : @"";
    
    path =
      [path stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
      
    NSString * name = [path lastPathComponent];
    
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json appendString: @"{"];
    
    [json
      appendFormat:
        @"\"known\":\"%@\",",
        [self.whitelistIndicators objectAtIndex: index]];
    
    [json appendFormat: @"\"name\":\"%@\",", name];
    [json appendFormat: @"\"path\":\"%@\",", path];
    [json appendFormat: @"\"cmd\":\"%@\"", cmd];
      
    [json appendString: @"}"];
    }
    
  [json appendString: @"],"];
  [json
    appendFormat:
      @"\"description\":\"%@\"}",
      [[self.whitelistDescription string]
        stringByReplacingOccurrencesOfString: @"\"" withString: @"'"]];
  
  NSString * server = @"https://etrecheck.com/server/adware_detection.php";
  
  NSArray * args =
    @[
      @"-s",
      @"--data",
      json,
      server
    ];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/curl" arguments: args])
    {
    NSString * status =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
      
    if([status isEqualToString: @"OK"])
      [self thanksForSubmission];
    else
      [self submissionFallbackToEmail];
      
    [status release];
    }
    
  [subProcess release];
  }

// Thank the user for their submission.
- (void) thanksForSubmission
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Thanks for your submission", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"thanksforsubmission", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

// Allow the user to submit an update via e-mail.
- (void) submissionFallbackToEmail
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Submission failed", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"submissionfailed", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle: NSLocalizedString(@"Yes - Send via e-mail", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"No", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertFirstButtonReturn)
    {
    NSMutableString * content = [NSMutableString string];
    
    [content
      appendString: @"EtreCheck found the following unknown files:\n\n"];

    NSUInteger index = 0;
    
    for(; index < self.whitelistIndicators.count; ++index)
      {
      [content
        appendString:
          [NSString
            stringWithFormat:
              @"%@ %@\n",
              [[self.whitelistIndicators objectAtIndex: index] boolValue]
                ? @"Known" : @"Unknown",
              [self.unknownFiles objectAtIndex: index]]];
      }
      
    [content appendString: @"\n\n"];
    [content appendString: [self.whitelistDescription string]];
    [content appendString: @"\n"];
      
    [Utilities
      sendEmailTo: @"info@etresoft.com"
      withSubject: @"Unknown files report"
      content: content];
    }

  [alert release];
  }

#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView: (NSTableView *) aTableView
  {
  return self.whitelistIndicators.count;
  }

- (id) tableView: (NSTableView *) aTableView
  objectValueForTableColumn: (NSTableColumn *) aTableColumn
  row: (NSInteger) rowIndex
  {
  if([[aTableColumn identifier] isEqualToString: kWhitelist])
    return [self.whitelistIndicators objectAtIndex: rowIndex];

  else if([[aTableColumn identifier] isEqualToString: kPath])
    return [self.unknownFiles objectAtIndex: rowIndex];
    
  return nil;
  }

- (void) tableView: (NSTableView *) tableView
  setObjectValue: (id) object
  forTableColumn: (NSTableColumn *) tableColumn
  row: (NSInteger) row
  {
  if([[tableColumn identifier] isEqualToString: kWhitelist])
    {
    [self willChangeValueForKey: @"canReport"];
    
    [self.whitelistIndicators replaceObjectAtIndex: row withObject: object];

    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: 0]];

    [self didChangeValueForKey: @"canReport"];
      
    NSButtonCell * cell =
      [[tableView tableColumnWithIdentifier: kRemove] dataCellForRow: row];
      
    [cell setEnabled: ![object boolValue]];
    }
  }

#pragma mark - NSTableViewDelegate

@end
