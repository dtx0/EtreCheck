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

#define kDelete @"delete"
#define kWhitelist @"whitelist"
#define kPath @"path"

@implementation UnknownFilesManager

@synthesize window = myWindow;
@synthesize textView = myTextView;
@synthesize tableView = myTableView;
@synthesize deleteIndicators = myDeleteIndicators;
@synthesize whitelistIndicators = myWhitelistIndicators;
@synthesize unknownFiles = myUnknownFiles;
@synthesize whitelistDescription = myWhitelistDescription;
@dynamic canDelete;
@dynamic canAddToWhitelist;

// Can I delete something?
- (BOOL) canDelete
  {
  BOOL canDelete = NO;

  NSUInteger count = [self.unknownFiles count];
  
  for(NSUInteger i = 0; i < count; ++i)
    if([[self.deleteIndicators objectAtIndex: i] boolValue])
      canDelete = YES;
    
  return canDelete;
  }

// Can I add something to the whitelist?
- (BOOL) canAddToWhitelist
  {
  BOOL canAdd = NO;

  NSUInteger count = [self.unknownFiles count];
  
  for(NSUInteger i = 0; i < count; ++i)
    if([[self.whitelistIndicators objectAtIndex: i] boolValue])
      canAdd = YES;
    
  return canAdd;
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
  
  self.deleteIndicators = nil;
  self.whitelistIndicators = nil;
  self.unknownFiles = nil;
  self.whitelistDescription = nil;
  }

// Show the window.
- (void) show
  {
  [self.window makeKeyAndOrderFront: self];
  
  NSMutableAttributedString * details = [NSMutableAttributedString new];
  
  [details appendString: NSLocalizedString(@"unknownfiles", NULL)];

  NSData * rtfData =
    [details
      RTFFromRange: NSMakeRange(0, [details length])
      documentAttributes: @{}];

  NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);
  
  [self.textView replaceCharactersInRange: range withRTF: rtfData];
  [self.textView setFont: [NSFont systemFontOfSize: 13]];
  
  [self.textView setEditable: YES];
  [self.textView setEnabledTextCheckingTypes: NSTextCheckingTypeLink];
  [self.textView checkTextInDocument: nil];
  [self.textView setEditable: NO];

  [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
    
  [details release];
  
  myWhitelistIndicators = [NSMutableArray new];
  myDeleteIndicators = [NSMutableArray new];
  
  NSUInteger count = [[[Model model] unknownFiles] count];
  
  for(NSUInteger i = 0; i < count; ++i)
    {
    [myDeleteIndicators addObject: [NSNumber numberWithBool: NO]];
    [myWhitelistIndicators addObject: [NSNumber numberWithBool: NO]];
    }
    
  self.unknownFiles =
    [NSMutableArray
      arrayWithArray: [[[Model model] unknownFiles] allObjects]];
  
  [self.tableView reloadData];
  }

// Close the window.
- (IBAction) close: (id) sender
  {
  [self.window close];
  }

// Remove the adware.
- (IBAction) removeAdware: (id) sender
  {
  if(![[Model model] backupExists])
    {
    [Utilities reportNoBackup];
    
    return;
    }
    
  NSUInteger count = [self.unknownFiles count];
  
  NSMutableArray * paths = [NSMutableArray array];
  
  for(NSUInteger i = 0; i < count; ++i)
    if([[self.deleteIndicators objectAtIndex: i] boolValue])
      [paths addObject: [self.unknownFiles objectAtIndex: i]];
    
  [Utilities
    removeFiles: paths
      completionHandler:
        ^(NSDictionary * newURLs, NSError * error)
          {
          [self willChangeValueForKey: @"canDelete"];
          [self willChangeValueForKey: @"canAddToWhitelist"];
          
          NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
          NSMutableArray * deletedFiles = [NSMutableArray array];
          
          for(NSUInteger i = 0; i < count; ++i)
            {
            NSString * path = [self.unknownFiles objectAtIndex: i];
            NSURL * url = [NSURL fileURLWithPath: path];
            
            if([newURLs objectForKey: url])
              {
              [[[Model model] unknownFiles] removeObject: path];
              [deletedFiles addObject: path];
              [indexSet addIndex: i];
              }
            }
            
          [self.whitelistIndicators removeObjectsAtIndexes: indexSet];
          [self.unknownFiles removeObjectsAtIndexes: indexSet];
          [self.deleteIndicators removeObjectsAtIndexes: indexSet];
          
          [self.tableView reloadData];

          [self didChangeValueForKey: @"canAddToWhitelist"];
          [self didChangeValueForKey: @"canDelete"];
          
          [self reportDeletedFiles: deletedFiles];
          }];
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
    [message appendFormat: @"- %@\n", path];
    
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

// Contact Etresoft to add to whitelist.
- (IBAction) addToWhitelist: (id) sender
  {
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"{\"files\":["];
  
  bool first = YES;
  
  NSUInteger index = 0;
  
  for(; index < self.whitelistIndicators.count; ++index)
    {
    NSString * path =
      [[self.unknownFiles objectAtIndex: index]
        stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
    
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json
      appendString:
        [NSString
          stringWithFormat:
            @"{\"deleted\": %@, \"known\": %@, \"path\":\"%@\"}",
            [self.deleteIndicators objectAtIndex: index],
            [self.whitelistIndicators objectAtIndex: index],
            path]];
    }
    
  [json appendString: @"],"];
  [json
    appendFormat:
      @"\"description\":\"%@\"}",
      [[self.whitelistDescription string]
        stringByReplacingOccurrencesOfString: @"\"" withString: @"'"]];
  
  NSString * server = @"http://etrecheck.com/server/addtowhitelist.php";
  
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
      [self thanksForWhitelist];
    else
      [self uploadWhitelistFallbackToEmail];
      
    [status release];
    }
  }

// Thank the user for their whitelist submission.
- (void) thanksForWhitelist
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Thanks for your submission", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"thanksforwhitelist", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

- (void) uploadWhitelistFallbackToEmail
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Whitelist upload failed", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"whitelistuploadfailed", NULL)];

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
              @"%@ %@ %@\n",
              [[self.deleteIndicators objectAtIndex: index] boolValue]
                ? @"Deleted" : @"Kept",
              [[self.whitelistIndicators objectAtIndex: index] boolValue]
                ? @"Known" : @"Unknown",
              [self.unknownFiles objectAtIndex: index]]];
      }
      
    [content appendString: @"\n\n"];
    [content appendString: [self.whitelistDescription string]];
    [content appendString: @"\n"];
      
    [self
      sendEmailTo: @"info@etresoft.com"
      withSubject: @"Add to whitelist"
      content: content];
    }

  [alert release];
  }

// Send an e-mail.
- (void) sendEmailTo: (NSString *) toAddress
  withSubject: (NSString *) subject
  content: (NSString *) bodyText
  {
  NSString * emailString =
    [NSString
      stringWithFormat:
        NSLocalizedString(@"addtowhitelistemail", NULL),
        subject, bodyText, @"Etresoft support", toAddress ];


  NSAppleScript * emailScript =
    [[NSAppleScript alloc] initWithSource: emailString];

  [emailScript executeAndReturnError: nil];
  [emailScript release];
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
  if([[aTableColumn identifier] isEqualToString: kDelete])
    return [self.deleteIndicators objectAtIndex: rowIndex];
  
  else if([[aTableColumn identifier] isEqualToString: kWhitelist])
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
  if([[tableColumn identifier] isEqualToString: kDelete])
    {
    [self willChangeValueForKey: @"canDelete"];
    
    [self.deleteIndicators replaceObjectAtIndex: row withObject: object];
    
    [self.whitelistIndicators
      replaceObjectAtIndex: row withObject: [NSNumber numberWithBool: NO]];
    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: 1]];
    
    [self didChangeValueForKey: @"canDelete"];
    }
    
  else if([[tableColumn identifier] isEqualToString: kWhitelist])
    {
    [self willChangeValueForKey: @"canAddToWhitelist"];
    
    [self.whitelistIndicators replaceObjectAtIndex: row withObject: object];

    [self.deleteIndicators
      replaceObjectAtIndex: row withObject: [NSNumber numberWithBool: NO]];
    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: 0]];

    [self didChangeValueForKey: @"canAddToWhitelist"];
    }
  }

@end
