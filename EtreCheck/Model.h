/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Major OS versions.
#define kSnowLeopard  10
#define kLion         11
#define kMountainLion 12
#define kMavericks    13
#define kYosemite     14
#define kElCapitan    15

// Critical errors
#define kHardDiskFailure @"harddiskfailure"
#define kNoBackups @"nobackup"
#define kLowHardDisk @"lowharddisk"
#define kLowRAM @"lowram"
#define kMemoryPressure @"memorypressure"
#define kAdware @"adware"
#define kOutdatedOS @"outdatedos"
#define kHighCache @"highcache"

#define kMinimumWhitelistSize 1000

@class DiagnosticEvent;

// A singleton to keep track of system information.
@interface Model : NSObject
  {
  int myMajorOSVersion;
  int myMinorOSVersion;
  NSMutableDictionary * myVolumes;
  NSMutableDictionary * myCoreStorageVolumes;
  NSMutableDictionary * myDiskErrors;
  NSNumber * myGPUErrors;
  NSArray * myLogEntries;
  NSDictionary * myApplications;
  int myPhysicalRAM;
  NSImage * myMachineIcon;
  NSDictionary * myProcesses;
  NSString * myModel;
  NSString * mySerialCode;
  NSMutableDictionary * myDiagnosticEvents;
  NSMutableDictionary * myAdwareFiles;
  NSMutableDictionary * myPotentialAdwareTrioFiles;
  NSArray * myAdwareExtensions;
  NSMutableSet * myWhitelistFiles;
  NSMutableSet * myWhitelistPrefixes;
  NSMutableSet * myBlacklistFiles;
  NSMutableSet * myBlacklistSuffixes;
  NSMutableSet * myBlacklistMatches;
  NSString * myComputerName;
  NSString * myHostName;
  bool myAdwareFound;
  NSMutableArray * myTerminatedTasks;
  NSMutableSet * myUnknownFiles;
  NSMutableSet * mySeriousProblems;
  bool myBackupExists;
  NSMutableDictionary * myLaunchdCommands;
  NSMutableDictionary * myLaunchdContents;
  
  bool myIgnoreKnownAppleFailures;
  bool myCheckAppleSignatures;
  bool myHideAppleTasks;
  bool myOldEtreCheckVersion;
  bool myVerifiedEtreCheckVersion;
  }

// Keep track of the OS version.
@property (assign) int majorOSVersion;
@property (assign) int minorOSVersion;

// Keep track of system volumes.
@property (retain) NSMutableDictionary * volumes;

// Keep track of CoreStorage volumes.
@property (retain) NSMutableDictionary * coreStorageVolumes;

// Keep track of disk errors.
@property (retain) NSMutableDictionary * diskErrors;

// Keep track of gpu errors.
@property (retain) NSNumber * gpuErrors;

// Keep track of log content.
@property (retain) NSArray * logEntries;

// Keep track of applications.
@property (retain) NSDictionary * applications;

// I will need the RAM amount (in GB) for later.
@property (assign) int physicalRAM;

// See if I can get the machine image.
@property (retain) NSImage * machineIcon;

// All processes.
@property (retain) NSDictionary * processes;

// The model code.
@property (retain) NSString * model;

// The serial number code for Apple lookups.
@property (retain) NSString * serialCode;

// Diagnostic events.
@property (retain) NSMutableDictionary * diagnosticEvents;

// Adware files.
@property (retain) NSMutableDictionary * adwareFiles;

// Adware files.
@property (retain) NSMutableDictionary * potentialAdwareTrioFiles;

// Adware extensions.
@property (retain) NSArray * adwareExtensions;

// Whitelist files.
@property (readonly) NSMutableSet * whitelistFiles;

// Whitelist prefixes.
@property (readonly) NSMutableSet * whitelistPrefixes;

// Blacklist files.
@property (readonly) NSMutableSet * blacklistFiles;

// Blacklist suffixes.
@property (readonly) NSMutableSet * blacklistSuffixes;

// Blacklist matches.
@property (readonly) NSMutableSet * blacklistMatches;

// Localized host name.
@property (retain) NSString * computerName;

// Host name.
@property (retain) NSString * hostName;

// Did I find any adware?
@property (assign) bool adwareFound;

// Which tasks had to be terminated.
@property (retain) NSMutableArray * terminatedTasks;

// Keep track of the number of files not in the whitelit.
@property (retain) NSMutableSet * unknownFiles;

// What serious problems were found?
@property (retain) NSMutableSet * seriousProblems;

// Do I have a Time Machine backup?
@property (assign) bool backupExists;

// Keep track of all launchd commands.
@property (retain) NSMutableDictionary * launchdCommands;

// Keep track of all launchd contents.
@property (retain) NSMutableDictionary * launchdContents;

// Ignore known Apple failures.
@property (assign) bool ignoreKnownAppleFailures;

// Check Apple signatures.
@property (assign) bool checkAppleSignatures;

// Hide Apple tasks.
@property (assign) bool hideAppleTasks;

// Do I have unknown files?
@property (readonly) bool haveUnknownFiles;

// Is this version outdated?
@property (assign) bool oldEtreCheckVersion;

// Do I have a verified EtreCheck version?
@property (assign) bool verifiedEtreCheckVersion;

// Return the singeton of shared values.
+ (Model *) model;

// Return true if there are log entries for a process.
- (bool) hasLogEntries: (NSString *) name;

// Collect log entires matching a date.
- (NSString *) logEntriesAround: (NSDate *) date;

// Create a details URL for a query string.
- (NSAttributedString *) getDetailsURLFor: (NSString *) query;

// Is this file an adware file?
- (bool) isAdware: (NSString *) path;

// Is this file an adware extension?
- (bool) isAdwareExtension: (NSString *) name path: (NSString *) path;

// Add files to the whitelist.
- (void) appendToWhitelist: (NSArray *) names;

// Add files to the whitelist prefixes.
- (void) appendToWhitelistPrefixes: (NSArray *) names;

// Add files to the blacklist.
- (void) appendToBlacklist: (NSArray *) names;

// Set the blacklist suffixes.
- (void) appendToBlacklistSuffixes: (NSArray *) names;

// Set the blacklist matches.
- (void) appendToBlacklistMatches: (NSArray *) names;

// Is this file known?
- (bool) isKnownFile: (NSString *) name path: (NSString *) path;

// Is this file in the whitelist?
- (bool) isWhitelistFile: (NSString *) name;

// What kind of adware is this?
- (NSString *) adwareType: (NSString *) path;

// Handle a task that takes too long to complete.
- (void) taskTerminated: (NSString *) program arguments: (NSArray *) args;

@end
