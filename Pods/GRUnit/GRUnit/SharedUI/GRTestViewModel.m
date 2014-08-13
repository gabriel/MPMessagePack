//
//  GRTestViewModel.m
//  GRUnit
//
//  Created by Gabriel Handford on 1/17/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

//! @cond DEV

#import "GRTestViewModel.h"
#import "GRTesting.h"

@interface GRTestViewModel ()
@property NSString *identifier;
@property GRTestSuite *suite;
@property GRTestNode *root;
@property GRTestRunner *runner;
@property NSMutableDictionary *map; // id<GRTest>#identifier -> GRTestNode
@property NSMutableDictionary *defaults;
@end

@implementation GRTestViewModel

- (id)initWithIdentifier:(NSString *)identifier suite:(GRTestSuite *)suite {
	if ((self = [super init])) {		
    _identifier = identifier;
		_suite = suite;				
		_map = [NSMutableDictionary dictionary];
		_root = [[GRTestNode alloc] initWithTest:_suite children:[_suite children] source:self];
	}
	return self;
}

- (void)dealloc {
	// Clear delegates
	for(NSString *identifier in _map) 
		[_map[identifier] setDelegate:nil];
	
  [_runner cancel];
  _runner.delegate = nil;
}

- (NSString *)name {
	return [_root name];
}

- (NSString *)statusString:(NSString *)prefix {
	NSInteger totalRunCount = _suite.stats.succeedCount + _suite.stats.failureCount;
	NSString *statusInterval = [NSString stringWithFormat:@"%@ %0.3fs (%0.3fs in test time)", (self.isRunning ? @"Running" : @"Took"), _runner.interval, [_suite interval]];
	return [NSString stringWithFormat:@"%@%@ %@/%@ (%@ failures)", prefix, statusInterval,
					@([_suite stats].succeedCount), @(totalRunCount), @([_suite stats].failureCount)];
}

- (void)registerNode:(GRTestNode *)node {
	_map[node.identifier] = node;
	node.delegate = self;
}

- (GRTestNode *)findTestNodeForTest:(id<GRTest>)test {
	return _map[[test identifier]];
}

- (GRTestNode *)findFailure {
	return [self findFailureFromNode:_root];
}

- (GRTestNode *)findFailureFromNode:(GRTestNode *)node {
	if (node.failed && [node.test exception]) return node;
	for(GRTestNode *childNode in node.filteredChildren) {
		GRTestNode *foundNode = [self findFailureFromNode:childNode];
		if (foundNode) return foundNode;
	}
	return nil;
}

- (NSInteger)numberOfGroups {
	return [[_root filteredChildren] count];
}

- (NSInteger)numberOfTestsInGroup:(NSInteger)group {
	NSArray *children = [_root filteredChildren];
	if ([children count] == 0) return 0;
	GRTestNode *groupNode = children[group];
	return [[groupNode filteredChildren] count];
}

- (NSIndexPath *)indexPathToTest:(id<GRTest>)test {
	NSInteger section = 0;
	for(GRTestNode *node in [_root filteredChildren]) {
		NSInteger row = 0;		
		if ([node.test isEqual:test]) {
			NSUInteger pathIndexes[] = {section,row};
			return [NSIndexPath indexPathWithIndexes:pathIndexes length:2]; // Not user row:section: for compatibility with MacOSX
		}
		for(GRTestNode *childNode in [node filteredChildren]) {
			if ([childNode.test isEqual:test]) {
				NSUInteger pathIndexes[] = {section,row};
				return [NSIndexPath indexPathWithIndexes:pathIndexes length:2];
			}
			row++;
		}
		section++;
	}
	return nil;
}

- (void)testNodeDidChange:(GRTestNode *)node { }

- (NSString *)_defaultsPath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  if ([paths count] == 0) return nil;
  NSString *identifier = _identifier;
  if (!identifier) identifier = @"Tests";
  return [paths[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"GRUnit-%@.tests", identifier]];
}

- (void)_updateTestNodeWithDefaults:(GRTestNode *)node {
  id<GRTest> test = node.test;
  id<GRTest> testDefault = _defaults[test.identifier];
  if (testDefault) {
    if (testDefault.status == GRTestStatusErrored) {
      test.status = testDefault.status;
      test.interval = testDefault.interval;
    }
    #if !TARGET_OS_IPHONE // Don't use hidden state for iPhone
    if ([test isKindOfClass:[GRTest class]]) 
      [test setHidden:testDefault.hidden];
    #endif
  }
  for(GRTestNode *childNode in [node filteredChildren])
    [self _updateTestNodeWithDefaults:childNode];
}

- (void)_saveTestNodeToDefaults:(GRTestNode *)node {
  _defaults[node.test.identifier] = node.test;
  for(GRTestNode *childNode in [node filteredChildren])
    [self _saveTestNodeToDefaults:childNode];
}

- (void)loadDefaults {  
  if (!_defaults) {
    NSString *path = [self _defaultsPath];
    if (path) _defaults = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
  }
  if (!_defaults) _defaults = [NSMutableDictionary dictionary];    
  [self _updateTestNodeWithDefaults:_root];
}

- (void)saveDefaults {
  NSString *path = [self _defaultsPath];
  if (!path || !_defaults) return;
  
  [self _saveTestNodeToDefaults:_root];
  [NSKeyedArchiver archiveRootObject:_defaults toFile:path];
}

- (void)cancel {	
	[_runner cancel];
}

- (void)run:(id<GRTestRunnerDelegate>)delegate inParallel:(BOOL)inParallel {
  // Reset (non-disabled) tests so we don't clear non-filtered tests status; in case we re-filter and they become visible
  for(id<GRTest> test in [_suite children])
    if (!test.disabled) [test reset];
  
  if (!_runner) {
    _runner = [GRTestRunner runnerForSuite:_suite];
  }
  _runner.delegate = delegate;
  [_runner setInParallel:inParallel];
  [_runner run:nil];
}

- (BOOL)isRunning {
	return _runner.isRunning;
}

@end

@interface  GRTestNode ()
@property id<GRTest> test;
@property NSMutableArray */*of GRTestNode*/children;
@property NSMutableArray */* of GRTestNode*/filteredChildNodes;
@end

@implementation GRTestNode

- (id)initWithTest:(id<GRTest>)test children:(NSArray */*of id<GRTest>*/)children source:(GRTestViewModel *)source {
	if ((self = [super init])) {
		_test = test;
		
		NSMutableArray *nodeChildren = [NSMutableArray array];
		for(id<GRTest> test in children) {	
			
			GRTestNode *node = nil;
			if ([test conformsToProtocol:@protocol(GRTestGroup)]) {
				NSArray *testChildren = [(id<GRTestGroup>)test children];
				if ([testChildren count] > 0) 
					node = [GRTestNode nodeWithTest:test children:testChildren source:source];
			} else {
				node = [GRTestNode nodeWithTest:test children:nil source:source];
			}			
			if (node)
				[nodeChildren addObject:node];
		}
		_children = nodeChildren;
		[source registerNode:self];
	}
	return self;
}


+ (GRTestNode *)nodeWithTest:(id<GRTest>)test children:(NSArray *)children source:(GRTestViewModel *)source {
	return [[GRTestNode alloc] initWithTest:test children:children source:source];
}

- (void)notifyChanged {
	[_delegate testNodeDidChange:self];
}

- (NSArray *)filteredChildren {
  if (_filter != GRTestNodeFilterNone || _textFilter) return _filteredChildNodes;
  return _children;
}

- (void)_applyFilters {  
  NSMutableSet *textFiltered = [NSMutableSet set];
  for(GRTestNode *childNode in _children) {
    [childNode setTextFilter:_textFilter];
    if (_textFilter) {
      if (([self.name rangeOfString:_textFilter options:NSCaseInsensitiveSearch].location != NSNotFound) || ([childNode.name rangeOfString:_textFilter options:NSCaseInsensitiveSearch].location != NSNotFound) || [[childNode filteredChildren] count] > 0)
        [textFiltered addObject:childNode];
    }
  }
  
  NSMutableSet *filtered = [NSMutableSet set];
  for(GRTestNode *childNode in _children) {      
    [childNode setFilter:_filter];
    if (_filter == GRTestNodeFilterFailed) { 
      if ([[childNode filteredChildren] count] > 0 || childNode.failed)
        [filtered addObject:childNode];
    }
  }
  
  _filteredChildNodes = [NSMutableArray array];
  for(GRTestNode *childNode in _children) {
    if (((!_textFilter || [textFiltered containsObject:childNode]) && 
        (_filter == GRTestNodeFilterNone || [filtered containsObject:childNode])) || [[childNode filteredChildren] count] > 0) {
      [_filteredChildNodes addObject:childNode];
      if (![[childNode filteredChildren] count] > 0) {
        [childNode.test setDisabled:NO];
      }
    } else {
      if (![[childNode filteredChildren] count] > 0) {
        [childNode.test setDisabled:YES];
      }
    }
  }
}

- (void)setTextFilter:(NSString *)textFilter {
  [self setFilter:_filter textFilter:textFilter];
}

- (void)setFilter:(GRTestNodeFilter)filter {
  [self setFilter:filter textFilter:_textFilter];
}

- (void)setFilter:(GRTestNodeFilter)filter textFilter:(NSString *)textFilter {
  _filter = filter;
  
  textFilter = [textFilter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([textFilter isEqualToString:@""]) textFilter = nil;
  
  _textFilter = textFilter;    
  [self _applyFilters];    
}

- (NSString *)name {
	return [_test name];
}

- (NSString *)identifier {
	return [_test identifier];
}

- (NSString *)statusString {
	// TODO(gabe): Some other special chars: ☐✖✗✘✓
	NSString *status = @"";
	NSString *interval = @"";
	if (self.isRunning) {
		status = @"✸";
		if (self.isGroupTest)
			interval = [NSString stringWithFormat:@"%0.2fs", [_test interval]];
	} else if (self.isEnded) {
		if ([_test interval] >= 0)
			interval = [NSString stringWithFormat:@"%0.2fs", [_test interval]];

		if ([_test status] == GRTestStatusErrored) status = @"✘";
		else if ([_test status] == GRTestStatusSucceeded) status = @"✔";
		else if ([_test status] == GRTestStatusCancelled) {
			status = @"-";
			interval = @"";
		} else if ([_test isDisabled] || [_test isHidden]) {
			status = @"⊝";
			interval = @"";
		}
	} else if (!self.isSelected) {
		status = @"";
	}

	if (self.isGroupTest) {
		NSString *statsString = [NSString stringWithFormat:@"%@/%@ (%@ failed)",
														 @([_test stats].succeedCount+[_test stats].failureCount),
														 @([_test stats].testCount), @([_test stats].failureCount)];
		return [NSString stringWithFormat:@"%@ %@ %@", status, statsString, interval];
	} else {
		return [NSString stringWithFormat:@"%@ %@", status, interval];
	}
}

- (NSString *)nameWithStatus {
	NSString *interval = @"";
	if (self.isEnded) interval = [NSString stringWithFormat:@" (%0.2fs)", [_test interval]];
	return [NSString stringWithFormat:@"%@%@", self.name, interval];
}

- (BOOL)isGroupTest {
	return ([_test conformsToProtocol:@protocol(GRTestGroup)]);
}

- (BOOL)failed {
	return [_test status] == GRTestStatusErrored;
}
	
- (BOOL)isRunning {
	return GRTestStatusIsRunning([_test status]);
}

- (BOOL)isDisabled {
	return [_test isDisabled];
}

- (BOOL)isHidden {
	return [_test isHidden];
}

- (BOOL)isEnded {
	return GRTestStatusEnded([_test status]);
}

- (GRTestStatus)status {
	return [_test status];
}

- (NSString *)stackTrace {
	if (![_test exception]) return nil;

	return [GRTesting descriptionForException:[_test exception]];
}

- (NSString *)exceptionFilename {
  return [GRTesting exceptionFilenameForTest:_test];
}

- (NSInteger)exceptionLineNumber {
  return [GRTesting exceptionLineNumberForTest:_test];
}

- (NSString *)log {
	return [[_test log] componentsJoinedByString:@"\n"]; // TODO(gabe): This isn't very performant
}

- (NSString *)description {
	return [_test description];
}

- (BOOL)isSelected {
	return ![_test isHidden];
}

- (void)setSelected:(BOOL)selected {
	[_test setHidden:!selected];
	for(GRTestNode *node in _children) 
		[node setSelected:selected];
	[self notifyChanged];
}

@end

//! @endcond
