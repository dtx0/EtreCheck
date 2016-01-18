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
  NSMutableString * content = [NSMutableString string];
  
  [content appendString: @"EtreCheck found the following unknown files:\n"];
  
  for(NSString * path in [[Model model] unknownFiles])
    [content appendString: [NSString stringWithFormat: @"%@\n", path]];
    
  [self
    sendEmailTo: @"info@etresoft.com"
    withSubject: @"Add to whitelist"
    content: content];
  }

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
