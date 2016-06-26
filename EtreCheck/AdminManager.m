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
  self.launchdTasksToUnload = nil;

  [self.window close];
  }

// Remove the adware.
- (IBAction) removeFiles: (id) sender
  {
  // Due to whatever funky is going on inside OS X and AppleScript, this
  // must be run from the main thread.
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      if(![self canRemoveFiles])
        return;
        
      [self reportFiles];
      [Utilities uninstallLaunchdTasks: self.launchdTasksToUnload];
      [Utilities deleteFiles: self.filesToRemove];
      [self verifyRemoveFiles];
    });
  }

// Can I remove files?
- (BOOL) canRemoveFiles
  {
  NSUInteger count =
    [self.filesToRemove count] + [self.launchdTasksToUnload count];
    
  if(count == 0)
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

// Verify removal of files.
- (void) verifyRemoveFiles
  {
  BOOL failed = NO;
  
  NSMutableArray * filesRemoved = [NSMutableArray new];
  
  for(NSDictionary * info in self.launchdTasksToUnload)
    {
    NSString * path = [info objectForKey: kPath];
    
    if([path length])
      {
      BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: path];
      
      if(exists)
        failed = YES;
      else
        [filesRemoved addObject: path];
      }
    }
    
  for(NSString * path in self.filesToRemove)
    {
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: path];
    
    if(exists)
      failed = YES;
    else
      [filesRemoved addObject: path];
    }
    
  if(failed)
    [self reportDeletedFilesFailed: filesRemoved];
  else
    [self reportDeletedFiles: filesRemoved];

  [filesRemoved release];
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
- (void) reportDeletedFiles: (NSArray *) filesRemoved
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      TTTLocalizedPluralString(
        [filesRemoved count], @"file deleted", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
  for(NSString * path in filesRemoved)
    [message appendFormat: @"%@\n", path];
    
  [alert setInformativeText: message];

  [alert runModal];
  
  [alert release];
  }

// Report which files were deleted.
- (void) reportDeletedFilesFailed: (NSArray *) filesRemoved
  {
  NSUInteger count = [filesRemoved count];
  
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: TTTLocalizedPluralString(count, @"file deleted", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  if(count == 0)
    {
    [message appendString: NSLocalizedString(@"nofilesdeleted", NULL)];

    [alert setInformativeText: message];
    
    [alert runModal];
    }
  else
    {
    [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
    for(NSString * path in filesRemoved)
      [message appendFormat: @"%@\n", path];
      
    [message appendString: NSLocalizedString(@"filesdeletedfailed", NULL)];
    
    [alert setInformativeText: message];

    [alert runModal];
    }

  [alert release];
  }

@end
