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

#define kReport @"report"
#define kWhitelist @"whitelist"
#define kPath @"path"

@interface AdminManager ()

// Show the window with content.
- (void) show: (NSString *) content;

@end

@implementation UnknownFilesManager

@synthesize adwareIndicators = myAdwareIndicators;
@synthesize whitelistIndicators = myWhitelistIndicators;
@synthesize unknownFiles = myUnknownFiles;
@synthesize whitelistDescription = myWhitelistDescription;
@dynamic canReport;
@dynamic canAddToWhitelist;

// Can I report something?
- (BOOL) canReport
  {
  BOOL canReport = NO;

  NSUInteger count = [self.unknownFiles count];
  
  for(NSUInteger i = 0; i < count; ++i)
    if([[self.adwareIndicators objectAtIndex: i] boolValue])
      canReport = YES;
    
  return canReport;
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
  
  self.adwareIndicators = nil;
  self.whitelistIndicators = nil;
  self.unknownFiles = nil;
  self.whitelistDescription = nil;
  }

// Show the window.
- (void) show
  {
  [super show: NSLocalizedString(@"unknownfiles", NULL)];
  
  myWhitelistIndicators = [NSMutableArray new];
  myAdwareIndicators = [NSMutableArray new];
  
  NSUInteger count = [[[Model model] unknownFiles] count];
  
  for(NSUInteger i = 0; i < count; ++i)
    {
    [myAdwareIndicators addObject: [NSNumber numberWithBool: NO]];
    [myWhitelistIndicators addObject: [NSNumber numberWithBool: NO]];
    }
    
  myUnknownFiles = [NSMutableArray new];
  
  for(NSString * adware in [[Model model] unknownFiles])
    [myUnknownFiles addObject: [Utilities makeURLPath: adware]];
  
  [myUnknownFiles sortUsingSelector: @selector(compare:)];
  
  [self.tableView reloadData];
  }

// Report the adware.
- (IBAction) reportAdware: (id) sender
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
    
  NSUInteger count = [self.unknownFiles count];
  
  NSMutableArray * paths = [NSMutableArray array];
  
  for(NSUInteger i = 0; i < count; ++i)
    if([[self.adwareIndicators objectAtIndex: i] boolValue])
      [paths addObject: [self.unknownFiles objectAtIndex: i]];
    
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"{\"action\":\"addtoblacklist\","];
  [json appendString: @"\"files\":["];
  
  bool first = YES;
  
  NSUInteger index = 0;
  
  for(; index < [paths count]; ++index)
    {
    NSString * path =
      [[paths objectAtIndex: index]
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
      [self thanksForAdware];
    else
      [self uploadAdwareFallbackToEmail];
      
    [status release];
    }
  }

// Contact Etresoft to add to whitelist.
- (IBAction) addToWhitelist: (id) sender
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
  
  [json appendString: @"{\"action\":\"addtowhitelist\","];
  [json appendString: @"\"files\":["];
  
  bool first = YES;
  
  NSUInteger index = 0;
  
  for(; index < self.whitelistIndicators.count; ++index)
    {
    NSString * path =
      [[self.unknownFiles objectAtIndex: index]
        stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
    
    NSString * name = [path lastPathComponent];
    NSString * cmd = @"";
    
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json appendString: @"{"];
    
    [json
      appendFormat:
        @"\"adware\":\"%@\",",
        [self.adwareIndicators objectAtIndex: index]];
      
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

// Allow the user to submit an update via e-mail.
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
      withSubject: @"Add to whitelist"
      content: content];
    }

  [alert release];
  }

// Thank the user for their adware submission.
- (void) thanksForAdware
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Thanks for your submission", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"thanksforadware", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

// Allow the user to submit an update via e-mail.
- (void) uploadAdwareFallbackToEmail
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Adware upload failed", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"adwareuploadfailed", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle: NSLocalizedString(@"Yes - Send via e-mail", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"No", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertFirstButtonReturn)
    {
    NSMutableString * content = [NSMutableString string];
    
    [content
      appendString: @"EtreCheck found the following adware files:\n\n"];

    NSUInteger index = 0;
    
    for(; index < self.adwareIndicators.count; ++index)
      {
      if([[self.adwareIndicators objectAtIndex: index] boolValue])
        [content
          appendString:
            [NSString
              stringWithFormat:
                @"%@\n", [self.unknownFiles objectAtIndex: index]]];
      }
      
    [content appendString: @"\n"];
      
    [Utilities
      sendEmailTo: @"info@etresoft.com"
      withSubject: @"Add to blacklist"
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
  if([[aTableColumn identifier] isEqualToString: kReport])
    return [self.adwareIndicators objectAtIndex: rowIndex];
  
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
  if([[tableColumn identifier] isEqualToString: kReport])
    {
    [self willChangeValueForKey: @"canReport"];
    
    [self.adwareIndicators replaceObjectAtIndex: row withObject: object];
    
    [self.whitelistIndicators
      replaceObjectAtIndex: row withObject: [NSNumber numberWithBool: NO]];
    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: 1]];
    
    [self didChangeValueForKey: @"canReport"];
    }
    
  else if([[tableColumn identifier] isEqualToString: kWhitelist])
    {
    [self willChangeValueForKey: @"canAddToWhitelist"];
    
    [self.whitelistIndicators replaceObjectAtIndex: row withObject: object];

    [self.adwareIndicators
      replaceObjectAtIndex: row withObject: [NSNumber numberWithBool: NO]];
    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: 0]];

    [self didChangeValueForKey: @"canAddToWhitelist"];
    }
  }

@end
