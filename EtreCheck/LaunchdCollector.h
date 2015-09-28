/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "Collector.h"

#define kStatus @"status"
#define kHidden @"hidden"
#define kPrinted @"printed"
#define kSignatureVerified @"signatureverified"
#define kApple @"apple"
#define kFilename @"filename"
#define kExecutable @"executable"
#define kSupportURL @"supporturl"
#define kDetailsURL @"detailsurl"
#define kPlist @"plist"

#define kStatusUnknown @"unknown"
#define kStatusNotLoaded @"notloaded"
#define kStatusLoaded @"loaded"
#define kStatusRunning @"running"
#define kStatusFailed @"failed"
#define kStatusInvalid @"invalid"
#define kStatusKilled @"killed"

@interface LaunchdCollector : Collector
  {
  NSMutableDictionary * myHiddenItems;
  bool myShowExecutable;
  NSUInteger myPressureKilledCount;
  }

// These need to be shared by all launchd collector objects.
@property (retain) NSMutableDictionary * launchdStatus;
@property (retain) NSMutableSet * appleLaunchd;
@property (assign) bool showExecutable;
@property (assign) NSUInteger pressureKilledCount;

// Print a list of files.
- (void) printPropertyListFiles: (NSArray *) paths;

// Format a status string.
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) status;

// Release memory.
+ (void) cleanup;

@end
