/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface XMLException : NSException

@end

// Encapsulate each element.
@interface XMLElement : NSObject
  {
  NSString * myName;
  NSMutableDictionary * myAttributes;
  NSMutableString * myContents;
  BOOL myCDATARequired;
  BOOL myParent;
  BOOL myEmpty;
  BOOL mySingleLine;
  BOOL myStartTagEmitted;
  int myIndent;
  }

// The name of the element.
@property (retain) NSString * name;

// The element's attributes.
@property (retain) NSMutableDictionary * attributes;

// The element's (current) contents.
@property (retain) NSMutableString * contents;

// Do the current contents require a CDATA?
@property (assign) BOOL CDATARequired;

// Is this element a parent of another element?
@property (assign) BOOL parent;

// Is the current element empty?
@property (assign) BOOL empty;

// Is the current element a single-line element?
@property (assign) BOOL singleLine;

// Has the begin tag been emitted?
@property (assign) BOOL startTagEmitted;

// This element's indent level.
@property (assign) int indent;

// Constructor with name and indent.
- (instancetype) initWithName: (NSString *) name indent: (int) indent;

@end

@interface XMLBuilder : NSObject
  {
  NSMutableString * myDocument;
  int myIndent;
  BOOL myPretty;
  NSMutableArray * myElements;
  }

// The document content.
@property (retain) NSMutableString * document;

// The XML content.
@property (readonly) NSString * XML;

// The current indent level.
@property (assign) int indent;

// Should the output be pretty?
@property (assign) BOOL pretty;

// The stack of elements.
@property (retain) NSMutableArray * elements;

@end
