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

#define kWhitelist @"whitelist"
#define kPath @"path"

@interface AdminManager ()

// Show the window with content.
- (void) show: (NSString *) content;

@end

@implementation UnknownFilesManager

@synthesize whitelistIndicators = myWhitelistIndicators;
@synthesize unknownFiles = myUnknownFiles;
@synthesize whitelistDescription = myWhitelistDescription;

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
  
  self.whitelistIndicators = nil;
  self.unknownFiles = nil;
  self.whitelistDescription = nil;
  }

// Show the window.
- (void) show
  {
  [super show: NSLocalizedString(@"unknownfiles", NULL)];
  
  myWhitelistIndicators = [NSMutableArray new];
  
  NSUInteger count = [[[Model model] unknownFiles] count];
  
  for(NSUInteger i = 0; i < count; ++i)
    [myWhitelistIndicators addObject: [NSNumber numberWithBool: NO]];
    
  myUnknownFiles = [NSMutableArray new];
  
  for(NSString * adware in [[Model model] unknownFiles])
    [myUnknownFiles addObject: [Utilities makeURLPath: adware]];
  
  [myUnknownFiles sortUsingSelector: @selector(compare:)];
  
  [self.tableView reloadData];
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
    
    NSString * cmd =
      [path length] > 0
        ? [[[Model model] launchdCommands] objectForKey: path]
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
  
  NSString * server = @"http://etrecheck.com/server/adware_detection.php";
  
  NSArray * args =
    @[
      @"--data",
      json,
      server
    ];

  NSData * result = [Utilities execute: @"/usr/bin/curl" arguments: args];

  if(result)
    {
    NSString * status =
      [[NSString alloc]
        initWithData: result encoding: NSUTF8StringEncoding];
      
    if([status isEqualToString: @"OK"])
      [self thanksForSubmission];
    else
      [self submissionFallbackToEmail];
      
    [status release];
    }
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
    [self.whitelistIndicators replaceObjectAtIndex: row withObject: object];

    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: 0]];
    }
  }

@end
