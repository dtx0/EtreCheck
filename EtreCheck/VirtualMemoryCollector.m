/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "VirtualMemoryCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"

#define kTotalRAM @"totalram"
#define kSwapUsed @"swapused"
#define kFreeRAM @"freeram"
#define kUsedRAM @"usedram"
#define kFileCache @"filecache"

// Collect virtual memory information.
@implementation VirtualMemoryCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"vm";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);

    formatter = [[ByteCountFormatter alloc] init];

    formatter.k1000 = 1024.0;
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [formatter release];
    
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking virtual memory information", NULL)];

  NSDictionary * vminfo = [self collectVirtualMemoryInformation];
    
  [self.result appendAttributedString: [self buildTitle]];

  [self printFreeVM: vminfo];
  [self printUsedVM: vminfo];
  [self printSwapVM: vminfo];
  
  [self.result appendCR];

  dispatch_semaphore_signal(self.complete);
  }

// Collect virtual memory information.
- (NSDictionary *) collectVirtualMemoryInformation
  {
  NSMutableDictionary * vminfo = [NSMutableDictionary dictionary];
  
  [self collectvm_stat: vminfo];
  [self collectsysctl: vminfo];
  
  NSInteger totalRAM = [[vminfo objectForKey: kTotalRAM] integerValue];
  NSInteger freeRAM = [[vminfo objectForKey: kFreeRAM] integerValue];

  [vminfo
    setObject: [NSNumber numberWithInteger: totalRAM - freeRAM]
    forKey: kUsedRAM];
  
  return vminfo;
  }

// Collect information from vm_stat.
- (void) collectvm_stat: (NSMutableDictionary *) vminfo
  {
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/vm_stat" arguments: nil])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    NSMutableDictionary * vm_stats = [NSMutableDictionary dictionary];
    
    for(NSString * line in lines)
      {
      NSArray * parts = [line componentsSeparatedByString: @":"];
      
      if([parts count] > 1)
        {
        NSString * key = [parts objectAtIndex: 0];

        NSString * value = [parts objectAtIndex: 1];
          
        [vm_stats setObject: value forKey: key];
        }
      }

    // Format the values into something I can use.
    [vminfo addEntriesFromDictionary: [self formatVMStats: vm_stats]];
    }
    
  [subProcess release];
  }

// Collect information from sysctl.
- (void) collectsysctl: (NSMutableDictionary *) vminfo
  {
  NSArray * args = @[@"-a"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/sysctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      if([line hasPrefix: @"vm.swapusage:"])
        // Format the values into something I can use.
        [vminfo addEntriesFromDictionary: [self formatSysctl: line]];
      
      else if([line hasPrefix: @"hw.memsize:"])
        // Format the values into something I can use.
        [vminfo addEntriesFromDictionary: [self formatSysctl: line]];
    }
    
  [subProcess release];
  }

// Print the free VM value.
- (void) printFreeVM: (NSDictionary *) vminfo
  {
  [self printVM: vminfo forKey: kFreeRAM indent: @"    "];
  }

// Print the used VM value.
- (void) printUsedVM: (NSDictionary *) vminfo
  {
  NSString * extra = [self formatUsedVM: vminfo];
  
  [self printVM: vminfo forKey: kUsedRAM indent: @"    " extra: extra];
  }

// Print the swap VM value.
- (void) printSwapVM: (NSDictionary *) vminfo
  {
  NSUInteger GB = 1024 * 1024 * 1024;

  if(pageouts > (GB * 1))
    [self
      printVM: vminfo
      forKey: kSwapUsed
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }
      indent: @"    "];
  else
    [self printVM: vminfo forKey: kSwapUsed indent: @"    "];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key indent: (NSString *) indent
  {
  [self printVM: vminfo forKey: key indent: indent extra: @""];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key
  indent: (NSString *) indent
  extra: (NSString *) extra
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"%@%@    %@ %@\n",
          indent,
          [formatter stringFromByteCount: (unsigned long long)value],
          NSLocalizedString(key, NULL),
          extra]];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key
  attributes: (NSDictionary *) attributes
  indent: (NSString *) indent
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"%@%@    %@\n",
          indent,
          [formatter stringFromByteCount: (unsigned long long)value],
          NSLocalizedString(key, NULL)]
    attributes: attributes];
  }

// Format used memory.
- (NSString *) formatUsedVM: (NSDictionary *) vminfo
  {
  double cached = [[vminfo objectForKey: kFileCache] doubleValue];
 
  NSMutableString * extra = [NSMutableString string];
  
  if(cached > 0)
    {
    [extra appendString: @"("];
    
    [extra
      appendFormat:
        NSLocalizedString(kFileCache, NULL),
        [formatter stringFromByteCount: (unsigned long long)cached]];
    
    [extra appendString: @")"];
    }
    
  return extra;
  }

// Format output from vm_stats into something useable.
- (NSDictionary *) formatVMStats: (NSDictionary *) vm_stats
  {
  NSString * statisticsValue =
    [vm_stats objectForKey: @"Mach Virtual Memory Statistics"];
  NSString * cachedValue = [vm_stats objectForKey: @"File-backed pages"];
  NSString * freeValue =
    [vm_stats objectForKey: @"Pages free"];
  NSString * speculativeValue =
    [vm_stats objectForKey: @"Pages speculative"];

  double pageSize = [self parsePageSize: statisticsValue];
  
  double cached = [cachedValue doubleValue] * pageSize;
  double free = [freeValue doubleValue] * pageSize;
  double speculative = [speculativeValue doubleValue] * pageSize;
  
  return
    @{
      kFileCache : [NSNumber numberWithDouble: cached],
      kFreeRAM : [NSNumber numberWithDouble: free + speculative]
    };
  }
  
// Parse a VM page size.
- (double) parsePageSize: (NSString *) statisticsValue
  {
  NSScanner * scanner = [NSScanner scannerWithString: statisticsValue];

  double size;

  if([scanner scanDouble: & size])
    return size;

  return 4096;
  }

// Format output from sysctl into something useable.
- (NSDictionary *) formatSysctl: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  [scanner scanString: @"vm.swapusage: total =" intoString: NULL];

  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: NULL];
  
  [scanner scanString: @"used =" intoString: NULL];

  double used = [Utilities scanTopMemory: scanner];
  
  NSInteger total = 0;
  
  if([scanner scanUpToString: @"hw.memsize:" intoString: NULL])
    if([scanner scanString: @"hw.memsize:" intoString: NULL])
      [scanner scanInteger: & total];
    
  return
    @{
      kSwapUsed : [NSNumber numberWithDouble: used],
      kTotalRAM : [NSNumber numberWithDouble: (double)total]
    };
  }

@end
