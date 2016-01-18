/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface UnknownFilesManager : PopoverManager
  {
  NSButton * myDownloadButton;
  }

// The Adware Medic download button.
@property (retain) IBOutlet NSButton * downloadButton;

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender;

// Contact Etresoft to add to whitelist.
- (IBAction) addToWhitelist: (id) sender;

@end
