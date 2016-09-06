//
//  UVSearchResultsTableViewController.m
//  UserVoice
//
//  Created by Donny Davis on 9/5/16.
//  Copyright © 2016 UserVoice Inc. All rights reserved.
//

#import "UVSearchResultsTableViewController.h"
#import "UVArticle.h"
#import "UVBaseViewController.h"

@interface UVSearchResultsTableViewController ()

@property (nonatomic, strong) UVBaseViewController *baseVC;

@end

@implementation UVSearchResultsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _baseVC = [[UVBaseViewController alloc] init];
}

- (void)dealloc {
    _baseVC = nil;
    _instantAnswerManager = nil;
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
    UILabel *noResultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.frame.size.height)];
    noResultsLabel.text = @"No Results";
    noResultsLabel.textAlignment = NSTextAlignmentCenter;
    [noResultsLabel sizeToFit];
    
    if (_searchResults.count == 0) {
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        SEL initCellSelector = NSSelectorFromString([NSString stringWithFormat:@"initCellFor%@:indexPath:", identifier]);
        if ([self respondsToSelector:initCellSelector]) {
            [self performSelector:initCellSelector withObject:cell withObject:indexPath];
        }
    }
    
    SEL customizeCellSelector = NSSelectorFromString([NSString stringWithFormat:@"customizeCellFor%@:indexPath:", identifier]);
    if ([self respondsToSelector:customizeCellSelector]) {
        [self performSelector:customizeCellSelector withObject:cell withObject:indexPath];
    }
    
    return cell;
//    return [_baseVC createCellForIdentifier:identifier tableView:tableView indexPath:indexPath style:style selectable:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_instantAnswerManager pushViewFor:[_searchResults objectAtIndex:indexPath.row] parent:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    id model = [_searchResults objectAtIndex:indexPath.row];
    if ([model isMemberOfClass:[UVArticle class]]) {
        identifier = @"ArticleResult";
    } else {
        identifier = @"SuggestionResult";
    }
    return [_baseVC heightForDynamicRowWithReuseIdentifier:identifier indexPath:indexPath];
}

@end
