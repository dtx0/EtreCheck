/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kExecutableTimeout @"executabletimeout"

@interface SubProcess : NSObject
  {
  BOOL myTimedout;
  int myResult;
  NSMutableData * myStandardOutput;
  NSMutableData * myStandardError;
  }

@property (assign) BOOL timedout;
@property (readonly) int result;
@property (readonly) NSMutableData * standardOutput;
@property (readonly) NSMutableData * standardError;

// Execute an external program and return the results.
// If this returns NO, internal data structures are undefined.
- (BOOL) execute: (NSString *) program arguments: (NSArray *) args;

// Execute an external program with options.
// Supported options:
//  kExecutableTimeout - timeout for external programs.
// If this returns NO, internal data structures are undefined.
- (BOOL) execute: (NSString *) program
  arguments: (NSArray *) args options: (NSDictionary *) options;

// Execute an external program and ignore results.
- (void) spawn: (NSString *) program arguments: (NSArray *) args;

// Execute an external program with options and ignore results.
// Supported options:
//  kExecutableTimeout - timeout for external programs.
- (void) spawn: (NSString *) program
  arguments: (NSArray *) args options: (NSDictionary *) options;

@end
