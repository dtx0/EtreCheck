/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Utilities.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import <CoreServices/CoreServices.h>
#import <Carbon/Carbon.h>

// Assorted utilities.
@implementation Utilities

// Create some dynamic properties for the singleton.
@synthesize boldFont = myBoldFont;
@synthesize italicFont = myItalicFont;
@synthesize boldItalicFont = myBoldItalicFont;
@synthesize normalFont = myNormalFont;
@synthesize largerFont = myLargerFont;
@synthesize veryLargeFont = myVeryLargeFont;

@synthesize green = myGreen;
@synthesize blue = myBlue;
@synthesize red = myRed;
@synthesize gray = myGray;

@synthesize unknownMachineIcon = myUnknownMachineIcon;
@synthesize machineNotFoundIcon = myMachineNotFoundIcon;
@synthesize genericApplicationIcon = myGenericApplicationIcon;
@synthesize EtreCheckIcon = myEtreCheckIcon;
@synthesize FinderIcon = myFinderIcon;

@synthesize EnglishBundle = myEnglishBundle;

// Signature checking is expensive.
@synthesize signatureCache = mySignatureCache;

// Return the singeton of shared values.
+ (Utilities *) shared
  {
  static Utilities * utilities = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      utilities = [Utilities new];
    });
    
  return utilities;
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    [self loadFonts];
    [self loadColours];
    [self loadIcons];
    [self loadEnglishStrings];
    
    mySignatureCache = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [mySignatureCache release];
  [myEnglishBundle release];
  
  [myVeryLargeFont release];
  [myLargerFont release];
  [myNormalFont release];
  [myBoldFont release];
  [myItalicFont release];
  [myBoldItalicFont release];

  [myGreen release];
  [myBlue release];
  [myGray release];
  [myRed release];
  
  [myFinderIcon release];
  [myEtreCheckIcon release];
  [myGenericApplicationIcon release];
  [myUnknownMachineIcon release];
  [myMachineNotFoundIcon release];
  
  return [super dealloc];
  }

// Load fonts.
- (void) loadFonts
  {
  myNormalFont = [[NSFont labelFontOfSize: 12.0] retain];
  myLargerFont = [[NSFont labelFontOfSize: 14.0] retain];
  myVeryLargeFont = [[NSFont labelFontOfSize: 18.0] retain];
  
  myBoldFont =
    [[NSFontManager sharedFontManager]
      convertFont: myNormalFont
      toHaveTrait: NSBoldFontMask];
    
  myItalicFont =
    [[NSFontManager sharedFontManager]
      convertFont: myNormalFont
      toHaveTrait: NSItalicFontMask];

  myBoldItalicFont =
    [NSFont fontWithName: @"Helvetica-BoldOblique" size: 12.0];
    
  [myBoldFont retain];
  [myItalicFont retain];
  [myBoldItalicFont retain];
  }

// Load colours.
- (void) loadColours
  {
  myGreen =
    [NSColor
      colorWithCalibratedRed: 0.2f green: 0.5f blue: 0.2f alpha: 0.0f];
    
  myBlue =
    [NSColor
      colorWithCalibratedRed: 0.0f green: 0.0f blue: 0.6f alpha: 0.0f];

  myGray =
    [NSColor
      colorWithCalibratedRed: 0.4f green: 0.4f blue: 0.4f alpha: 0.0f];

  myRed = [NSColor redColor];
  
  [myGreen retain];
  [myBlue retain];
  [myGray retain];
  [myRed retain];
  }

// Load icons.
- (void) loadIcons
  {
  NSString * resourceDirectory =
    @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/";
    
  myUnknownMachineIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"GenericQuestionMarkIcon.icns"]];

  myMachineNotFoundIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"public.generic-pc.icns"]];

  myGenericApplicationIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"GenericApplicationIcon.icns"]];
  
  myEtreCheckIcon = [NSImage imageNamed: @"AppIcon"];
  
  [myEtreCheckIcon setSize: NSMakeSize(128, 128)];
  
  myFinderIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"FinderIcon.icns"]];
  }

// Load English strings.
- (void) loadEnglishStrings
  {
  NSString * EnglishBundlePath =
    [[NSBundle mainBundle]
      pathForResource: @"Localizable"
      ofType: @"strings"
      inDirectory: nil
      forLocalization: @"en"];


  myEnglishBundle =
    [[NSBundle alloc]
      initWithPath: [EnglishBundlePath stringByDeletingLastPathComponent]];
  }

// Execute an external program and return the results.
+ (NSData *) execute: (NSString *) program arguments: (NSArray *) args
  {
  return [self execute: program arguments: args options: nil error: NULL];
  }

// Execute an external program and return the results.
+ (NSData *) execute: (NSString *) program
  arguments: (NSArray *) args error: (NSString **) error
  {
  return [self execute: program arguments: args options: nil error: error];
  }

// Execute an external program, with options, return the results, and
// collect any errors.
// Supported options:
//  kExecutableTimeout - timeout for external programs.
+ (NSData *) execute: (NSString *) program
  arguments: (NSArray *) args
  options: (NSDictionary *) options
  error: (NSString **) error
  {
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
  
  NSData * result = nil;  
  NSData * errorData = nil;

  @try
    {
    [task launch];
    
    int64_t timeout = 60 * 5 * NSEC_PER_SEC;
    
    NSNumber * timeoutValue = [options objectForKey: kExecutableTimeout];
    
    if(timeoutValue)
      timeout = [timeoutValue unsignedLongLongValue] * NSEC_PER_SEC;
      
    //NSLog(@"Running %@ %@ with timeout %lld", program, args, timeout);
    
    // Timeout after 5 minutes.
    dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, timeout),
      dispatch_get_main_queue(),
      ^{
        if([task isRunning])
          {
          [task terminate];
          
          [[Model model] taskTerminated: program arguments: args];
          }
      });
      
    result =
      [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    
    errorData =
      [[[task standardError] fileHandleForReading] readDataToEndOfFile];

    [task release];
    [errorPipe release];
    [outputPipe release];
    }
  @catch(NSException * exception)
    {
    if(error)
      *error = [exception description];
    }
  @catch(...)
    {
    if(error)
      *error = @"Unknown exception";
    }
    
  if(![result length] && error && [errorData length])
    *error =
      [[[NSString alloc]
        initWithData: errorData encoding: NSUTF8StringEncoding]
        autorelease];
    
  return result;
  }

/* TODO: I could log long-running tasks with this:

  [[NSNotificationCenter defaultCenter]
    postNotificationName: kStatusUpdate object: status];
*/

// Format text into an array of trimmed lines separated by newlines.
+ (NSArray *) formatLines: (NSData *) data
  {
  NSMutableArray * result = [NSMutableArray array];
  
  if(!data)
    return result;
    
  NSString * text =
    [[NSString alloc]
      initWithBytes: [data bytes]
      length: [data length]
      encoding: NSUTF8StringEncoding];
      
  NSArray * lines = [text componentsSeparatedByString: @"\n"];
  
  [text release];
  
  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
    if([trimmedLine isEqualToString: @""])
      continue;
      
    [result addObject: trimmedLine];
    }
    
  return result;
  }

// Read a property list.
+ (id) readPropertyList: (NSString *) path
  {
  NSString * resolvedPath = [path stringByResolvingSymlinksInPath];
  
  return
    [self
      readPropertyListData: [NSData dataWithContentsOfFile: resolvedPath]];
  }
  
// Read a property list.
+ (id) readPropertyListData: (NSData *) data
  {
  if(data)
    {
    NSError * error;
    NSPropertyListFormat format;
    
    return
      [NSPropertyListSerialization
        propertyListWithData: data
        options: NSPropertyListImmutable
        format: & format
        error: & error];
    }
    
  return nil;
  }

// Redact any user names in a path.
+ (NSString *) cleanPath: (NSString *) path
  {
  NSString * abbreviated = [path stringByAbbreviatingWithTildeInPath];
  
  NSString * username = NSUserName();
  NSString * fullname = NSFullUserName();
  
  if([username length] < 4)
    return abbreviated;
    
  NSRange range = [abbreviated rangeOfString: username];
  
  if(range.location == NSNotFound)
    {
    if([fullname length])
      range = [abbreviated rangeOfString: username];
    else
      return abbreviated;
    }
    
  // Now check for a hostname version.
  if(range.location == NSNotFound)
    {
    // See if the full user name is in the computer name.
    NSString * computerName = [[Model model] computerName];
    
    if(!computerName)
      return abbreviated;
      
    BOOL redact = NO;
    
    if([computerName rangeOfString: username].location != NSNotFound)
      redact = YES;
    else if([fullname length])
      if([computerName rangeOfString: fullname].location != NSNotFound)
        redact = YES;
      
    if(redact)
      {
      range = [abbreviated rangeOfString: computerName];

      if(range.location == NSNotFound)
        {
        NSString * hostName = [[Model model] hostName];
        
        if(hostName)
          range = [abbreviated rangeOfString: hostName];
        else
          range.location = NSNotFound;
        }
      }
    }
    
  if(range.location == NSNotFound)
    return abbreviated;
    
  return
    [NSString
      stringWithFormat:
        @"%@%@%@",
        [abbreviated substringToIndex: range.location],
        NSLocalizedString(@"[redacted]", NULL),
        [abbreviated substringFromIndex: range.location + range.length]];
  }

// Format an exectuable array for printing, redacting any user names in
// the path.
+ (NSString *) formatExecutable: (NSArray *) parts
  {
  NSMutableArray * mutableParts = [NSMutableArray arrayWithArray: parts];
  
  // Sanitize the executable.
  NSString * program = [mutableParts firstObject];
  
  if(program)
    {
    [mutableParts removeObjectAtIndex: 0];
    [mutableParts insertObject: [Utilities cleanPath: program] atIndex: 0];
    }
    
  return [mutableParts componentsJoinedByString: @" "];
  }

// Make a file name more presentable.
+ (NSString *) sanitizeFilename: (NSString *) file
  {
  NSString * prettyFile = [self cleanPath: file];
  
  NSString * name = [prettyFile lastPathComponent];
  
  // What are you trying to hide?
  if([name hasPrefix: @"."])
    prettyFile =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"%@ (hidden)", NULL), prettyFile];

  // Silly Apple.
  else if([name hasPrefix: @"com.apple.CSConfigDotMacCert-"])
    prettyFile = [self sanitizeMobileMe: prettyFile];

  // What are you trying to expose?
  else if([name hasPrefix: @"com.facebook.videochat."])
    prettyFile = [self sanitizeFacebook: prettyFile];

  // What are you trying to expose?
  else if([name hasPrefix: @"com.adobe.ARM."])
    prettyFile = @"com.adobe.ARM.[...].plist";

  // I don't want to see it.
  else if([prettyFile length] > 76)
    {
    NSString * extension = [prettyFile pathExtension];
    
    prettyFile =
      [NSString
        stringWithFormat:
          @"%@...%@", [prettyFile substringToIndex: 40], extension];
    }
    
  return prettyFile;
  }

// Apple used to put the user's name into a file name.
+ (NSString *) sanitizeMobileMe: (NSString *) file
  {
  NSScanner * scanner = [NSScanner scannerWithString: file];

  BOOL found =
    [scanner
      scanString: @"com.apple.CSConfigDotMacCert-" intoString: NULL];

  if(!found)
    return file;
    
  found = [scanner scanUpToString: @"@" intoString: NULL];

  if(!found)
    return file;
    
  NSString * domain = nil;
  
  found = [scanner scanUpToString: @".com-" intoString: & domain];

  if(!found)
    return file;

  found = [scanner scanString: @".com-" intoString: NULL];

  if(!found)
    return file;
    
  NSString * suffix = nil;

  found = [scanner scanUpToString: @"\n" intoString: & suffix];

  if(!found)
    return file;
    
  return
    [NSString
      stringWithFormat:
        @"com.apple.CSConfigDotMacCert-[...]%@.com-%@", domain, suffix];
  }

/* Facebook puts the users name in a filename too. */
+ (NSString *) sanitizeFacebook: (NSString *) file
  {
  NSScanner * scanner = [NSScanner scannerWithString: file];

  BOOL found =
    [scanner
      scanString: @"com.facebook.videochat." intoString: NULL];

  if(!found)
    return file;
    
  [scanner scanUpToString: @".plist" intoString: NULL];

  return
    NSLocalizedString(@"com.facebook.videochat.[redacted].plist", NULL);
  }

// Uncompress some data.
+ (NSData *) ungzip: (NSData *) gzipData
  {
  // Create pipes for handling communication.
  NSPipe * inputPipe = [NSPipe new];
  NSPipe * outputPipe = [NSPipe new];
  
  // Create the task itself.
  NSTask * task = [NSTask new];
  
  // Send all task output to the pipe.
  [task setStandardInput: inputPipe];
  [task setStandardOutput: outputPipe];
  
  [task setLaunchPath: @"/usr/bin/gunzip"];

  [task setCurrentDirectoryPath: @"/"];
  
  NSData * result = nil;
  
  @try
    {
    [task launch];
    
    dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^{
        [[[task standardInput] fileHandleForWriting] writeData: gzipData];
        [[[task standardInput] fileHandleForWriting] closeFile];
      });
    
    result =
      [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    }
  @catch(NSException * exception)
    {
    }
  @catch(...)
    {
    }
  @finally
    {
    [task release];
    [outputPipe release];
    [inputPipe release];
    }
    
  return result;
  }

// Build a URL.
+ (NSAttributedString *) buildURL: (NSString *) url
  title: (NSString *) title
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString
    appendString: title
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Look for attributes from a file that might depend on the PATH.
+ (NSDictionary *) lookForFileAttributes: (NSString *) path
  {
  NSDictionary * attributes =
    [[NSFileManager defaultManager]
      attributesOfItemAtPath: path error: NULL];
    
  if(attributes)
    return attributes;
    
  NSDictionary * environment = [[NSProcessInfo processInfo] environment];
  
  NSString * PATH = [environment objectForKey: @"PATH"];
  
  NSArray * pathParts = [PATH componentsSeparatedByString: @":"];
  
  for(NSString * dir in pathParts)
    {
    NSString * searchPath = [dir stringByAppendingPathComponent: path];
    
    attributes =
      [[NSFileManager defaultManager]
        attributesOfItemAtPath: searchPath error: NULL];
    
    if(attributes)
      return attributes;
    }
    
  return nil;
  }

// Compare versions.
+ (NSComparisonResult) compareVersion: (NSString *) version1
  withVersion: (NSString *) version2
  {
  NSArray * version1Parts = [version1 componentsSeparatedByString: @"."];
  NSArray * version2Parts = [version2 componentsSeparatedByString: @"."];
  
  int index = 0;
  
  while(YES)
    {
    if(index >= [version1Parts count])
      {
      if(index >= [version2Parts count])
        break;
        
      else
        return NSOrderedAscending;
      }
      
    if(index >= [version2Parts count])
      return NSOrderedDescending;
    
    NSString * segment1 = [version1Parts objectAtIndex: index];
    NSString * segment2 = [version2Parts objectAtIndex: index];
    
    NSComparisonResult result = [segment1 compare: segment2];
    
    if(result != NSOrderedSame)
      return result;
      
    ++index;
    }
    
  return NSOrderedSame;
  }

// Scan a string from top output.
+ (double) scanTopMemory: (NSScanner *) scanner
  {
  double memValue;
  
  bool found = [scanner scanDouble: & memValue];

  if(!found)
    return 0;

  NSString * units;
  
  found =
    [scanner
      scanCharactersFromSet:
        [NSCharacterSet characterSetWithCharactersInString: @"BKMGT"]
      intoString: & units];

  if(found)
    {
    if([units isEqualToString: @"K"])
      memValue *= 1024;
    else if([units isEqualToString: @"M"])
      memValue *= 1024 * 1024;
    else if([units isEqualToString: @"G"])
      memValue *= 1024 * 1024 * 1024;
    else if([units isEqualToString: @"T"])
      memValue *= 1024 * 1024 * 1024 * 1024;
    }
    
  return memValue;
  }

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSString *) serialCode
  language: (NSString *) language type: (NSString *) type
  {
  NSString * marketingName = @"";
  
  if([serialCode length])
    {
    NSURL * url =
      [NSURL
        URLWithString:
          [Utilities
            AppleSupportSPQueryURL: serialCode
            language: language
            type: type]];
    
    marketingName = [Utilities askAppleForMarketingName: url];
    }
    
  return marketingName;
  }

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSURL *) url
  {
  NSString * marketingName = @"";
  
  if(url)
    {
    NSError * error = nil;
    
    NSXMLDocument * document =
      [[NSXMLDocument alloc]
        initWithContentsOfURL: url options: 0 error: & error];
    
    if(document)
      {
      NSArray * nodes =
        [document nodesForXPath: @"root/configCode" error: & error];

      if(nodes && [nodes count])
        {
        NSXMLNode * configCodeNode = [nodes objectAtIndex: 0];
        
        // Apple has non-breaking spaces in the results, especially in
        // French but sometimes in English too.
        NSString * nbsp = @"\u00A0";
        
        marketingName =
          [[configCodeNode stringValue]
            stringByReplacingOccurrencesOfString: nbsp withString: @" "];
        }
      
      [document release];
      }
    }
    
  return marketingName;
  }

// Construct an Apple support query URL.
+ (NSString *) AppleSupportSPQueryURL: (NSString *) serialCode
  language: (NSString *) language
  type: (NSString *) type
  {
  return
    [NSString
      stringWithFormat:
        @"http://support-sp.apple.com/sp/%@&cc=%@&lang=%@",
        type, serialCode, language];
  }

// Verify the signature of an Apple executable.
+ (NSString *) checkAppleExecutable: (NSString *) path
  {
  if(![path length])
    return kExecutableMissing;
    
  if(![[Model model] checkAppleSignatures])
    return kSignatureValid;
    
  NSString * result =
    [[[Utilities shared] signatureCache] objectForKey: path];
  
  if(result)
    return result;
    
  // If I am hiding Apple tasks, then skip Xcode.
  if([[Model model] hideAppleTasks])
    if([[path lastPathComponent] isEqualToString: @"Xcode"])
      return kSignatureSkipped;

  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"-vv"];
  [args addObject: @"-R=anchor apple generic"];
  
  switch([[Model model] majorOSVersion])
    {
    // What a mess.
    case kMavericks:
      if([[Model model] minorOSVersion] < 5)
        break;
    case kYosemite:
      [args addObject: @"--no-strict"];
      break;
    }
    
  NSMutableDictionary * options = [NSMutableDictionary dictionary];
  
  [args addObject: path];

  // Give Xcode a 10-minute timeout.
  if([[path lastPathComponent] isEqualToString: @"Xcode"])
    [options
      setObject: [NSNumber numberWithInt: 60 * 10]
      forKey: kExecutableTimeout];
    
  NSString * output = nil;
  
  [Utilities
    execute: @"/usr/bin/codesign"
    arguments: args
    options: options
    error: & output];
  
  //NSLog(@"/usr/bin/codesign %@\n%@", args, output);
  result = [Utilities parseSignature: output forPath: path];
      
  [[[Utilities shared] signatureCache] setObject: result forKey: path];
  
  return result;
  }

// Parse a signature.
+ (NSString *) parseSignature: (NSString *) output
  forPath: (NSString *) path
  {
  NSString * result = kSignatureNotValid;
  
  if([output length])
    {
    NSString * expectedOutput =
      [NSString
        stringWithFormat:
          @"%@: valid on disk\n"
          "%@: satisfies its Designated Requirement\n"
          "%@: explicit requirement satisfied\n",
          path,
          path,
          path];
      
    if([output isEqualToString: expectedOutput])
      result = kSignatureValid;
      
    else
      {
      expectedOutput =
        [NSString
          stringWithFormat:
            @"%@: code object is not signed", path];

      // The wording has changed slightly on this.
      if([output hasPrefix: expectedOutput])
        result = kNotSigned;
      
      else
        {
        expectedOutput =
          [NSString
            stringWithFormat: @"%@: No such file or directory\n", path];

        if([output isEqualToString: expectedOutput])
          result = kExecutableMissing;
        }
      }
    }
    
  return result;
  }

// Create a temporary directory.
+ (NSString *) createTemporaryDirectory
  {
  NSString * template =
    [NSTemporaryDirectory()
      stringByAppendingPathComponent: @"XXXXXXXXXXXX"];
  
  char * buffer = strdup([template fileSystemRepresentation]);
  
  mkdtemp(buffer);
  
  NSString * temporaryDirectory =
    [[NSFileManager defaultManager]
      stringWithFileSystemRepresentation: buffer length: strlen(buffer)];
  
  free(buffer);
  
  return temporaryDirectory;
  }

// Delete an array of files.
+ (void) removeFiles: (NSArray *) paths
  completionHandler:
    (void (^)(NSDictionary * newURLs, NSError *error)) handler
  {
  __block NSMutableSet * urlsToRemove = [[NSMutableSet alloc] init];
  
  NSMutableArray * urls = [NSMutableArray array];
  
  for(NSString * path in paths)
    {
    NSURL * url = [NSURL fileURLWithPath: path];
    
    [urls addObject: url];
    [urlsToRemove addObject: url];
    }
    
  [[NSWorkspace sharedWorkspace]
    recycleURLs: urls
    completionHandler:
      ^(NSDictionary * newURLs, NSError * error)
        {
        for(NSURL * url in newURLs)
          [urlsToRemove removeObject: url];
          
        if([urlsToRemove count] > 0)
          {
          NSArray * urlsRemovedByAdmin =
            [Utilities removeAdminFiles: urlsToRemove];
          
          NSMutableDictionary * urls =
            [NSMutableDictionary dictionaryWithDictionary: newURLs];
            
          for(NSURL * url in urlsRemovedByAdmin)
            [urls setObject: url forKey: url];
            
          handler(urls, error);
          
          [urlsToRemove release];
          }
        }];
  }

// Remove files with administrator privileges.
+ (NSArray *) removeAdminFiles: (NSMutableSet *) urlsToRemove
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Password required!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  [message appendString: NSLocalizedString(@"passwordrequired", NULL)];
  
  for(NSURL * url in urlsToRemove)
    [message appendFormat: @"- %@\n", [url path]];
    
  [message appendString: NSLocalizedString(@"continuewithpassword", NULL)];

  [alert setInformativeText: message];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Yes", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"No", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  if(result == NSAlertFirstButtonReturn)
    return [Utilities performAdminDelete: urlsToRemove];
    
  return [NSArray array];
  }

// Perform a deletion of files with administrator privileges.
+ (NSArray *) performAdminDelete: (NSMutableSet *) urlsToRemove
  {
  NSMutableString * source = [NSMutableString string];
  
  [source appendString: @"set posixFiles to {"];
  
  int i = 0;
  
  for(NSURL * url in urlsToRemove)
    {
    if(i)
      [source appendString: @","];
      
    [source
      appendString:
        [NSString
          stringWithFormat:
            @"POSIX file \"%@\"", [url path]]];
      
    ++i;
    }

  [source appendString: @"}\n"];

  [source appendString: @"tell application \"Finder\"\n"];
  [source appendString: @"activate\n"];
  [source appendString: @"move posixFiles to the trash\n"];
  [source appendString: @"end tell\n"];

  NSAppleScript * scriptObject =
    [[NSAppleScript alloc] initWithSource: source];

  NSDictionary * errorDict;
  
  NSAppleEventDescriptor * returnDescriptor =
    [scriptObject executeAndReturnError: & errorDict];
    
  [scriptObject release];

  if(returnDescriptor != NULL)
    // Successful execution
    if(kAENullEvent != [returnDescriptor descriptorType])
      {
      NSMutableArray * urlsDeleted = [NSMutableArray array];
  
      for(NSURL * url in urlsToRemove)
        if(![[NSFileManager defaultManager] fileExistsAtPath: [url path]])
          [urlsDeleted addObject: url];
        
      return urlsDeleted;
      }
    
  return [NSArray array];
  }

// Restart the machine.
+ (BOOL) restart
  {
  AEAddressDesc targetDesc;
  
  static const ProcessSerialNumber kPSNOfSystemProcess =
    { 0, kSystemProcess };
    
  AppleEvent eventReply = {typeNull, NULL};
  AppleEvent appleEventToSend = {typeNull, NULL};

  OSStatus error =
    AECreateDesc(
      typeProcessSerialNumber,
      & kPSNOfSystemProcess,
      sizeof(kPSNOfSystemProcess),
      & targetDesc);

  if(error != noErr)
    return NO;

  error =
    AECreateAppleEvent(
      kCoreEventClass,
      kAERestart,
      & targetDesc,
      kAutoGenerateReturnID,
      kAnyTransactionID,
      & appleEventToSend);

  AEDisposeDesc(& targetDesc);
  
  if(error != noErr)
    return NO;

  error =
    AESend(
      & appleEventToSend,
      & eventReply,
      kAENoReply,
      kAENormalPriority,
      kAEDefaultTimeout,
      NULL,
      NULL);

  AEDisposeDesc(& appleEventToSend);
  
  if(error != noErr)
    return NO;

  AEDisposeDesc(& eventReply);

  return YES;
  }

// Tell the user that EtreCheck won't delete files without a backup.
+ (void) reportNoBackup
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"No Time Machine backup!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"notimemachinebackup", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

@end
