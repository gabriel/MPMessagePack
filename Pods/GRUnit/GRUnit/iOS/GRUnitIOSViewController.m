//
//  GRUnitIOSViewController.m
//  GRUnitIOS
//
//  Created by Gabriel Handford on 1/25/09.
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

#import "GRUnitIOSViewController.h"

#import "GRUnitIOSTestViewController.h"

NSString *const GRUnitTextFilterKey = @"TextFilter";
NSString *const GRUnitFilterKey = @"Filter";

@interface GRUnitIOSViewController ()
@property GRUnitIOSView *contentView;
@property GRUnitIOSTableViewDataSource *dataSource;
@property UIBarButtonItem *runButton;
@property BOOL userDidDrag; // If set then we will no longer auto scroll as tests are run

@property GRUnitIOSTestViewController *testViewController;
@end

@implementation GRUnitIOSViewController

- (id)init {
  if ((self = [super init])) {
    self.title = @"Tests";
  }
  return self;
}

- (void)loadDefaults { }

- (void)saveDefaults {
  [_dataSource saveDefaults];
}

- (void)loadView {
  [super loadView];

  _runButton = [[UIBarButtonItem alloc] initWithTitle:@"Run" style:UIBarButtonItemStyleDone target:self action:@selector(_toggleTestsRunning)];
  self.navigationItem.rightBarButtonItem = _runButton;  

  if (!_dataSource) {
    _dataSource = [[GRUnitIOSTableViewDataSource alloc] initWithIdentifier:@"Tests" suite:[GRTestSuite suiteFromEnv]];
    [_dataSource loadDefaults];
  }
  
  _contentView = [[GRUnitIOSView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  _contentView.searchBar.delegate = self;
  NSString *textFilter = [self _textFilter];
  if (textFilter) _contentView.searchBar.text = textFilter;  
  _contentView.filterControl.selectedSegmentIndex = [self _filterIndex];
  [_contentView.filterControl addTarget:self action:@selector(_filterChanged:) forControlEvents:UIControlEventValueChanged];
  _contentView.tableView.delegate = self;
  _contentView.tableView.dataSource = self.dataSource;
  self.view = _contentView;  
  [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self reload];
}

- (void)reload {
  [self.dataSource.root setTextFilter:[self _textFilter]];  
  [self.dataSource.root setFilter:[self _filterIndex]];
  [_contentView.tableView reloadData]; 
}

#pragma mark Running

- (void)_toggleTestsRunning {
  if (self.dataSource.isRunning) [self cancel];
  else [self runTests];
}

- (void)runTests {
  if (self.dataSource.isRunning) return;
  
  [self view];
  _runButton.title = @"Cancel";
  _userDidDrag = NO; // Reset drag status
  _contentView.statusLabel.textColor = [UIColor blackColor];
  _contentView.statusLabel.text = @"Starting tests...";
  [self.dataSource run:self inParallel:NO];
}

- (void)cancel {
  _contentView.statusLabel.text = @"Cancelling...";
  [_dataSource cancel];
}

- (void)_exit {
  exit(0);
}

#pragma mark Properties

- (NSString *)_textFilter {
  return [[NSUserDefaults standardUserDefaults] objectForKey:GRUnitTextFilterKey];
}

- (void)_setTextFilter:(NSString *)textFilter {
  [[NSUserDefaults standardUserDefaults] setObject:textFilter forKey:GRUnitTextFilterKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)_setFilterIndex:(NSInteger)index {
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:index] forKey:GRUnitFilterKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)_filterIndex {
  return [[[NSUserDefaults standardUserDefaults] objectForKey:GRUnitFilterKey] integerValue];
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

- (void)_filterChanged:(id)sender {
  [self _setFilterIndex:_contentView.filterControl.selectedSegmentIndex];
  [self reload];
}

- (void)reloadTest:(id<GRTest>)test {
  [_contentView.tableView reloadData];
  if (!_userDidDrag && !_dataSource.isEditing && ![test isDisabled] 
      && [test status] == GRTestStatusRunning && ![test conformsToProtocol:@protocol(GRTestGroup)]) 
    [self scrollToTest:test];
}

- (void)scrollToTest:(id<GRTest>)test {
  NSIndexPath *path = [_dataSource indexPathToTest:test];
  if (!path) return;
  [_contentView.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (void)scrollToBottom {
  NSInteger lastGroupIndex = [_dataSource numberOfGroups] - 1;
  if (lastGroupIndex < 0) return;
  NSInteger lastTestIndex = [_dataSource numberOfTestsInGroup:lastGroupIndex] - 1;
  if (lastTestIndex < 0) return;
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastTestIndex inSection:lastGroupIndex];
  [_contentView.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)setStatusText:(NSString *)message {
  _contentView.statusLabel.text = message;
}

#pragma mark Delegates (UITableView)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  GRTestNode *node = [_dataSource nodeForIndexPath:indexPath];
  if (_dataSource.isEditing) {
    [node setSelected:![node isSelected]];
    [node notifyChanged];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [_contentView.tableView reloadData];
  } else {    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GRTestNode *sectionNode = [[_dataSource root] filteredChildren][indexPath.section];
    GRTestNode *testNode = [sectionNode filteredChildren][indexPath.row];
    
    _testViewController = [[GRUnitIOSTestViewController alloc] init];
    [_testViewController setTest:testNode.test runnerDelegate:self];
    [self.navigationController pushViewController:_testViewController animated:YES];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 36.0f;
}

#pragma mark Delegates (UIScrollView) 

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  _userDidDrag = YES;
}

#pragma mark Delegates (GRTestRunner)

- (void)_setRunning:(BOOL)running runner:(GRTestRunner *)runner {
  if (running) {
    _contentView.filterControl.enabled = NO;
  } else {
    _contentView.filterControl.enabled = YES;
    GRTestStats stats = [runner.test stats];
    if (stats.failureCount > 0) {
      _contentView.statusLabel.textColor = [UIColor redColor];
    } else {
      _contentView.statusLabel.textColor = [UIColor blackColor];
    }

    _runButton.title = @"Run";
  }
}

- (void)testRunner:(GRTestRunner *)runner test:(id<GRTest>)test didLog:(NSString *)message {
  [self setStatusText:message];
  if ([test isEqual:_testViewController.test]) {
    [_testViewController log:message];
  }
}

- (void)testRunner:(GRTestRunner *)runner didStartTest:(id<GRTest>)test {
  [self setStatusText:[NSString stringWithFormat:@"Test '%@' started.", [test identifier]]];
  [self reloadTest:test];
}

- (void)testRunner:(GRTestRunner *)runner didUpdateTest:(id<GRTest>)test {
  [self reloadTest:test];
}

- (void)testRunner:(GRTestRunner *)runner didEndTest:(id<GRTest>)test { 
  [self reloadTest:test];
}

- (void)testRunnerDidStart:(GRTestRunner *)runner { 
  [self _setRunning:YES runner:runner];
}

- (void)testRunnerDidCancel:(GRTestRunner *)runner { 
  [self _setRunning:NO runner:runner];
  [self setStatusText:@"Cancelled..."];
}

- (void)testRunnerDidEnd:(GRTestRunner *)runner {
  [self _setRunning:NO runner:runner];
  [self setStatusText:[_dataSource statusString:@"Tests finished. "]];
  
  // Save defaults after test run
  [self saveDefaults];
  
  if (getenv("GRUNIT_AUTOEXIT")) {
    NSLog(@"Exiting (GRUNIT_AUTOEXIT)");
    exit((int)runner.test.stats.failureCount);
  }
}

#pragma mark Delegates (UISearchBar)

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  [searchBar setShowsCancelButton:YES animated:YES];  
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
  return ![_dataSource isRunning];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  // Workaround for clearing search
  if ([searchBar.text isEqualToString:@""]) {
    [self searchBarSearchButtonClicked:searchBar];
    return;
  }
  NSString *textFilter = [self _textFilter];
  searchBar.text = (textFilter ? textFilter : @"");
  [searchBar resignFirstResponder];
  [searchBar setShowsCancelButton:NO animated:YES]; 
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  [searchBar resignFirstResponder];
  [searchBar setShowsCancelButton:NO animated:YES]; 
  
  [self _setTextFilter:searchBar.text];
  [self reload];
}

@end
