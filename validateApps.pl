#!/usr/bin/env perl

use strict;
use Capture::Tiny ':all';

my @xpc = `find /System -type d -iname "*.xpc" 2> /dev/null`;
my @sysapps = `find /System -type d -iname "*.app" 2> /dev/null`;
my @apps = `find /Applications -type d -iname "*.app" 2> /dev/null`;
my @bin = `find /bin -type f -or -type l 2> /dev/null`;
my @sbin = `find /sbin -type f -or -type l 2> /dev/null`;
my @usrbin = `find /usr/bin -type f -or -type l 2> /dev/null`;
my @usrsbin = `find /usr/sbin -type f -or -type l 2> /dev/null`;
my @libexec = `find /usr/libexec -type f -or -type l 2> /dev/null`;

my $expectedTemplate = 
  "%s: valid on disk\n"
  . "%s: satisfies its Designated Requirement\n"
  . "%s: explicit requirement satisfied\n";

foreach 
  my $bundle 
  (@xpc, @sysapps, @apps, @bin, @sbin, @usrbin, @usrsbin, @libexec)
  {
  chomp $bundle;
        
  my $apple = verify($bundle, 'apple');
  
  if($apple)
    {
    print("$bundle: Apple\n");
    
    next;
    }
    
  my $generic = verify($bundle, 'apple generic');
  
  printf("$bundle: %s\n", $generic ? "Success" : "Failed");
  }
  
sub verify
  {
  my $bundle = shift;
  my $anchor = shift;
  
  my ($stdout, $stderr, $exit) = 
    capture 
      {
      # Don't forget to add --no-strict for 10.9.5 and 10.10 only.
      system(qq{/usr/bin/codesign -vv -R="anchor $anchor" "$bundle"});
      };

  my $data = $stdout . $stderr;

  my $expected = 
    sprintf($expectedTemplate, $bundle, $bundle, $bundle);
    
  return $data eq $expected;
  }
