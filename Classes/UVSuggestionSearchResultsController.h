//
//  UVSuggestionSearchResultsController.h
//  UserVoice
//
//  Created by Donny Davis on 9/13/16.
//  Copyright © 2016 UserVoice Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UVBaseViewController.h"

@interface UVSuggestionSearchResultsController: UVBaseViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSArray *searchResults;

@end
