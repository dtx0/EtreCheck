/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "UnknownFilesManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

@interface PopoverManager ()

// Show detail.
- (void) showDetail: (NSString *) title
  content: (NSAttributedString *) content;

@end

@implementation UnknownFilesManager

@synthesize downloadButton = myDownloadButton;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myMinPopoverSize = NSMakeSize(500, 200);
    }
  
  return self;
  }

// Show detail.
- (void) showDetail: (NSString *) name
  {
  if([[Model model] hasMalwareBytes])
    self.downloadButton.title = NSLocalizedString(@"runmbam", NULL);
  else
    self.downloadButton.title = NSLocalizedString(@"downloadmbam", NULL);

  NSMutableAttributedString * details = [NSMutableAttributedString new];
  
  [details appendString: NSLocalizedString(@"unknownfiles", NULL)];

  [super
    showDetail: NSLocalizedString(@"About unknown files", NULL)
    content: details];      
    
  [details release];
  }

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender
  {
  if([[Model model] hasMalwareBytes])
    {
    NSURL * url =
      [[NSWorkspace sharedWorkspace]
        URLForApplicationWithBundleIdentifier:
          @"com.malwarebytes.antimalware"];
      
    [[NSWorkspace sharedWorkspace] openURL: url];
    
    return;
    }
  
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL
        URLWithString: @"http://www.malwarebytes.org/antimalware/mac/"]];
  }

// Contact Etresoft to add to whitelist.
- (IBAction) addToWhitelist: (id) sender
  {
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"["];
  
  bool first = YES;
  
  for(NSString * path in [[Model model] unknownFiles])
    {
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json
      appendString:
        [NSString stringWithFormat: @"\"%@\"", [path lastPathComponent]]];
    }
    
  [json appendString: @"]"];
  
  NSString * server = @"http://etrecheck.com/server/whitelist.php";
  
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
      appendString: @"EtreCheck found the following unknown files:\n"];
    
    for(NSString * path in [[Model model] unknownFiles])
      [content appendString: [NSString stringWithFormat: @"%@\n", path]];
      
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

@end
