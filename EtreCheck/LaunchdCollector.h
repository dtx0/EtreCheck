/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "Collector.h"

#define kStatus @"status"
#define kPID @"PID"
#define kHidden @"hidden"
#define kPrinted @"printed"
#define kIgnored @"ignored"
#define kSignature @"signature"
#define kApple @"apple"
#define kFilename @"filename"
#define kExecutable @"executable"
#define kCommand @"command"
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
@property (retain) NSMutableSet * knownAppleFailures;
@property (retain) NSMutableSet * knownAppleSignatureFailures;

// Print a list of files.
- (void) printPropertyListFiles: (NSArray *) paths;

// Format a status string.
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) status;

// Get the job status.
- (NSMutableDictionary *) collectJobStatus: (NSDictionary *) plist;

// Collect the command of the launchd item.
- (NSArray *) collectLaunchdItemCommand: (NSDictionary *) plist;

// Collect the actual executable from a command.
- (NSString *) collectLaunchdItemExecutable: (NSArray *) command;

// Is this an Apple file that I expect to see?
- (bool) isAppleFile: (NSString *) file;

// Should I ignore these invalid signatures?
- (bool) ignoreInvalidSignatures: (NSString *) file;

// Format a codesign response.
- (NSString *) formatAppleSignature: (NSDictionary *) status;

// Create a support link for a plist dictionary.
- (NSAttributedString *) formatSupportLink: (NSDictionary *) status;

// Release memory.
+ (void) cleanup;

@end
