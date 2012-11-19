//
//  UVWelcomeViewController.m
//  UserVoice
//
//  Created by UserVoice on 12/15/09.
//  Copyright 2009 UserVoice Inc. All rights reserved.
//

#import "UVRootViewController.h"
#import "UVClientConfig.h"
#import "UVAccessToken.h"
#import "UVRequestToken.h"
#import "UVSession.h"
#import "UVUser.h"
#import "UVWelcomeViewController.h"
#import "UVNewSuggestionViewController.h"
#import "UVSuggestionListViewController.h"
#import "UVNewTicketViewController.h"
#import "UVNetworkUtils.h"
#import "UVSuggestion.h"
#import "UVConfig.h"
#import "NSError+UVExtras.h"
#import "UVStyleSheet.h"
#include <QuartzCore/QuartzCore.h>

@implementation UVRootViewController

@synthesize viewToLoad;

- (id)init {
    if (self = [super init]) {
        self.viewToLoad = @"welcome";
    }
    return self;
}

- (id)initWithViewToLoad:(NSString *)theViewToLoad {
    if (self = [super init]) {
        self.viewToLoad = theViewToLoad;
    }
    return self;
}

- (void)didReceiveError:(NSError *)error {
    if ([error isAuthError]) {
        if ([UVAccessToken exists]) {
            [[UVSession currentSession].accessToken remove];
            [UVSession currentSession].accessToken = nil;
            [UVRequestToken getRequestTokenWithDelegate:self];
        } else {
            [[[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Error", @"UserVoice", nil)
                                         message:NSLocalizedStringFromTable(@"This application didn't configure UserVoice properly", @"UserVoice", nil)
                                        delegate:self
                               cancelButtonTitle:nil
                               otherButtonTitles:NSLocalizedStringFromTable(@"OK", @"UserVoice", nil), nil] autorelease] show];
        }
    } else {
        [super didReceiveError:error];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self dismissUserVoice];
}

- (void)pushNextView {
    UVSession *session = [UVSession currentSession];
    if ((![UVAccessToken exists] || session.user) && session.clientConfig && [self.navigationController.viewControllers count] == 1) {
        CATransition* transition = [CATransition animation];
        transition.duration = 0.3;
        transition.type = kCATransitionFade;
        [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
        if (self.viewToLoad == @"welcome") {
            self.navigationController.navigationBarHidden = NO;
            UVWelcomeViewController *welcomeView = [[UVWelcomeViewController alloc] init];
            [self.navigationController pushViewController:welcomeView animated:NO];
            [welcomeView release];
        } else if (self.viewToLoad == @"suggestions") {
            self.navigationController.navigationBarHidden = NO;
            UIViewController *welcomeViewController = [[[UVWelcomeViewController alloc] init] autorelease];
            UIViewController *suggestionListViewController = [[[UVSuggestionListViewController alloc] initWithForum:[UVSession currentSession].clientConfig.forum] autorelease];
            NSArray *viewControllers = [NSArray arrayWithObjects:welcomeViewController, suggestionListViewController, nil];
            [self.navigationController setViewControllers:viewControllers animated:NO];
        } else if (self.viewToLoad == @"new_ticket") {
            self.navigationController.navigationBarHidden = NO;
            UIViewController *welcomeViewController = [[[UVWelcomeViewController alloc] init] autorelease];
            UIViewController *newTicketViewController = [[[UVNewTicketViewController alloc] init] autorelease];
            NSArray *viewControllers = [NSArray arrayWithObjects:welcomeViewController, newTicketViewController, nil];
            [self.navigationController setViewControllers:viewControllers animated:NO];
        }
    }
}

// Initialization: request token -> client config -> user -> persist the access token -> user's suggestions -> next view
// If we don't have either a configured user, or a persisted token (which is therefore an access token) then we go straight from the client config to the next view
- (void)didRetrieveRequestToken:(UVRequestToken *)token {
    // should be storing all tokens and checking on type
    [UVSession currentSession].requestToken = token;
    [UVClientConfig getWithDelegate:self];
}

- (void)didRetrieveClientConfig:(UVClientConfig *)clientConfig {
    // check if we have a sso token and if so exchange it for an access token and user
    if ([UVSession currentSession].config.ssoToken != nil) {
        [UVUser findOrCreateWithSsoToken:[UVSession currentSession].config.ssoToken delegate:self];
    } else if ([UVSession currentSession].config.email != nil) {
        [UVUser findOrCreateWithGUID:[UVSession currentSession].config.guid andEmail:[UVSession currentSession].config.email andName:[UVSession currentSession].config.displayName andDelegate:self];
    } else if ([UVAccessToken exists]) {
        [UVUser retrieveCurrentUser:self];
    } else {
        [self pushNextView];
    }
}

- (void)didCreateUser:(UVUser *)theUser {
    [UVSession currentSession].user = theUser;
    [[UVSession currentSession].accessToken persist];
    [self pushNextView];
}

- (void)didRetrieveCurrentUser:(UVUser *)theUser {
    [UVSession currentSession].user = theUser;
    [[UVSession currentSession].accessToken persist];
    [UVSuggestion getWithForumAndUser:[UVSession currentSession].clientConfig.forum
                                 user:theUser delegate:self];
}

- (void) didRetrieveUserSuggestions:(NSArray *) theSuggestions {
    UVUser *user = [UVSession currentSession].user;
    [user didLoadSuggestions:theSuggestions];
    [self pushNextView];
}

#pragma mark ===== Basic View Methods =====

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    [self showExitButton];

    CGRect frame = [self contentFrame];
    UIView *contentView = [[UIView alloc] initWithFrame:frame];
    CGFloat screenWidth = [UVClientConfig getScreenWidth];
    CGFloat screenHeight = [UVClientConfig getScreenHeight];

//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        contentView.backgroundColor = [UVStyleSheet backgroundColor];
//    else
//        contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];

    UILabel *splashLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, screenHeight/2 - 30, screenWidth, 20)];
    splashLabel2.backgroundColor = [UIColor clearColor];
    splashLabel2.font = [UIFont systemFontOfSize:15];
    splashLabel2.textColor = [UIColor darkGrayColor];
    splashLabel2.textAlignment = UITextAlignmentCenter;
    splashLabel2.text = NSLocalizedStringFromTable(@"Connecting to UserVoice", @"UserVoice", nil);
    [contentView addSubview:splashLabel2];
    [splashLabel2 release];

    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    if ([activity respondsToSelector:@selector(setColor:)]) {
        [activity setColor:[UIColor grayColor]];
    } else {
        [activity release];
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    activity.center = CGPointMake(screenWidth/2, (screenHeight/ 2) - 60);
    [contentView addSubview:activity];
    [activity startAnimating];
    [activity release];

    self.view = contentView;
    [contentView release];
}

- (void)viewWillAppear:(BOOL)animated {
    if (![UVNetworkUtils hasInternetAccess]) {
        UIImageView *serverErrorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uv_error_connection.png"]];
        self.navigationController.navigationBarHidden = NO;
        serverErrorImage.frame = self.view.frame;
        serverErrorImage.contentMode = UIViewContentModeCenter;
        serverErrorImage.backgroundColor = [UIColor colorWithRed:0.78f green:0.80f blue:0.83f alpha:1.0f];
        serverErrorImage.clipsToBounds = YES;
        [self.view addSubview:serverErrorImage];
        [serverErrorImage release];
    } else if (![UVAccessToken exists]) {
        [UVRequestToken getRequestTokenWithDelegate:self];
    } else if (![[UVSession currentSession] clientConfig]) {
        [UVSession currentSession].accessToken = [[[UVAccessToken alloc] initWithExisting] autorelease];
        [UVClientConfig getWithDelegate:self];
    } else if (![UVSession currentSession].user) {
        [UVSession currentSession].accessToken = [[[UVAccessToken alloc] initWithExisting] autorelease];
        [UVUser retrieveCurrentUser:self];
    } else {
        // We already have a client config, because the user already logged in before during
        // this session. Skip straight to the welcome view.
        [self pushNextView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    // Re-enable the navigation bar
    self.navigationController.navigationBarHidden = NO;
}

- (void)dealloc {
    self.viewToLoad = nil;
    [super dealloc];
}

@end
