//
//  UVWelcomeSearchResultsController.m
//  UserVoice
//
//  Created by Donny Davis on 9/5/16.
//  Copyright © 2016 UserVoice Inc. All rights reserved.
//

#import "UVWelcomeSearchResultsController.h"
#import "UVArticle.h"

@interface UVWelcomeSearchResultsController ()
@end

@implementation UVWelcomeSearchResultsController

- (instancetype)init {
    self = [super init];
    if (self) {
        _instantAnswerManager = [UVInstantAnswerManager new];
        [self setupPlainTableView];
        return self;
    }
}

- (void)dealloc {
    _instantAnswerManager = nil;
}

- (void)dismiss {
    _instantAnswerManager = nil;
    [super dismiss];
}

#pragma mark ===== table cells =====

- (void)initCellForArticleResult:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    [_instantAnswerManager initCellForArticle:cell finalCondition:indexPath == nil];
}

- (void)customizeCellForArticleResult:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    id model = [self.searchResults objectAtIndex:indexPath.row];
    [_instantAnswerManager customizeCell:cell forArticle:(UVArticle *)model];
}

- (void)initCellForSuggestionResult:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    [_instantAnswerManager initCellForSuggestion:cell finalCondition:indexPath == nil];
}

- (void)customizeCellForSuggestionResult:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    id model = [self.searchResults objectAtIndex:indexPath.row];
    [_instantAnswerManager customizeCell:cell forSuggestion:(UVSuggestion *)model];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.backgroundView = nil;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    if (_searchResults.count == 0) {
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
    return _searchResults.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"";
    NSInteger style = UITableViewCellStyleDefault;
    id model = [_searchResults objectAtIndex:indexPath.row];
    if ([model isMemberOfClass:[UVArticle class]]) {
        identifier = @"ArticleResult";
    } else {
        identifier = @"SuggestionResult";
    }
    
    return [self createCellForIdentifier:identifier tableView:tableView indexPath:indexPath style:style selectable:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_instantAnswerManager pushViewFor:[_searchResults objectAtIndex:indexPath.row] parent:self.presentingViewController];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    id model = [_searchResults objectAtIndex:indexPath.row];
    if ([model isMemberOfClass:[UVArticle class]]) {
        identifier = @"ArticleResult";
    } else {
        identifier = @"SuggestionResult";
    }
    return [self heightForDynamicRowWithReuseIdentifier:identifier indexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

@end
