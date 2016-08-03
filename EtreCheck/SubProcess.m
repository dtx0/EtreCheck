/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "SubProcess.h"
#import <unistd.h>
#include <sys/select.h>

@implementation SubProcess

@synthesize timedout = myTimedout;
@synthesize timeout = myTimeout;
@synthesize result = myResult;
@synthesize standardOutput = myStandardOutput;
@synthesize standardError = myStandardError;

// Constructor.
- (instancetype) init
  {
  if(self = [super init])
    {
    myTimeout = 30;
    
    myStandardOutput = [NSMutableData new];
    myStandardError = [NSMutableData new];
  
    return self;
    }
    
  return nil;
  }

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
  const char * path = [program fileSystemRepresentation];
  
  NSRange range = NSMakeRange(0, [args count]);
  
  const char ** argv = malloc(sizeof(char *) * (range.length + 2));
 
  NSUInteger i = 0;
  
  argv[i++] = path;
  
  for(NSString * arg in args)
    argv[i++] = [arg UTF8String];
    
  argv[i] = 0;
  
  int outputPipe[2];
  int errorPipe[2];
  
  if(pipe(outputPipe) == -1)
    return NO;

  if(pipe(errorPipe) == -1)
    {
    close(outputPipe[0]);
    close(outputPipe[1]);

    return NO;
    }
    
  pid_t pid = fork();
  
  if(pid == -1)
    {
    close(outputPipe[0]);
    close(outputPipe[1]);

    close(errorPipe[0]);
    close(errorPipe[1]);

    free(argv);
  
    return NO;
    }
  
  // Child.
  if(pid == 0)
    {
    close(outputPipe[0]);
    close(errorPipe[0]);

    // They say that dup2 could be interrupted by a signal, so this must
    // be done in a loop.
    while((dup2(outputPipe[1], STDOUT_FILENO) == -1) && (errno == EINTR))
      {
      }
      
    while((dup2(errorPipe[1], STDERR_FILENO) == -1) && (errno == EINTR))
      {
      }

    close(outputPipe[1]);
    close(errorPipe[1]);

    execv(path, (char * const *)argv);
    
    exit(1);
    }
    
  free(argv);
  
  close(outputPipe[1]);
  close(errorPipe[1]);

  fcntl(outputPipe[0], F_SETFL, O_NONBLOCK);
  fcntl(errorPipe[0], F_SETFL, O_NONBLOCK);

  fd_set fds;
  int nfds;
    
  size_t bufferSize = 65536;
  char * buffer = (char *)malloc(bufferSize);
  
  bool stdoutOpen = YES;
  bool stderrOpen = YES;
  
  while(stdoutOpen || stderrOpen)
    {
    FD_ZERO(& fds);
    
    if(stdoutOpen)
      {
      FD_SET(outputPipe[0], & fds);
      
      nfds = outputPipe[0] + 1;
      }
      
    if(stderrOpen)
      {
      FD_SET(errorPipe[0], & fds);
      
      if(stdoutOpen && (outputPipe[0] > errorPipe[0]))
        nfds = outputPipe[0] + 1;
      else
        nfds = errorPipe[0] + 1;
      }
    
    struct timeval tv;

    tv.tv_sec = myTimeout;
    tv.tv_usec = 0;

    int result = select(nfds, & fds, NULL, NULL, & tv);

    if(result == -1)
      break;
      
    else if(result == 0)
      {
      myTimedout = YES;
      break;
      }
      
    else
      {
      if(FD_ISSET(outputPipe[0], & fds))
        {
        ssize_t amount = read(outputPipe[0], buffer, bufferSize);
        
        if(amount < 1)
          stdoutOpen = NO;
        else
          [myStandardOutput appendBytes: buffer length: amount];
        }
        
      if(FD_ISSET(errorPipe[0], & fds))
        {
        ssize_t amount = read(errorPipe[0], buffer, bufferSize);
        
        if(amount < 1)
          stderrOpen = NO;
        else
          [myStandardError appendBytes: buffer length: amount];
        }
      }
    }
    
  close(outputPipe[0]);
  close(errorPipe[0]);

  free(buffer);
  
  waitpid(pid, & myResult, 0);
    
  return !self.timedout;
  }

@end
