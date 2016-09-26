//
//  UVSuggestionSearchResultsController.m
//  UserVoice
//
//  Created by Donny Davis on 9/13/16.
//  Copyright © 2016 UserVoice Inc. All rights reserved.
//

#import "UVSuggestionSearchResultsController.h"
#import "UVUtils.h"
#import "UVClientConfig.h"
#import "UVSession.h"
#import "UVSuggestion.h"
#import "UVSuggestionDetailsViewController.h"

#define TITLE 20
#define SUBSCRIBER_COUNT 21
#define STATUS 22
#define STATUS_COLOR 23

@interface UVSuggestionSearchResultsController ()

@end

@implementation UVSuggestionSearchResultsController

- (void)dismiss {
    [super dismiss];
}

#pragma mark ===== table cells =====

- (void)initCellForResult:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    [self initCellForSuggestion:cell indexPath:indexPath];
}

- (void)customizeCellForResult:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    [self customizeCellForSuggestion:[self.searchResults objectAtIndex:indexPath.row] cell:cell];
}

- (void)initCellForSuggestion:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UIImageView *heart = [UVUtils imageViewWithImageNamed:@"uv_heart.png"];
    UILabel *subs = [UILabel new];
    subs.font = [UIFont systemFontOfSize:14];
    subs.textColor = [UIColor grayColor];
    subs.tag = SUBSCRIBER_COUNT;
    UILabel *title = [UILabel new];
    title.numberOfLines = 0;
    title.tag = TITLE;
    title.font = [UIFont systemFontOfSize:17];
    UILabel *status = [UILabel new];
    status.font = [UIFont systemFontOfSize:11];
    status.tag = STATUS;
    UIView *statusColor = [UIView new];
    statusColor.tag = STATUS_COLOR;
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, 9, 9);
    [statusColor.layer addSublayer:layer];
    NSArray *constraints = @[
                             @"|-16-[title]-|",
                             @"|-16-[heart(==9)]-3-[subs]-10-[statusColor(==9)]-5-[status]",
                             @"V:|-12-[title]-6-[heart(==9)]",
                             @"V:[title]-6-[statusColor(==9)]",
                             @"V:[title]-4-[status]",
                             @"V:[title]-2-[subs]"
                             ];
    [self configureView:cell.contentView
               subviews:NSDictionaryOfVariableBindings(subs, title, heart, statusColor, status)
            constraints:constraints
         finalCondition:indexPath == nil
        finalConstraint:@"V:[heart]-14-|"];
}

- (void)customizeCellForSuggestion:(UVSuggestion *)suggestion cell:(UITableViewCell *)cell {
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:TITLE];
    UILabel *subs = (UILabel *)[cell.contentView viewWithTag:SUBSCRIBER_COUNT];
    UILabel *status = (UILabel *)[cell.contentView viewWithTag:STATUS];
    UIView *statusColor = [cell.contentView viewWithTag:STATUS_COLOR];
    title.text = suggestion.title;
    if ([UVSession currentSession].clientConfig.displaySuggestionsByRank) {
        subs.text = suggestion.rankString;
    } else {
        subs.text = [NSString stringWithFormat:@"%d", (int)suggestion.subscriberCount];
    }
    [(CALayer *)statusColor.layer.sublayers.lastObject setBackgroundColor:suggestion.statusColor.CGColor];
    status.textColor = suggestion.statusColor;
    status.text = [suggestion.status uppercaseString];
}

#pragma mark - Table view data source

- (UITableViewCell *)setupCellForRow:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"Result";
    NSInteger style = UITableViewCellStyleDefault;
    
    return [self createCellForIdentifier:identifier tableView:tableView indexPath:indexPath style:style selectable:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showSuggestion:[self.searchResults objectAtIndex:indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForDynamicRowWithReuseIdentifier:@"Result" indexPath:indexPath];
}

- (void)showSuggestion:(UVSuggestion *)suggestion {
    UVSuggestionDetailsViewController *next = [[UVSuggestionDetailsViewController alloc] initWithSuggestion:suggestion];
    [self.presentingViewController.navigationController pushViewController:next animated:YES];
}

@end
