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
#define kUnknown @"unknown"
#define kAdware @"adware"
#define kSignature @"signature"
#define kApple @"apple"
#define kPath @"path"
#define kFilename @"filename"
#define kExecutable @"executable"
#define kCommand @"command"
#define kLabel @"Label"
#define kApp @"app"
#define kSupportURL @"supporturl"
#define kDetailsURL @"detailsurl"
#define kPlist @"plist"
#define kModificationDate @"modificationdate"

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
  NSUInteger myAppleNotLoadedCount;
  NSUInteger myAppleLoadedCount;
  NSUInteger myAppleRunningCount;
  NSUInteger myAppleKilledCount;
  }

// These need to be shared by all launchd collector objects.
@property (retain) NSMutableDictionary * launchdStatus;
@property (retain) NSMutableSet * appleLaunchd;
@property (assign) bool showExecutable;
@property (assign) NSUInteger pressureKilledCount;
@property (assign) NSUInteger AppleNotLoadedCount;
@property (assign) NSUInteger AppleLoadedCount;
@property (assign) NSUInteger AppleRunningCount;
@property (assign) NSUInteger AppleKilledCount;
@property (retain) NSMutableSet * knownAppleFailures;
@property (retain) NSMutableSet * knownAppleSignatureFailures;

// Collect property list files.
// Returns an array of plists for printing.
- (NSArray *) collectPropertyListFiles: (NSArray *) paths;

// Print property lists files.
- (void) printPropertyLists: (NSArray *) plists;

// Format a status into a string.
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) status;

// Get the job status.
- (NSMutableDictionary *) collectJobStatus: (NSString *) path;

// Collect the job status for a label.
- (NSMutableDictionary *) collectJobStatusForLabel: (NSString *) label;

// Collect the command of the launchd item.
- (NSArray *) collectLaunchdItemCommand: (NSDictionary *) plist;

// Collect the actual executable from a command.
- (NSString *) collectLaunchdItemExecutable: (NSArray *) command;

// Update a funky new dynamic task.
- (void) updateDynamicTask: (NSMutableDictionary *) info
  domain: (NSString *) domain;

// Is this an Apple file that I expect to see?
- (bool) isAppleFile: (NSString *) file;

// Should I ignore these invalid signatures?
- (bool) ignoreInvalidSignatures: (NSString *) file;

// Handle whitelist exceptions.
- (void) updateAppleCounts: (NSDictionary *) info;

// Format Apple counts.
// Return YES if there was any output.
- (bool) formatAppleCounts: (NSMutableAttributedString *) output;

// Format a codesign response.
- (NSString *) formatAppleSignature: (NSDictionary *) info;

// Create a support link for a plist dictionary.
- (NSAttributedString *) formatSupportLink: (NSDictionary *) info;

// Release memory.
+ (void) cleanup;

@end
