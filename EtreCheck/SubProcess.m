/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "SubProcess.h"
#import "DispatchSource.h"

@implementation SubProcess

@synthesize timedout = myTimedout;
@synthesize result = myResult;
@synthesize standardOutput = myStandardOutput;
@synthesize standardError = myStandardError;

// Deallocate.
- (void) dealloc
  {
  [myStandardOutput release];
  [myStandardError release];
  
  [super dealloc];
  }

// Execute an external program and return the results.
- (BOOL) execute: (NSString *) program arguments: (NSArray *) args
  {
  return [self execute: program arguments: args options: nil];
  }

// Execute an external program, with options, return the results, and
// collect any errors.
// Supported options:
//  kExecutableTimeout - timeout for external programs.
- (BOOL) execute: (NSString *) program
  arguments: (NSArray *) args
  options: (NSDictionary *) options
  {
  NSLog(@"running: %@ %@", program, args);
  
  myStandardOutput = [[NSMutableData alloc] init];
  myStandardError = [[NSMutableData alloc] init];
  
  // Create pipes for handling communication.
  NSPipe * outputPipe = [NSPipe new];
  NSPipe * errorPipe = [NSPipe new];
  
  // Create the task itself.
  NSTask * task = [NSTask new];
  
  // Send all task output to the pipe.
  [task setStandardOutput: outputPipe];
  [task setStandardError: errorPipe];
  
  [task setLaunchPath: program];

  if(args)
    [task setArguments: args];
  
  [task setCurrentDirectoryPath: @"/"];
    
  dispatch_group_t group = dispatch_group_create();

  // Run the task.
  [task launch];
    
  dispatch_group_enter(group);

  fcntl(
    [[[task standardOutput] fileHandleForReading] fileDescriptor],
    F_SETFL,
    O_NONBLOCK);
  
  DispatchSource * output = [[DispatchSource alloc] init];
  
  output.type = DISPATCH_SOURCE_TYPE_READ;
  output.handle =
    [[[task standardOutput] fileHandleForReading] fileDescriptor];
  output.eventHandler =
    ^{
      int fd = (int)dispatch_source_get_handle(output.source);
      size_t estimated = dispatch_source_get_data(output.source) + 1;
      
      // Read the data into a text buffer.
      char * buffer = (char *)malloc(estimated);
      
      if(buffer)
        {
        ssize_t actual = read(fd, buffer, (estimated));
        
        NSLog(@"read %zd bytes on stdout", actual);
        
        if(!actual)
          dispatch_source_cancel(output.source);
        else
          [self.standardOutput appendBytes: buffer length: actual];
 
        // Release the buffer when done.
        free(buffer);
        }
    };
  output.cancelHandler =
    ^{
      close((int)dispatch_source_get_handle(output.source));
      
      dispatch_group_leave(group);
    };

  dispatch_group_enter(group);

  fcntl(
    [[[task standardError] fileHandleForReading] fileDescriptor],
    F_SETFL,
    O_NONBLOCK);

  DispatchSource * error = [[DispatchSource alloc] init];
  
  error.type = DISPATCH_SOURCE_TYPE_READ;
  error.handle =
    [[[task standardError] fileHandleForReading] fileDescriptor];
  error.eventHandler =
    ^{
      int fd = (int)dispatch_source_get_handle(error.source);
      size_t estimated = dispatch_source_get_data(error.source) + 1;
      
      // Read the data into a text buffer.
      char * buffer = (char *)malloc(estimated);
      
      if(buffer)
        {
        ssize_t actual = read(fd, buffer, (estimated));
        
        NSLog(@"read %zd bytes on stderr", actual);
        
        if(!actual)
          dispatch_source_cancel(error.source);
        else
          [self.standardError appendBytes: buffer length: actual];
 
        // Release the buffer when done.
        free(buffer);
        }
    };
  error.cancelHandler =
    ^{
      close((int)dispatch_source_get_handle(error.source));

      dispatch_group_leave(group);
    };

  DispatchSource * timer = [[DispatchSource alloc] init];
  
  timer.type = DISPATCH_SOURCE_TYPE_TIMER;
  
  int64_t timeout = 60 * 5 * NSEC_PER_SEC;
  
  NSNumber * timeoutValue = [options objectForKey: kExecutableTimeout];
  
  if(timeoutValue)
    timeout = [timeoutValue unsignedLongLongValue] * NSEC_PER_SEC;

  timer.startTime = timeout;
  timer.intervalTime = timeout;
  timer.leewayTime = 1ull * NSEC_PER_SEC;
  timer.eventHandler =
    ^{
      NSLog(@"timer fired");
      if([task isRunning])
        {
        [task terminate];
        
        self.timedout = YES;
        }
    };

  dispatch_group_enter(group);
  
  DispatchSource * proc = [[DispatchSource alloc] init];
  
  proc.type = DISPATCH_SOURCE_TYPE_PROC;
  proc.mask = DISPATCH_PROC_EXIT;
  proc.handle = [task processIdentifier];
  proc.eventHandler =
    ^{
      //NSLog(@"process ended");
      dispatch_source_cancel(timer.source);
      
      dispatch_group_leave(group);
    };

  [proc enable];
  [output enable];
  [error enable];
  [timer enable];

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  
  dispatch_release(group);
  
  if(!self.timedout)
    {
    if([task isRunning])
      myResult = 0;
    else
      myResult = [task terminationStatus];
    }
    
  [proc stop];
  [output stop];
  [error stop];
  [timer stop];
  
  [task release];
  [errorPipe release];
  [outputPipe release];

  NSLog(@"done running: %@ %@", program, args);
  
  return !self.timedout;
  }

// Spawn an external program and ignore the results.
- (void) spawn: (NSString *) program arguments: (NSArray *) args
  {
  [self spawn: program arguments: args options: nil];
  }

// Spawn an external program, with options and ignore the results.
// Supported options:
//  kExecutableTimeout - timeout for external programs.
- (void) spawn: (NSString *) program
  arguments: (NSArray *) args options: (NSDictionary *) options
  {
  NSLog(@"spawning: %@ %@", program, args);
  
  // Create the task.
  NSTask * task = [NSTask new];
  
  [task setLaunchPath: @"/bin/sh"];
  
  NSString * command = program;
  
  if(args)
    command =
      [NSString stringWithFormat: @"%@ %@",
        program, [args componentsJoinedByString: @" "]];
  
  NSArray * taskArguments =
    @[
      @"-c",
      command,
      @"&"
    ];
    
  [task setArguments: taskArguments];
  
  [task setCurrentDirectoryPath: @"/"];
    
  dispatch_group_t group = dispatch_group_create();

  // Run the task.
  [task launch];
    
  dispatch_group_enter(group);

  DispatchSource * timer = [[DispatchSource alloc] init];
  
  timer.type = DISPATCH_SOURCE_TYPE_TIMER;
  
  int64_t timeout = 60 * 5 * NSEC_PER_SEC;
  
  NSNumber * timeoutValue = [options objectForKey: kExecutableTimeout];
  
  if(timeoutValue)
    timeout = [timeoutValue unsignedLongLongValue] * NSEC_PER_SEC;

  timer.startTime = timeout;
  timer.intervalTime = timeout;
  timer.leewayTime = 1ull * NSEC_PER_SEC;
  timer.eventHandler =
    ^{
      NSLog(@"timer fired");
      if([task isRunning])
        {
        [task terminate];
        
        self.timedout = YES;
        }
    };

  dispatch_group_enter(group);
  
  DispatchSource * proc = [[DispatchSource alloc] init];
  
  proc.type = DISPATCH_SOURCE_TYPE_PROC;
  proc.mask = DISPATCH_PROC_EXIT;
  proc.handle = [task processIdentifier];
  proc.eventHandler =
    ^{
      //NSLog(@"process ended");
      dispatch_source_cancel(timer.source);
      
      dispatch_group_leave(group);
    };

  [proc enable];
  [timer enable];

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  
  dispatch_release(group);
  
  if(!self.timedout)
    {
    if([task isRunning])
      myResult = 0;
    else
      myResult = [task terminationStatus];
    }
    
  [proc stop];
  [timer stop];
  
  [task release];

  NSLog(@"done spawn: %@ %@", program, args);
  }

@end
