//
//  UVNavigationController.m
//  UserVoice
//
//  Created by Austin Taylor on 11/1/12.
//  Copyright (c) 2012 UserVoice Inc. All rights reserved.
//

#import "UVNavigationController.h"

@implementation UVNavigationController

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (!_preferredStatusBarStyle) {
        return UIStatusBarStyleDefault;
    }
    return _preferredStatusBarStyle;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

@end