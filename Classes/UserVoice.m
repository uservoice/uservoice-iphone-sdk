//
//  UserVoice.m
//  UserVoice
//
//  Created by UserVoice on 10/19/09.
//  Copyright 2009 UserVoice Inc. All rights reserved.
//

#import "UserVoice.h"
#import "UVConfig.h"
#import "UVClientConfig.h"
#import "UVWelcomeViewController.h"
#import "UVRootViewController.h"
#import "UVSession.h"

@implementation UserVoice

+ (void)presentUserVoiceModalViewControllerForParent:(UIViewController *)viewController 
											 andSite:(NSString *)site
											  andKey:(NSString *)key
										   andSecret:(NSString *)secret
                                            delegate:(id)delegate {
	[UVSession currentSession].config = [[[UVConfig alloc] initWithSite:site andKey:key andSecret:secret] autorelease];
 	
	UIViewController *rootViewController;
	if ([[UVSession currentSession] clientConfig])
	{
		rootViewController = [[[UVWelcomeViewController alloc] init] autorelease];
	}
	else
	{
		rootViewController = [[[UVRootViewController alloc] init] autorelease];
	}
    [(UVBaseViewController *)rootViewController setDelegate:delegate];
	
	// Capture the launch orientation, then store it in NSDefaults for reference in all other UV view controller classes
	[UVClientConfig setOrientation];
	
	[self showUserVoice:rootViewController forController:viewController];
}

+ (void)presentUserVoiceModalViewControllerForParent:(UIViewController *)viewController 
											 andSite:(NSString *)site
											  andKey:(NSString *)key
										   andSecret:(NSString *)secret
										 andSsoToken:(NSString *)token
                                            delegate:(id)delegate {
	[UVSession currentSession].config = [[[UVConfig alloc] initWithSite:site andKey:key andSecret:secret] autorelease];
	
	// always use the sso token to ensure details are updated	
	UIViewController *rootViewController;
    rootViewController = [[[UVRootViewController alloc] initWithSsoToken:token] autorelease];
    [(UVBaseViewController *)rootViewController setDelegate:delegate];
	
	// Capture the launch orientation, then store it in NSDefaults for reference in all other UV view controller classes
	[UVClientConfig setOrientation];
	
	[self showUserVoice:rootViewController forController:viewController];
}

+ (void)presentUserVoiceModalViewControllerForParent:(UIViewController *)viewController 
											 andSite:(NSString *)site
											  andKey:(NSString *)key
										   andSecret:(NSString *)secret
											andEmail:(NSString *)email
									  andDisplayName:(NSString *)displayName
											 andGUID:(NSString *)guid
                                            delegate:(id)delegate {
	[UVSession currentSession].config = [[[UVConfig alloc] initWithSite:site andKey:key andSecret:secret] autorelease];
	
	UIViewController *rootViewController;
	if ([[UVSession currentSession] clientConfig])
	{
		rootViewController = [[[UVWelcomeViewController alloc] init] autorelease];
	}
	else
	{
		rootViewController = [[[UVRootViewController alloc] initWithEmail:email 
																  andGUID:guid 
																  andName:displayName] autorelease];
	}
    [(UVBaseViewController *)rootViewController setDelegate:delegate];
	
	// Capture the launch orientation, then store it in NSDefaults for reference in all other UV view controller classes
	[UVClientConfig setOrientation];
	
	[self showUserVoice:rootViewController forController:viewController];
	
}

+ (void)showUserVoice:(UIViewController *)rootViewController forController:(UIViewController *)viewController {
	[UVSession currentSession].isModal = YES;
	UINavigationController *userVoiceNav = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
	[viewController presentModalViewController:userVoiceNav animated:YES];
}

@end
