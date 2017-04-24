//
//  AppDelegate.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 11/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Phone.h"
#import "ContactsViewController.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) ContactsViewController* viewController;

@end

