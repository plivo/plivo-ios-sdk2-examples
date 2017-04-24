//
//  PlivoCallController.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 12/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Phone.h"

@interface PlivoCallController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *callerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStateLabel;
@property (weak, nonatomic) IBOutlet UIView *dialPadView;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *hideButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *holdButton;
@property (weak, nonatomic) IBOutlet UIButton *keypadButton;
@property (weak, nonatomic) IBOutlet UIImageView* activeCallImageView;

- (IBAction)callButtonTapped:(id)sender;
- (IBAction)hideButtonTapped:(id)sender;
- (IBAction)muteButtonTapped:(id)sender;
- (IBAction)holdButtonTapped:(id)sender;
- (IBAction)keypadButtonTapped:(id)sender;

- (void)onIncomingCall:(PlivoIncoming *)incoming;
- (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle;
- (void)unRegisterSIPEndpoit;
@end
