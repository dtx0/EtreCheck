/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "AdminManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"

@implementation AdminManager

@synthesize window = myWindow;
@synthesize textView = myTextView;
@synthesize tableView = myTableView;

// Show the window.
- (void) show
  {
  }

// Show the window with content.
- (void) show: (NSString *) content
  {
  [self.window makeKeyAndOrderFront: self];
  
  NSMutableAttributedString * details = [NSMutableAttributedString new];
  
  [details appendString: content];

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
  }

// Close the window.
- (IBAction) close: (id) sender
  {
  [self.window close];
  }

// Can I remove adware?
- (BOOL) canRemoveAdware
  {
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

@end
