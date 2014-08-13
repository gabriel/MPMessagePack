//
//  GRUnitIOSView.m
//  GRUnitIOS
//
//  Created by Gabriel Handford on 4/12/10.
//  Copyright 2010. All rights reserved.
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

#import "GRUnitIOSView.h"

@interface GRUnitIOSView ()
@property UILabel *statusLabel;
@property UISegmentedControl *filterControl;
@property UISearchBar *searchBar;
@property UITableView *tableView;
@property UIView *footerView;
@property UIToolbar *runToolbar;
@end

@implementation GRUnitIOSView

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    _searchBar.showsCancelButton = NO;
    [self addSubview:_searchBar];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 420) style:UITableViewStylePlain];
    _tableView.sectionIndexMinimumDisplayRowCount = 5;
    [self addSubview:_tableView];
    
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 36)];
    _footerView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 310, 36)];
    _statusLabel.text = @"Select 'Run' to start tests";
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.font = [UIFont systemFontOfSize:12];
    _statusLabel.numberOfLines = 2;
    [_footerView addSubview:_statusLabel];
    
    [self addSubview:_footerView];
    
    _runToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 36)];
    _filterControl = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Failed"]];
    _filterControl.frame = CGRectMake(20, 6, 280, 24);
    [_runToolbar addSubview:_filterControl];
    [self addSubview:_runToolbar];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGSize size = self.frame.size;
  CGFloat y = 64;
  CGFloat contentHeight = size.height - 44 - 36 - 36 - y;
  
  _searchBar.frame = CGRectMake(0, y, size.width, 44);
  y += 44;
  
  _tableView.frame = CGRectMake(0, y, size.width, contentHeight);
  y += contentHeight;
  
  _footerView.frame = CGRectMake(0, y, size.width, 36);
  y += 36;
  
  _runToolbar.frame = CGRectMake(0, y, size.width, 36);      
}

@end
