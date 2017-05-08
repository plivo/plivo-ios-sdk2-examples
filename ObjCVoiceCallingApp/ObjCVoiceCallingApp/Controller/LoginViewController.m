//
//  LoginViewController.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 11/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "LoginViewController.h"
#import "UtilityClass.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "APIRequestManager.h"
#import "UIView+Toast.h"
#import "PlivoCallController.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <Crashlytics/Crashlytics.h>
#import <Google/SignIn.h>

@interface LoginViewController ()<GIDSignInUIDelegate,GIDSignInDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *googleButton;

- (IBAction)loginButtonTapped:(id)sender;
- (IBAction)googleloginTapped:(id)sender;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.loginButton.layer.cornerRadius = DEVICE_HEIGHT * 0.04401408451;
    self.googleButton.layer.cornerRadius = DEVICE_HEIGHT * 0.04401408451;


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Hide keyboard after user press 'return' key
 */
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

/**
 * Hide keyboard when text filed being clicked
 */
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField       // return NO to disallow editing.
{
    if(textField == self.userNameTextField)
    {
        self.userNameTextField.text = @"";
        return YES;

    }
    else
    {
        self.passwordTextField.text = @"";
        return YES;

    }
}

/**
 *  Hide keyboard when user touches on UI
 *
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    if(touch.phase == UITouchPhaseBegan)
    {
        [self.userNameTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
    }
}


- (IBAction)loginButtonTapped:(id)sender
{
    
    if (NO == [UtilityClass isEmptyString:self.userNameTextField.text] && NO == [UtilityClass isEmptyString:self.passwordTextField.text] && ![self.userNameTextField.text isEqualToString:@"SIP Username"])
    {
        if([UtilityClass isNetworkAvailable])
        {
            self.view.userInteractionEnabled = NO;
            
            [UtilityClass makeToastActivity];

            [[Phone sharedInstance] loginWithUserName:self.userNameTextField.text andPassword:self.passwordTextField.text];
            
            [FIRAnalytics logEventWithName:@"Login"
                                parameters:@{
                                             @"Username": self.userNameTextField.text
                                             }];

        }
        else
        {
            [UtilityClass makeToast:kNOINTERNETMSG];

        }
    }
    else
    {
        [UtilityClass makeToast:kINVALIDENTRIESMSG];

    }
  
}

/**
 * onLogin delegate implementation.
 */
- (void)onLogin
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UtilityClass hideToastActivity];
        
        [UtilityClass makeToast:kLOGINSUCCESS];

        /**
         *  If user already logged in with G+ signIn
         *
         */
        if(![[NSUserDefaults standardUserDefaults] objectForKey:kUSERNAME])
        {
            [[NSUserDefaults standardUserDefaults] setObject:self.userNameTextField.text forKey:kUSERNAME];
            [[NSUserDefaults standardUserDefaults] setObject:self.passwordTextField.text forKey:kPASSWORD];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[Crashlytics sharedInstance] setUserIdentifier:self.userNameTextField.text];

            [FIRAnalytics logEventWithName:@"LoginSuccess"
                                parameters:@{
                                             @"Type": @"Direct",
                                             @"Username": self.userNameTextField.text
                                             }];

        }
        
        [UtilityClass setUserAuthenticationStatus:YES];


        //Default View Controller: ContactsViewController
        //Landing page
        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        UITabBarController* tabbarControler = [_mainStoryboard instantiateViewControllerWithIdentifier:@"tabBarViewController"];
        
        PlivoCallController* plivoVC = [tabbarControler.viewControllers objectAtIndex:2];
        [[Phone sharedInstance] setDelegate:plivoVC];

        tabbarControler.selectedViewController = [tabbarControler.viewControllers objectAtIndex:1];
        _appDelegate.window.rootViewController = tabbarControler;
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate voipRegistration];

    });

}

/**
 * onLoginFailed delegate implementation.
 */
- (void)onLoginFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UtilityClass setUserAuthenticationStatus:NO];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUSERNAME];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPASSWORD];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[GIDSignIn sharedInstance] signOut];
        
        [UtilityClass hideToastActivity];
        
        [UtilityClass makeToast:kLOGINFAILMSG];
        
        self.view.userInteractionEnabled = YES;

        [FIRAnalytics logEventWithName:@"LoginFailed"
                            parameters:@{
                                         @"Username": kUSERNAME
                                         }];

        
    });
}

- (IBAction)googleloginTapped:(id)sender
{
    [FIRAnalytics logEventWithName:@"GoogleSignIn"
                        parameters:nil];

    self.view.userInteractionEnabled = NO;

    [GIDSignIn sharedInstance].uiDelegate = self;
    [GIDSignIn sharedInstance].delegate=self;
    
    [GIDSignIn sharedInstance].clientID = @"900363642731-b014hv4khou88fokat0b7dkv3mocvtrm.apps.googleusercontent.com";// Replace with the value of CLIENT_ID key in GoogleService-Info.plist

    [GIDSignIn sharedInstance].shouldFetchBasicProfile=YES;

    [[GIDSignIn sharedInstance] signIn];

}

#pragma mark -Google SignIn Delegate
//pragma mark - Google SignIn Delegate
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error
{
    
}

// Dismiss the "Sign in with Google" view

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
// Present a view that prompts the user to sign in with Google

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController
{
    [self presentViewController:viewController animated:YES completion:nil];
}

//completed sign In

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error
{
 
    NSLog(@"userID  name===%@",user.profile.name);
    NSLog(@"userID emil ===%@",user.profile.email);

    if ([user.profile.email rangeOfString:@"@plivo.com"].location == NSNotFound)
    {
        [FIRAnalytics logEventWithName:@"InvalidEmail"
                            parameters:nil];

        [[GIDSignIn sharedInstance] signOut];

        [UtilityClass makeToast:kINVALIDEMAIL];
        
        self.view.userInteractionEnabled = YES;
        return;

    }
    else
    {
        
        if(![UtilityClass isEmptyString:user.profile.email])
        {
            [UtilityClass makeToastActivity];

            [self getSIPEndpointCredentials:user.profile.email];
            
            [FIRAnalytics logEventWithName:@"GoogleSignIn"
                                parameters:@{
                                             @"Name": user.profile.name,
                                             @"Email": user.profile.email
                                             }];
            
            [[Crashlytics sharedInstance] setUserName:user.profile.name];
            [[Crashlytics sharedInstance] setUserEmail:user.profile.email];
        }
        else
        {
            [FIRAnalytics logEventWithName:@"InvalidEmail"
                                parameters:nil];

            [[GIDSignIn sharedInstance] signOut];

            [UtilityClass makeToast:kINVALIDEMAIL];
            
            self.view.userInteractionEnabled = YES;
            return;

        }

    }
    
}

/*
 * API Call to SIP Endpoint
 * To get Array of SIP Endpoints
 *
 */
- (void)getSIPEndpointCredentials:(NSString*)emailId
{
    if([UtilityClass isNetworkAvailable])//Check internet connection
    {
        
         [APIRequestManager PostWithUrl:[NSString stringWithFormat:@"%@%@",kSERVERURL,emailId] Parameters:nil success:^(id json)
          {
              dispatch_async(dispatch_get_main_queue(), ^{
                  
                  NSArray* sipArray = json;
                  
                  NSDictionary* dict = sipArray[1];
                  
                  [[NSUserDefaults standardUserDefaults] setObject:sipArray[0] forKey:kUSERNAME];
                  [[NSUserDefaults standardUserDefaults] setObject:@"7bjbk5ib7f23ie05be2h5713hf1hl774j94c88244e2185b" forKey:kPASSWORD];
                  
                  [[Crashlytics sharedInstance] setUserIdentifier:sipArray[0]];

                  
                  NSMutableArray* sipContactsArray = [[NSMutableArray alloc] initWithCapacity:dict.allKeys.count];
                  
                  for(int i = 0; i < dict.allKeys.count; i++)
                  {
                      [sipContactsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:dict.allKeys[i],@"eMail",dict.allValues[i],@"endPoint", nil]];
                  }
                  
                  [[NSUserDefaults standardUserDefaults] setObject:[sipContactsArray copy] forKey:kSIPDETAILS];
                  
                  [[NSUserDefaults standardUserDefaults] synchronize];
                  
                  [[Phone sharedInstance] setDelegate:self];
                  
                  NSLog(@"Username in G+ %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUSERNAME]);
                  NSLog(@"Password in G+ %@",[[NSUserDefaults standardUserDefaults] objectForKey:kPASSWORD]);

                  [[Phone sharedInstance] loginWithUserName:[[NSUserDefaults standardUserDefaults] objectForKey:kUSERNAME] andPassword:[[NSUserDefaults standardUserDefaults] objectForKey:kPASSWORD]];
                  
                  [FIRAnalytics logEventWithName:@"JsonResponseSuccess"
                                      parameters:nil];

                  
              });
              
          } failure:^(NSError *error)
         {
             NSLog(@"Error is: %@",error.description);
             [FIRAnalytics logEventWithName:@"JsonResponseFail"
                                 parameters:@{
                                              @"Error": error.description
                                              }];

         }];
        
    }else
    {
        [FIRAnalytics logEventWithName:@"JsonResponseFail"
                            parameters:@{
                                         @"Error": kNOINTERNETMSG
                                         }];

        [UtilityClass makeToast:kNOINTERNETMSG];
    }
}

@end
