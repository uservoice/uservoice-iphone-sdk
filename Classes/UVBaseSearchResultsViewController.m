//
//  UVBaseSearchResultsViewController.m
//  UserVoice
//
//  Created by Donny Davis on 9/25/16.
//  Copyright © 2016 UserVoice Inc. All rights reserved.
//

#import "UVBaseSearchResultsViewController.h"

@interface UVBaseSearchResultsViewController ()
- (UITableViewCell *)setupCellForRow:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
@end

@implementation UVBaseSearchResultsViewController

- (void)loadView {
    [super loadView];
    [self setupPlainTableView];
}

- (void)dealloc {
    self.searchResults = nil;
}

- (UIView *)displayNoResults {
    if (self.searchResults.count == 0) {
        UILabel *noResultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height)];
        noResultsLabel.text = @"No Results";
        noResultsLabel.textAlignment = NSTextAlignmentCenter;
        [noResultsLabel sizeToFit];
        return noResultsLabel;
    } else {
        return nil;
    }
}

- (UITableViewCell *)setupCellForRow:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    NSAssert(NO, @"Must be implemented in subclass!");
    return nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
    return (self.searchResults.count == 0) ? 0 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self setupCellForRow:tableView indexPath:indexPath];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

@end
