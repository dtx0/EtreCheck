/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kStatusUpdate @"statusupdate"
#define kProgressUpdate @"progressupdate"
#define kCurrentProgress @"currentprogress"
#define kNextProgress @"nextprogress"
#define kFoundApplication @"foundapplication"
#define kShowMachineIcon @"showmachineicon"
#define kCollectionStatus @"collectionstatus"
#define kShowDemonAgent @"showdemonagent"

#define kNotSigned @"notsigned"
#define kSignatureValid @"signaturevalid"
#define kSignatureNotValid @"signataurenotvalid"
#define kExecutableMissing @"executablemissing"
#define kSignatureSkipped @"signatureskipped"

#define kExecutableTimeout @"executabletimeout"

// Assorted utilities.
@interface Utilities : NSObject
  {
  NSFont * myBoldFont;
  NSFont * myItalicFont;
  NSFont * myBoldItalicFont;
  NSFont * myNormalFont;
  NSFont * myLargerFont;
  NSFont * myVeryLargeFont;
  
  NSColor * myGreen;
  NSColor * myBlue;
  NSColor * myRed;
  NSColor * myGray;
  
  NSImage * myUnknownMachineIcon;
  NSImage * myMachineNotFoundIcon;
  NSImage * myGenericApplicationIcon;
  NSImage * myEtreCheckIcon;
  NSImage * myFinderIcon;
  
  NSBundle * myEnglishBundle;
  
  NSMutableDictionary * mySignatureCache;
  }

// Make some handy shared values available to all collectors.
@property (readonly) NSFont * boldFont;
@property (readonly) NSFont * italicFont;
@property (readonly) NSFont * boldItalicFont;
@property (readonly) NSFont * normalFont;
@property (readonly) NSFont * largerFont;
@property (readonly) NSFont * veryLargeFont;

@property (readonly) NSColor * green;
@property (readonly) NSColor * blue;
@property (readonly) NSColor * red;
@property (readonly) NSColor * gray;

@property (readonly) NSImage * unknownMachineIcon;
@property (readonly) NSImage * machineNotFoundIcon;
@property (readonly) NSImage * genericApplicationIcon;
@property (readonly) NSImage * EtreCheckIcon;
@property (readonly) NSImage * FinderIcon;

@property (readonly) NSBundle * EnglishBundle;

@property (readonly) NSMutableDictionary * signatureCache;

// Return the singeton of shared utilities.
+ (Utilities *) shared;

// Execute an external program and return the results.
+ (NSData *) execute: (NSString *) program arguments: (NSArray *) args;

// Execute an external program, return the results, and collect any errors.
+ (NSData *) execute: (NSString *) program
  arguments: (NSArray *) args error: (NSString **) error;

// Execute an external program, with options, return the results, and
// collect any errors.
// Supported options:
//  kExecutableTimeout - timeout for external programs.
+ (NSData *) execute: (NSString *) program
  arguments: (NSArray *) args
  options: (NSDictionary *) options
  error: (NSString **) error;

// Format text into an array of trimmed lines separated by newlines.
+ (NSArray *) formatLines: (NSData *) data;

// Read a property list to an array.
+ (id) readPropertyList: (NSString *) path;
+ (id) readPropertyListData: (NSData *) data;

// Redact any user names in a path.
+ (NSString *) cleanPath: (NSString *) path;

// Format an exectuable array for printing, redacting any user names in
// the path.
+ (NSString *) formatExecutable: (NSArray *) parts;

// Make a file name more presentable.
+ (NSString *) sanitizeFilename: (NSString *) file;

// Uncompress some data.
+ (NSData *) ungzip: (NSData *) gzipData;

// Build a URL.
+ (NSAttributedString *) buildURL: (NSString *) url
  title: (NSString *) title;

// Look for attributes from a file that might depend on the PATH.
+ (NSDictionary *) lookForFileAttributes: (NSString *) path;

// Compare versions.
+ (NSComparisonResult) compareVersion: (NSString *) version1
  withVersion: (NSString *) version2;

// Scan a string from top output.
+ (double) scanTopMemory: (NSScanner *) scanner;

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSString *) serialCode
  language: (NSString *) language type: (NSString *) type;

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSURL *) url;

// Construct an Apple support query URL.
+ (NSString *) AppleSupportSPQueryURL: (NSString *) serialCode
  language: (NSString *) language
  type: (NSString *) type;

// Check the signature of an Apple executable.
+ (NSString *) checkAppleExecutable: (NSString *) path;

// Create a temporary directory.
+ (NSString *) createTemporaryDirectory;

@end
