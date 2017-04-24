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
//#import "ContactsViewController.h"
#import <Google/SignIn.h>
#import "APIRequestManager.h"
#import "UIView+Toast.h"
#import "PlivoCallController.h"

@interface LoginViewController ()<GIDSignInUIDelegate,GIDSignInDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
- (IBAction)loginButtonTapped:(id)sender;
- (IBAction)googleloginTapped:(id)sender;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

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
            
            [self.view makeToastActivity:CSToastPositionCenter];

            [[Phone sharedInstance] loginWithUserName:self.userNameTextField.text andPassword:self.passwordTextField.text];
        }
        else
        {
            [self.view makeToast:kNOINTERNETMSG];

        }
    }
    else
    {
        [self.view makeToast:kINVALIDENTRIESMSG];

    }
  
}

/**
 * onLogin delegate implementation.
 */
- (void)onLogin
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.view hideToastActivity];

        [self.view makeToast:kLOGINSUCCESS];

        /**
         *  If user already logged in with G+ signIn
         *
         */
        if(![[NSUserDefaults standardUserDefaults] objectForKey:kUSERNAME])
        {
            [[NSUserDefaults standardUserDefaults] setObject:self.userNameTextField.text forKey:kUSERNAME];
            [[NSUserDefaults standardUserDefaults] setObject:self.passwordTextField.text forKey:kPASSWORD];
            [[NSUserDefaults standardUserDefaults] synchronize];

        }
        
        [UtilityClass setUserAuthenticationStatus:YES];

        //Default View Controller: ContactsViewController
        //Landing page
        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        UITabBarController* tabbarControler = [_mainStoryboard instantiateViewControllerWithIdentifier:@"tabBarViewController"];
//        ContactsViewController* contactsVC = [tabbarControler.viewControllers objectAtIndex:1];
//        [[Phone sharedInstance] setDelegate:contactsVC];
        
        PlivoCallController* plivoVC = [tabbarControler.viewControllers objectAtIndex:2];
        [[Phone sharedInstance] setDelegate:plivoVC];

        tabbarControler.selectedViewController = [tabbarControler.viewControllers objectAtIndex:1];
        _appDelegate.window.rootViewController = tabbarControler;


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
        
        [self.view hideToastActivity];
        
        [self.view makeToast:kLOGINFAILMSG];
        
        self.view.userInteractionEnabled = YES;

        
    });
}

- (IBAction)googleloginTapped:(id)sender
{
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
//    NSLog(@"userID ===%@",user.userID);
//    NSLog(@"userID givenName ===%@",user.profile.givenName);
//    NSLog(@"userID familyName ===%@",user.profile.familyName);
 
    NSLog(@"userID  name===%@",user.profile.name);
    NSLog(@"userID emil ===%@",user.profile.email);

    if ([user.profile.email rangeOfString:@"@plivo.com"].location == NSNotFound)
    {
        [[GIDSignIn sharedInstance] signOut];
        [self.view makeToast:kINVALIDEMAIL];
        self.view.userInteractionEnabled = YES;
        return;

    }
    else
    {
        
        [self.view makeToastActivity:CSToastPositionCenter];
        
        if(![UtilityClass isEmptyString:user.profile.email])
        {
            [self getSIPEndpointCredentials:user.profile.email];
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
                  
                  [UtilityClass setUserAuthenticationStatus:YES];
                  
                  NSDictionary* dict = sipArray[1];
                  
                  [[NSUserDefaults standardUserDefaults] setObject:sipArray[0] forKey:kUSERNAME];
                  [[NSUserDefaults standardUserDefaults] setObject:@"7bjbk5ib7f23ie05be2h5713hf1hl774j94c88244e2185b" forKey:kPASSWORD];
                  
                  NSMutableArray* sipContactsArray = [[NSMutableArray alloc] initWithCapacity:dict.allKeys.count];
                  
                  for(int i = 0; i < dict.allKeys.count; i++)
                  {
                      [sipContactsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:dict.allKeys[i],@"eMail",dict.allValues[i],@"endPoint", nil]];
                  }
                  
                  [[NSUserDefaults standardUserDefaults] setObject:[sipContactsArray copy] forKey:kSIPDETAILS];
                  
                  [[NSUserDefaults standardUserDefaults] synchronize];
                  
                  [[Phone sharedInstance] setDelegate:self];
                  
                  [[Phone sharedInstance] loginWithUserName:[[NSUserDefaults standardUserDefaults] objectForKey:kUSERNAME] andPassword:[[NSUserDefaults standardUserDefaults] objectForKey:kPASSWORD]];
                  
              });
              
          } failure:^(NSError *error)
         {
             NSLog(@"Error is: %@",error.description);
         }];
        
    }else
    {
        [self.view makeToast:kNOINTERNETMSG];
    }
}

@end
