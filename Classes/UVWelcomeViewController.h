//
//  UVWelcomeViewController.h
//  UserVoice
//
//  Created by UserVoice on 12/15/09.
//  Copyright 2009 UserVoice Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UVBaseViewController.h"
#import "UVInstantAnswerManager.h"

#define IA_FILTER_ALL 0
#define IA_FILTER_ARTICLES 1
#define IA_FILTER_IDEAS 2

@interface UVWelcomeViewController : UVBaseViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating, UVInstantAnswersDelegate, UVModelDelegate>

@property (nonatomic, retain) UVInstantAnswerManager *instantAnswerManager;
//
// DDSearch
// May not need this search bar object
//
//@property (nonatomic, retain) UISearchBar *searchBarOld;
@property (nonatomic, assign) BOOL searching;

@end
