//
//  AppDelegate.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 11/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "UtilityClass.h"
#import <Intents/Intents.h>
#import "Constants.h"
#import "CallKitInstance.h"
#import <AVFoundation/AVFoundation.h>
#import <Google/SignIn.h>
#import "CallKitInstance.h"
#import "PlivoCallController.h"
#import "UIView+Toast.h"

#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    // Override point for customization after application launch.
    if(SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0"))
    {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if( !error ){
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
        }];
    }
    
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)])
    {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            
        }];
    }
    
    
    if([UtilityClass getUserAuthenticationStatus])
    {
    
        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UITabBarController* tabBarContrler = [_mainStoryboard instantiateViewControllerWithIdentifier:@"tabBarViewController"];
        self.viewController = [tabBarContrler.viewControllers objectAtIndex:1];
        [[Phone sharedInstance] setDelegate:self.viewController];
        tabBarContrler.selectedViewController = [tabBarContrler.viewControllers objectAtIndex:1];
        
        [[Phone sharedInstance] loginWithUserName:[[NSUserDefaults standardUserDefaults] objectForKey:kUSERNAME] andPassword:[[NSUserDefaults standardUserDefaults] objectForKey:kPASSWORD]];

        self.window.rootViewController = tabBarContrler;
        
        
    }else
    {
        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        LoginViewController* loginVC = [_mainStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [[Phone sharedInstance] setDelegate:loginVC];
        self.window.rootViewController = loginVC;
        
    }
    
    return YES;
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    //Called when a notification is delivered to a foreground app.
    NSLog(@"willPresentNotification Userinfo %@",notification.request.content.userInfo);
    completionHandler(UNNotificationPresentationOptionAlert);
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler
{
    
    //Called to let your app know which action was selected by the user for a given notification.
    
    NSLog(@"didReceiveNotificationResponse Userinfo %@",response.notification.request.content.userInfo);
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options NS_AVAILABLE_IOS(9_0)
{
    return [self application:app
        processOpenURLAction:url
           sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                  annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
                  iosVersion:9];
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [self application:application
        processOpenURLAction:url
           sourceApplication:sourceApplication
                  annotation:annotation
                  iosVersion:8];
}

- (BOOL)application:(UIApplication *)application processOpenURLAction:(NSURL*)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation iosVersion:(int)version
{
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray * __nullable restorableObjects))restorationHandler NS_AVAILABLE_IOS(8_0)
{
    
    //Added by Siva on Tue 7, 2017
    if([UtilityClass getUserAuthenticationStatus])
    {
        
        INInteraction *interaction = userActivity.interaction;
        
        INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
        
        INPerson *contact = startAudioCallIntent.contacts[0];
        
        INPersonHandle *personHandle = contact.personHandle;
        
        NSString *contactValue = personHandle.value;
        
        [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
        
        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UITabBarController* tabBarContrler = [_mainStoryboard instantiateViewControllerWithIdentifier:@"tabBarViewController"];
        PlivoCallController* plivoVC  = [tabBarContrler.viewControllers objectAtIndex:2];
        [[Phone sharedInstance] setDelegate:plivoVC];
        [plivoVC performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:contactValue];
        tabBarContrler.selectedViewController = [tabBarContrler.viewControllers objectAtIndex:2];
        self.window.rootViewController = tabBarContrler;

        return YES;
        
    }else
    {
        [self.window.rootViewController.view makeToast:@"Please login to make a call"];
        return NO;
        
    }
    
}
@end

//Customizing Tabbar
//    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0], NSFontAttributeName, nil];
//    [[UITabBarItem appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
//    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, -13.0)];

