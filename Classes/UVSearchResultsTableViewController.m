//
//  UVSearchResultsTableViewController.m
//  UserVoice
//
//  Created by Donny Davis on 9/5/16.
//  Copyright © 2016 UserVoice Inc. All rights reserved.
//

#import "UVSearchResultsTableViewController.h"
#import "UVArticle.h"
#import "UVTruncatingLabel.m"

@interface UVSearchResultsTableViewController ()

@property (nonatomic, retain) NSMutableDictionary *templateCells;

@end

@implementation UVSearchResultsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _templateCells = [NSMutableDictionary dictionary];
}

- (void)dealloc {
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
    if (!IOS7) {
        cell.contentView.frame = CGRectMake(0, 0, [self cellWidthForStyle:tableView.style accessoryType:cell.accessoryType], 0);
        [cell.contentView setNeedsLayout];
        [cell.contentView layoutIfNeeded];
        for (UIView *view in cell.contentView.subviews) {
            if ([view isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)view;
                if (label.numberOfLines != 1) {
                    [label setPreferredMaxLayoutWidth:label.frame.size.width];
                }
                [label setBackgroundColor:[UIColor clearColor]];
            } else if ([view isKindOfClass:[UVTruncatingLabel class]]) {
                UVTruncatingLabel *label = (UVTruncatingLabel *)view;
                [label setPreferredMaxLayoutWidth:label.frame.size.width];
            }
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    return [self heightForDynamicRowWithReuseIdentifier:identifier indexPath:indexPath];
}

#pragma mark - Table cell configurations

- (CGFloat)heightForDynamicRowWithReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath {
    NSString *cacheKey = [NSString stringWithFormat:@"%@-%d", reuseIdentifier, (int)self.view.frame.size.width];
    UITableViewCell *cell = [_templateCells objectForKey:cacheKey];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:reuseIdentifier];
        SEL initCellSelector = NSSelectorFromString([NSString stringWithFormat:@"initCellFor%@:indexPath:", reuseIdentifier]);
        if ([self respondsToSelector:initCellSelector]) {
            [self performSelector:initCellSelector withObject:cell withObject:nil];
        }
        [_templateCells setObject:cell forKey:cacheKey];
    }
    SEL customizeCellSelector = NSSelectorFromString([NSString stringWithFormat:@"customizeCellFor%@:indexPath:", reuseIdentifier]);
    if ([self respondsToSelector:customizeCellSelector]) {
        [self performSelector:customizeCellSelector withObject:cell withObject:indexPath];
    }
    cell.contentView.frame = CGRectMake(0, 0, [self cellWidthForStyle:self.tableView.style accessoryType:cell.accessoryType], 10000);
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    
    // cells are usually flat so I don't bother to iterate recursively
    for (UIView *view in cell.contentView.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if (label.numberOfLines != 1) {
                [label setPreferredMaxLayoutWidth:label.frame.size.width];
            }
        }
    }
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    
    return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1;
}

- (CGFloat)cellWidthForStyle:(UITableViewStyle)style accessoryType:(UITableViewCellAccessoryType)accessoryType {
    CGFloat width = self.view.frame.size.width;
    CGFloat accessoryWidth = 0;
    CGFloat margin = 0;
    if (IOS8) {
        if (IPAD || IPHONE_PLUS) {
            if (accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
                accessoryWidth = 38;
            } else if (accessoryType == UITableViewCellAccessoryCheckmark) {
                accessoryWidth = 44;
            }
        } else {
            if (accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
                accessoryWidth = 34;
            } else if (accessoryType == UITableViewCellAccessoryCheckmark) {
                accessoryWidth = 40;
            }
        }
    } else if (IOS7) {
        if (accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
            accessoryWidth = 33;
        } else if (accessoryType == UITableViewCellAccessoryCheckmark) {
            accessoryWidth = 38.5;
        }
    } else {
        if (accessoryType == UITableViewCellAccessoryDisclosureIndicator || accessoryType == UITableViewCellAccessoryCheckmark) {
            accessoryWidth = 20;
        }
        if (width > 20) {
            if (width < 400) {
                margin = 10;
            } else {
                margin = MAX(31, MIN(45, width*0.06f));
            }
        } else {
            margin = width - 10;
        }
    }
    return width - (style == UITableViewStyleGrouped ? margin * 2 : 0) - accessoryWidth;
}

@end
