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

@implementation AdwareManager

@synthesize window = myWindow;
@synthesize textView = myTextView;
@synthesize tableView = myTableView;
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
  [self.window makeKeyAndOrderFront: self];
  
  NSMutableAttributedString * details = [NSMutableAttributedString new];
  
  [details appendString: NSLocalizedString(@"adware", NULL)];

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
  
  myAdwareFiles = [NSMutableArray new];
  
  for(NSString * adware in [[Model model] adwareFiles])
    [myAdwareFiles addObject: adware];
    
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
