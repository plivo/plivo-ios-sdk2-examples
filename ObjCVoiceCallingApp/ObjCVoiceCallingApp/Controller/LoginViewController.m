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
#import "UIView+Toast.h"
#import "PlivoCallController.h"
#import <Crashlytics/Crashlytics.h>

@interface LoginViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *userNameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)loginButtonTapped:(id)sender;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.loginButton.layer.cornerRadius = DEVICE_HEIGHT * 0.04401408451;

    self.userNameTextField.delegate = self;
    self.passwordTextField.delegate = self;

}

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:YES];
    
    [self.userNameTextField setValue:[UIColor whiteColor]
                     forKeyPath:@"_placeholderLabel.textColor"];
    [self.passwordTextField setValue:[UIColor whiteColor]
                 forKeyPath:@"_placeholderLabel.textColor"];

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
    return YES;

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
            
            self.userNameTextField.delegate = nil;
            self.passwordTextField.delegate = nil;
            
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

        [UtilityClass setUserAuthenticationStatus:YES];

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

        }
        

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
        
        self.userNameTextField.delegate = self;
        self.passwordTextField.delegate = self;
        
        [UtilityClass hideToastActivity];
        
        [UtilityClass makeToast:kLOGINFAILMSG];
        
        self.view.userInteractionEnabled = YES;

        
    });
}

@end
