//
//  UVBaseSearchResultsViewController.m
//  UserVoice
//
//  Created by Donny Davis on 9/25/16.
//  Copyright © 2016 UserVoice Inc. All rights reserved.
//

#import "UVBaseSearchResultsViewController.h"

@interface UVBaseSearchResultsViewController ()

@end

@implementation UVBaseSearchResultsViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupPlainTableView];
    }
    return self;
}

- (void)dealloc {
    self.searchResults = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.backgroundView = nil;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    if (self.searchResults.count == 0) {
        UILabel *noResultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.frame.size.height)];
        noResultsLabel.text = @"No Results";
        noResultsLabel.textAlignment = NSTextAlignmentCenter;
        [noResultsLabel sizeToFit];
        tableView.backgroundView = noResultsLabel;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        return 0;
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SEL setupCellSelector = NSSelectorFromString(@"setupCellForRow:indexPath:");
    if ([self respondsToSelector:setupCellSelector]) {
        return [self performSelector:setupCellSelector withObject:tableView withObject:indexPath];
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

@end
