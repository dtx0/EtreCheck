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
#import "LaunchdCollector.h"
#import "SubProcess.h"

@implementation AdminManager

@synthesize window = myWindow;
@synthesize textView = myTextView;
@synthesize tableView = myTableView;
@synthesize launchdTasksToUnload = myLaunchdTasksToUnload;
@synthesize processesToKill = myProcessesToKill;
@synthesize filesToRemove = myFilesToRemove;
@synthesize filesDeleted = myFilesDeleted;

// Show the window.
- (void) show
  {
  }

// Show the window with content.
- (void) show: (NSString *) content
  {
  myLaunchdTasksToUnload = [NSMutableArray new];
  myProcessesToKill = [NSMutableArray new];
  myFilesToRemove = [NSMutableArray new];
  
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
  if(self.filesDeleted)
    [self suggestRestart];
  
  self.filesToRemove = nil;
  self.processesToKill = nil;
  self.launchdTasksToUnload = nil;

  [self.window close];
  }

// Remove the adware.
- (IBAction) removeFiles: (id) sender
  {
  if(![self canRemoveFiles])
    return;
    
  [self reportFiles];
  [self unloadFiles];
  [self killProcesses];
  [self removeFiles];
  }

// Can I remove files?
- (BOOL) canRemoveFiles
  {
  if([self.filesToRemove count] == 0)
    return NO;
    
  if([[Model model] oldEtreCheckVersion])
    return [self reportOldEtreCheckVersion];
    
  if(![[Model model] verifiedEtreCheckVersion])
    return [self reportUnverifiedEtreCheckVersion];

  if([[Model model] majorOSVersion] < kMountainLion)
    return [self warnBackup];
    
  if(![[Model model] backupExists])
    {
    NSNumber * override =
      [[NSUserDefaults standardUserDefaults]
        objectForKey: @"timemachineoverride"];
      
    if([override boolValue])
      return YES;
      
    [self reportNoBackup];
    
    return NO;
    }
    
  if([self needsAdministratorAuthorization])
    return [self requestAdministratorAuthorization];
    
  return YES;
  }

// Tell the user that EtreCheck is too old.
- (BOOL) reportOldEtreCheckVersion
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Outdated EtreCheck version!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"oldetrecheckversion", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];

  return NO;
  }

// Tell the user that the EtreCheck version is unverified.
- (BOOL) reportUnverifiedEtreCheckVersion
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Unverified EtreCheck version!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(@"unverifiedetrecheckversion", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];

  return NO;
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

- (BOOL) needsAdministratorAuthorization
  {
  for(NSString * path in self.filesToRemove)
    if(![[NSFileManager defaultManager] isDeletableFileAtPath: path])
      return YES;
      
  return NO;
  }

- (BOOL) requestAdministratorAuthorization
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Password required!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  NSString * message = NSLocalizedString(@"passwordrequired", NULL);
  
  [alert setInformativeText: message];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Yes", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"No", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  return (result == NSAlertFirstButtonReturn);
  }

// Unload the files.
- (void) unloadFiles
  {
  NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
  
  NSUInteger count = [self.launchdTasksToUnload count];
  
  for(NSUInteger i = 0; i < count; ++i)
    {
    NSDictionary * info = [self.launchdTasksToUnload objectAtIndex: i];

    [Utilities unloadLaunchdTask: info];

    [indexSet addIndex: i];
    }
  }
  
// Kill processes.
- (void) killProcesses
  {
  NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
  
  NSUInteger count = [self.processesToKill count];
  
  for(NSUInteger i = 0; i < count; ++i)
    {
    NSNumber * pid = [self.processesToKill objectAtIndex: i];

    [Utilities killProcess: pid];
    
    [[[Model model] processes] removeObject: pid];
    [indexSet addIndex: i];
    }
    
  [self.processesToKill removeObjectsAtIndexes: indexSet];
  }

// Remove the files.
- (void) removeFiles
  {
  [Utilities
    removeFiles: self.filesToRemove
    completionHandler:
      ^(NSDictionary * newURLs, NSError * error)
        {
        [self handleFileRemoval: newURLs error: error];
        }];
  }

// Handle removal of files.
- (void) handleFileRemoval: (NSDictionary *) newURLs
  error: (NSError *) error
  {
  if([self.filesToRemove count] != [newURLs count])
    [self reportDeletedFilesFailed: newURLs error: error];
  else
    [self reportDeletedFiles: newURLs];
  }

// Report the files.
- (void) reportFiles
  {
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"{\"action\":\"addtoblacklist\","];
  [json appendString: @"\"files\":["];
  
  bool first = YES;
  
  NSUInteger index = 0;
  
  for(; index < [self.filesToRemove count]; ++index)
    {
    NSString * path = [self.filesToRemove objectAtIndex: index];
    
    NSDictionary * info = [[[Model model] launchdFiles] objectForKey: path];
    
    NSString * command = [info objectForKey: kCommand];
      
    path =
      [path stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
      
    NSString * name = [path lastPathComponent];
    
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json appendString: @"{"];
    
    [json appendFormat: @"\"name\":\"%@\",", name];
    [json appendFormat: @"\"path\":\"%@\",", path];
    [json appendFormat: @"\"cmd\":\"%@\"", command ? command : @""];
    
    [json appendString: @"}"];
    }
    
  [json appendString: @"]}"];
  
  NSString * server = @"https://etrecheck.com/server/adware_detection.php";
  
  NSArray * args =
    @[
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
      {
      //NSLog(@"adware report successful");
      }
    else
      {
      //NSLog(@"adware report failed: %@", status);
      }
      
    [status release];
    }
    
  [subProcess release];
  }

// Suggest a restart.
- (void) suggestRestart
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Restart recommended", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  NSString * message = NSLocalizedString(@"restartrecommended", NULL);
  
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

// Report which files were deleted.
- (void) reportDeletedFiles: (NSDictionary *) newURLs
  {
  NSUInteger count = [newURLs count];
  
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: TTTLocalizedPluralString(count, @"file deleted", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
  for(NSURL * url in newURLs)
    [message appendFormat: @"%@\n", [url path]];
    
  [alert setInformativeText: message];

  [alert runModal];
  
  [alert release];
  }

// Report which files were deleted.
- (void) reportDeletedFilesFailed: (NSDictionary *) newURLs
  error: (NSError *) error
  {
  NSUInteger count = [newURLs count];
  
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: TTTLocalizedPluralString(count, @"file deleted", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  if([newURLs count] == 0)
    {
    NSString * reason = [error description];
    
    if([reason length])
      NSLog(@"Failed to delete files: %@", reason);
    
    [message appendString: NSLocalizedString(@"nofilesdeleted", NULL)];

    [alert setInformativeText: message];
    
    [alert runModal];
    }
  else
    {
    [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
    for(NSURL * url in newURLs)
      [message appendFormat: @"%@\n", [url path]];
      
    [message appendString: NSLocalizedString(@"filesdeletedfailed", NULL)];
    
    [alert setInformativeText: message];

    [alert runModal];
    }

  [alert release];
  }

@end
