//
//  PlivoCallController.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 12/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "PlivoCallController.h"
#import "UtilityClass.h"
#import "CallInfo.h"
#import "UIView+Toast.h"
#import "Constants.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "JCDialPad.h"
#import "JCPadButton.h"
#import "MZTimerLabel.h"
#import "CallKitInstance.h"
#import <PlivoVoiceKit/PlivoVoiceKit.h>
#import <CallKit/CallKit.h>
#import <UserNotifications/UserNotifications.h>
#import <AVFoundation/AVFoundation.h>
#import <Google/SignIn.h>
#import <PushKit/PushKit.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <Crashlytics/Crashlytics.h>

@interface PlivoCallController ()<CXProviderDelegate, PKPushRegistryDelegate, CXCallObserverDelegate, JCDialPadDelegate, PlivoEndpointDelegate>
{
    BOOL isItUserAction;
    BOOL isItGSMCall;
}
@property (strong, nonatomic) JCDialPad *pad;
@property (strong, nonatomic) MZTimerLabel *timer;
@property ( nonatomic ) CXCallObserver *callObserver;
@end

@implementation PlivoCallController
{
    PlivoOutgoing *outCall;
    PlivoIncoming *incCall;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Dial pad to enter phone number or to Enter DTMF Text
    self.pad = [[JCDialPad alloc] initWithFrame:self.dialPadView.bounds];
    self.pad.buttons = [JCDialPad defaultButtons];
    self.pad.delegate = self;
    self.pad.showDeleteButton = YES;
    self.pad.formatTextToPhoneNumber = NO;
    
    self.dialPadView.backgroundColor = [UIColor whiteColor];
    [self.dialPadView addSubview:self.pad];

    self.timer = [[MZTimerLabel alloc] initWithLabel:self.callStateLabel andTimerType:MZTimerLabelTypeStopWatch];
    self.timer.timeFormat = @"HH:mm:ss";

    [[CallKitInstance sharedInstance].callKitProvider setDelegate:self queue:dispatch_get_main_queue()];
    [[CallKitInstance sharedInstance].callObserver setDelegate:self queue:dispatch_get_main_queue()];
    
    //Add Call Interruption observers
    [self addObservers];
    
    //Register with Pushkit to handle plivo calls in background
    [self voipRegistration];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [[Phone sharedInstance] setDelegate:self];
    
    [self hideActiveCallView];
    
    self.pad.buttons = [JCDialPad defaultButtons];
    [self.pad layoutSubviews];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Keypad Enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.pad layoutSubviews];

    self.pad.digitsTextField.text = @"";
    self.pad.showDeleteButton = NO;
    self.pad.rawText = @"";
    self.muteButton.enabled = NO;
    self.holdButton.enabled = NO;
    self.keypadButton.enabled = NO;

    [self hideActiveCallView];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Register for VoIP notifications
- (void)voipRegistration
{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    // Create a push registry object
    PKPushRegistry *voipResistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
    // Set the registry's delegate to self
    [voipResistry setDelegate:(id<PKPushRegistryDelegate> _Nullable)self];
    //Set the push type to VOIP
    voipResistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
}


#pragma mark - Pushkit delegates

// Handle updated push credentials
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type
{
    // Register VoIP push token (a property of PKPushCredentials) with server
    
    if(credentials.token.length == 0)
    {
        NSLog(@"VOIP token NULL");
        return;
    }
    
    NSLog(@"Credentials token: %@", credentials.token);
    
    [FIRAnalytics logEventWithName:@"PushKit"
                        parameters:@{
                                     @"Token": credentials.token
                                     }];
    [[Phone sharedInstance] registerToken:credentials.token];
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    if([type isEqualToString:PKPushTypeVoIP])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [FIRAnalytics logEventWithName:@"PushKit"
                                parameters:@{
                                             @"Payload": payload.dictionaryPayload
                                             }];
            
            [[Phone sharedInstance] relayVoipPushNotification:payload.dictionaryPayload];
            
        });
    }
}

- (void)addObservers
{
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
    
    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:[AVAudioSession sharedInstance]];
    
    // if media services are reset, we need to rebuild our audio chain
    [[NSNotificationCenter defaultCenter]	addObserver:	self
                                             selector:	@selector(handleMediaServerReset:)
                                                 name:	AVAudioSessionMediaServicesWereResetNotification
                                               object:	[AVAudioSession sharedInstance]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];

}

//To unregister with SIP Server
- (void)unRegisterSIPEndpoit
{
    [FIRAnalytics logEventWithName:@"SIPEndpointUnregister"
                        parameters:nil];
    [[Phone sharedInstance] logout];
    
}


#pragma mark - PlivoEndPoint Delegates
/**
 * onLogin delegate implementation.
 */
- (void)onLogin
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UtilityClass makeToast:kLOGINSUCCESS];
        
        [UtilityClass hideToastActivity];
        
        [[Crashlytics sharedInstance] setUserIdentifier:[[NSUserDefaults standardUserDefaults] objectForKey:kUSERNAME]];
        
    });
    NSLog(@"Ready to make a call");
    
}

/**
 * onLoginFailed delegate implementation.
 */
- (void)onLoginFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [UtilityClass makeToast:@"408:Timedout Error"];
        
        [UtilityClass hideToastActivity];

        NSLog(@"%@",kLOGINFAILMSG);

        [UtilityClass setUserAuthenticationStatus:NO];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUSERNAME];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPASSWORD];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[GIDSignIn sharedInstance] signOut];

        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        LoginViewController* loginVC = [_mainStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [[Phone sharedInstance] setDelegate:loginVC];
        
        AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        _appDelegate.window.rootViewController = loginVC;

    });
}

/**
 * onLogout delegate implementation.
 */
- (void)onLogout
{
    dispatch_async(dispatch_get_main_queue(), ^{
                
        [UtilityClass makeToast:kLOGOUTSUCCESS];
        
        [UtilityClass setUserAuthenticationStatus:NO];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUSERNAME];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPASSWORD];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[GIDSignIn sharedInstance] signOut];

        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        LoginViewController* loginVC = [_mainStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [[Phone sharedInstance] setDelegate:loginVC];
        
        AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        _appDelegate.window.rootViewController = loginVC;
        
    });
    
}

/**
 * onIncomingCall delegate implementation
 */
- (void)onIncomingCall:(PlivoIncoming *)incoming
{
    switch ([[AVAudioSession sharedInstance] recordPermission]) {
            
        case AVAudioSessionRecordPermissionGranted:
        {
            
            [FIRAnalytics logEventWithName:@"OnIncomingCall"
                                parameters:@{
                                             @"CallId": [NSString stringWithFormat:@"%@",incoming.callId],
                                             @"Account Id" : [NSString stringWithFormat:@"%d",incoming.accId],
                                             @"From" : [NSString stringWithFormat:@"%@",incoming.fromUser]
                                             }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];
                
                self.userNameTextField.text = @"";
                self.pad.digitsTextField.text = @"";
                self.pad.rawText = @"";
                
                self.callerNameLabel.text = incoming.fromUser;
                self.callStateLabel.text = @"Incoming call...";
                
            });
            
            [[CallKitInstance sharedInstance].callKitProvider setDelegate:self queue:dispatch_get_main_queue()];
            [[CallKitInstance sharedInstance].callObserver setDelegate:self queue:dispatch_get_main_queue()];
            
            [CallInfo addCallInfo:[NSDictionary dictionaryWithObjectsAndKeys:incoming.fromUser,@"CallId",[NSDate date],@"CallTime", nil]];
            
            
            //Added by Siva on Tue 11th, 2017
            if(!incCall && !outCall)
            {
                /* log it */
                NSLog(@"%@",[[NSString alloc]initWithFormat:@"Incoming Call from %@", incoming.fromContact]);
                
                /* assign incCall var */
                incCall = incoming;
                
                outCall = nil;
                
                [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
                
                NSLog(@"Incoming Call UUID IS %@",[CallKitInstance sharedInstance].callUUID);
                
                [self reportIncomingCallFrom:incoming.fromUser withUUID:[CallKitInstance sharedInstance].callUUID];
            }
            else
            {
                [FIRAnalytics logEventWithName:@"OnIncomingCallReject"
                                    parameters:@{
                                                 @"CallId": [NSString stringWithFormat:@"%@",incoming.callId],
                                                 @"Account Id" : [NSString stringWithFormat:@"%d",incoming.accId],
                                                 @"From" : [NSString stringWithFormat:@"%@",incoming.fromUser]
                                                 }];
                /*
                 * Reject the call when we already have active ongoing call
                 */
                [incoming reject];
                return;
            }
            break;
        }
        case AVAudioSessionRecordPermissionDenied:
            [UtilityClass makeToast:@"Please go to settings and turn on Microphone service for incoming/outgoing calls."];
            [incoming reject];
            break;
        case AVAudioSessionRecordPermissionUndetermined:
            // This is the initial state before a user has made any choice
            // You can use this spot to request permission here if you want
            break;
        default:
            break;
    }
}

/**
 * onIncomingCallHangup delegate implementation.
 */
- (void)onIncomingCallHangup:(PlivoIncoming *)incoming
{
    NSLog(@"- Incoming call ended");
    
    [FIRAnalytics logEventWithName:@"onIncomingCallHangup"
                        parameters:@{
                                     @"CallId": [NSString stringWithFormat:@"%@",incoming.callId],
                                     @"Account Id" : [NSString stringWithFormat:@"%d",incoming.accId],
                                     @"From" : [NSString stringWithFormat:@"%@",incoming.fromUser]
                                     }];
    
    if(incCall)
    {
        NSLog(@"Hangup Incoming call : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
        
        [self performEndCallActionWithUUID:[CallKitInstance sharedInstance].callUUID];
        
        incCall = nil;
    }
}

/**
 * onIncomingCallRejected implementation.
 */
- (void)onIncomingCallRejected:(PlivoIncoming *)incoming
{
    [FIRAnalytics logEventWithName:@"onIncomingCallRejected"
                        parameters:@{
                                     @"CallId": [NSString stringWithFormat:@"%@",incoming.callId],
                                     @"Account Id" : [NSString stringWithFormat:@"%d",incoming.accId],
                                     @"From" : [NSString stringWithFormat:@"%@",incoming.fromUser]
                                     }];
    /* log it */
    NSLog(@"Incoming call Rejected : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
    
    [self performEndCallActionWithUUID:[CallKitInstance sharedInstance].callUUID];
    
    incCall = nil;

}

/**
 * onOutgoingCallAnswered delegate implementation
 */
- (void)onOutgoingCallAnswered:(PlivoOutgoing *)call
{
    [FIRAnalytics logEventWithName:@"onOutgoingCallAnswered"
                        parameters:@{
                                     @"CallId": [NSString stringWithFormat:@"%@",call.callId],
                                     @"Account Id" : [NSString stringWithFormat:@"%d",call.accId]
                                     }];
    
    NSLog(@"- On outgoing call answered");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.muteButton.enabled = YES;
        self.keypadButton.enabled = YES;
        self.holdButton.enabled = YES;
        
        self.pad.digitsTextField.hidden = YES;
        
        if(!self.timer)
        {
            self.timer = [[MZTimerLabel alloc] initWithLabel:self.callStateLabel andTimerType:MZTimerLabelTypeStopWatch];
            self.timer.timeFormat = @"HH:mm:ss";
            [self.timer start];

        }else
        {
            [self.timer start];
            
        }
        
    });
}

/**
 * onOutgoingCallHangup delegate implementation.
 */
- (void)onOutgoingCallHangup:(PlivoOutgoing *)call
{
    [FIRAnalytics logEventWithName:@"onOutgoingCallHangup"
                        parameters:@{
                                     @"CallId": [NSString stringWithFormat:@"%@",call.callId],
                                     @"Account Id" : [NSString stringWithFormat:@"%d",call.accId]
                                     }];
    
    NSLog(@"Hangup call : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
    
    [self performEndCallActionWithUUID:[CallKitInstance sharedInstance].callUUID];
}

- (void)onCalling:(PlivoOutgoing *)call
{
    [FIRAnalytics logEventWithName:@"onOutgoingCallonCalling"
                        parameters:nil];
    NSLog(@"On Caling");
}

/**
 * onOutgoingCallRinging delegate implementation.
 */
- (void)onOutgoingCallRinging:(PlivoOutgoing *)call
{
    
    [FIRAnalytics logEventWithName:@"onOutgoingCallRinging"
                        parameters:@{
                                     @"Event" : @"onOutgoingCallRinging",
                                     @"CallId": [NSString stringWithFormat:@"%@",call.callId],
                                     }];
    
    NSLog(@"- On outgoing call ringing");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.callStateLabel.text = @"Ringing...";
        
    });
}

/**
 * onOutgoingCallrejected delegate implementation.
 */
- (void)onOutgoingCallRejected:(PlivoOutgoing *)call
{
    [FIRAnalytics logEventWithName:@"onOutgoingCallRejected"
                        parameters:@{
                                     @"CallId": [NSString stringWithFormat:@"%@",call.callId],
                                     @"Account Id" : [NSString stringWithFormat:@"%d",call.accId]
                                     }];
    
    NSLog(@"Outgoing call Rejected : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
    
    [self performEndCallActionWithUUID:[CallKitInstance sharedInstance].callUUID];
}

/**
 * onOutgoingCallInvalid delegate implementation.
 */
- (void)onOutgoingCallInvalid:(PlivoOutgoing *)call
{
    [FIRAnalytics logEventWithName:@"onOutgoingCallInvalid"
                        parameters:@{
                                     @"CallId": [NSString stringWithFormat:@"%@",call.callId],
                                     @"Account Id" : [NSString stringWithFormat:@"%d",call.accId]
                                     }];
    
    NSLog(@"- On outgoing call invalid");
    
    [self performEndCallActionWithUUID:[CallKitInstance sharedInstance].callUUID];
}

#pragma mark - CallKit Actions
//To make outgoing call
- (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle
{
    switch ([[AVAudioSession sharedInstance] recordPermission]) {
        
        case AVAudioSessionRecordPermissionGranted:
        {

            NSLog(@"Permission granted");
            
            [FIRAnalytics logEventWithName:@"performStartCallActionWithUUID"
                                parameters:@{
                                             @"NSUUID": uuid.UUIDString,
                                             @"Handle" : handle
                                             }];
            [self hideActiveCallView];
            [self unhideActiveCallView];
            
            NSLog(@"Outgoing call uuid is: %@", uuid);
            
            [[CallKitInstance sharedInstance].callKitProvider setDelegate:self queue:dispatch_get_main_queue()];
            [[CallKitInstance sharedInstance].callObserver setDelegate:self queue:dispatch_get_main_queue()];
            
            NSLog(@"provider:performStartCallActionWithUUID:");
            
            if( uuid == nil || handle == nil)
            {
                NSLog(@"UUID or Handle nil");
                return;
            }
            
            [CallInfo addCallInfo:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"CallId",[NSDate date],@"CallTime", nil]];
            
            NSString* newHandleString = [handle stringByReplacingOccurrencesOfString:@"-" withString:@""];
            
            if ([newHandleString rangeOfString:@"+91"].location == NSNotFound && newHandleString.length == 10)
            {
                newHandleString = [NSString stringWithFormat:@"+91%@",newHandleString];
            }
            
            CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:newHandleString];
            CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
            CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
            
            [[CallKitInstance sharedInstance].callKitCallController requestTransaction:transaction completion:^(NSError * _Nullable error)
             {
                 
                 if(error)
                 {
                     NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         [UtilityClass makeToast:kSTARTACTIONFAILED];
                         
                     });
                     
                 }
                 else
                 {
                     NSLog(@"StartCallAction transaction request successful");
                     
                     CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
                     callUpdate.remoteHandle = callHandle;
                     callUpdate.supportsDTMF = YES;
                     callUpdate.supportsHolding = YES;
                     callUpdate.supportsGrouping = NO;
                     callUpdate.supportsUngrouping = NO;
                     callUpdate.hasVideo = NO;
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         self.callerNameLabel.text = handle;
                         self.callStateLabel.text = @"Calling...";
                         
                         [self unhideActiveCallView];
                         
                         [[CallKitInstance sharedInstance].callKitProvider reportCallWithUUID:uuid updated:callUpdate];
                         
                     });
                     
                 }
                 
             }];
            
            break;
        }
        case AVAudioSessionRecordPermissionDenied:
            [UtilityClass makeToast:@"Please go to settings and turn on Microphone service for incoming/outgoing calls."];
            break;
        case AVAudioSessionRecordPermissionUndetermined:
            // This is the initial state before a user has made any choice
            // You can use this spot to request permission here if you want
            break;
        default:
            break;
    }
    
}

//To repot incoming call
- (void)reportIncomingCallFrom:(NSString *) from withUUID:(NSUUID *)uuid
{
    [FIRAnalytics logEventWithName:@"reportIncomingCallFrom"
                        parameters:@{
                                     @"NSUUID": uuid.UUIDString,
                                     @"from" : from
                                     }];
    
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];
    
    CXCallUpdate* callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = callHandle;
    callUpdate.supportsDTMF = YES;
    callUpdate.supportsHolding = YES;
    callUpdate.supportsGrouping = NO;
    callUpdate.supportsUngrouping = NO;
    callUpdate.hasVideo = NO;
    
    [[CallKitInstance sharedInstance].callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError * _Nullable error) {
        
        if(error)
        {
            NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
            
            [UtilityClass makeToast:kREQUESTFAILED];
            
            [[Phone sharedInstance] stopAudioDevice];
            
            if(incCall)
            {
                
                if(incCall.state != Ongoing)
                {
                    [FIRAnalytics logEventWithName:@"IncomingCallReject"
                                        parameters:@{
                                                     @"CallUUID": uuid.UUIDString,
                                                     @"from" : from
                                                     }];
                    
                    NSLog(@"Incoming call - Reject");
                    [incCall reject];
                }
                else
                {
                    [FIRAnalytics logEventWithName:@"IncomingCallHangup"
                                        parameters:@{
                                                     @"CallUUID": uuid.UUIDString,
                                                     @"from" : from
                                                     }];
                    
                    NSLog(@"Incoming call - Hangup");
                    [incCall hangup];
                }
                incCall = nil;
                
            }
            
        }
        else
        {
            [FIRAnalytics logEventWithName:@"IncomingCallSuccessfullyReported."
                                parameters:nil];
            
            NSLog(@"Incoming call successfully reported.");
            
            [[Phone sharedInstance] configureAudioSession];
            
        }
        
    }];
    
}

- (void)performEndCallActionWithUUID:(NSUUID *)uuid
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"performEndCallActionWithUUID: %@",uuid);
        
        if(uuid == nil)
        {
            NSLog(@"UUID is null return from here");
            return;
        }
        
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
        CXTransaction *trasanction = [[CXTransaction alloc] initWithAction:endCallAction];
        
        [[CallKitInstance sharedInstance].callKitCallController requestTransaction:trasanction completion:^(NSError * _Nullable error) {
            
            if(error)
            {
                NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [UtilityClass makeToast:kREQUESTFAILED];
                    
                    [[Phone sharedInstance] stopAudioDevice];
                    
                    if(incCall)
                    {
                        
                        if(incCall.state != Ongoing)
                        {
                            [FIRAnalytics logEventWithName:@"IncomingCallReject"
                                                parameters:@{
                                                             @"CallUUID": uuid.UUIDString,
                                                             @"from" : [NSString stringWithFormat:@"%@",incCall.fromUser]
                                                             }];
                            
                            NSLog(@"Incoming call - Reject");
                            [incCall reject];
                        }
                        else
                        {
                            [FIRAnalytics logEventWithName:@"IncomingCallHangup"
                                                parameters:@{
                                                             @"CallUUID": uuid.UUIDString,
                                                             @"from" : [NSString stringWithFormat:@"%@",incCall.fromUser]
                                                             }];
                            
                            NSLog(@"Incoming call - Hangup");
                            [incCall hangup];
                        }
                        incCall = nil;
                        
                    }
                    
                    if(outCall)
                    {
                        [FIRAnalytics logEventWithName:@"OutgoingCallHangup"
                                            parameters:@{
                                                         @"CallUUID": uuid.UUIDString
                                                         }];
                        
                        NSLog(@"Outgoing call - Hangup");
                        [outCall hangup];
                        outCall = nil;
                        
                    }
                    
                    self.tabBarController.tabBar.hidden = NO;
                    self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:1];
                });
            }
            else
            {
                [FIRAnalytics logEventWithName:@"EndCallActionTransactionRequestSuccessful"
                                    parameters:nil];
                NSLog(@"EndCallAction transaction request successful");
            }
            
        }];
    });
    
}

#pragma mark - CXCallObserverDelegate

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call{
    
    if (call == nil || call.hasEnded == YES) {
        NSLog(@"CXCallState : Disconnected");
    }
    
    if (call.isOutgoing == YES && call.hasConnected == NO) {
        NSLog(@"CXCallState : Dialing");
    }
    
    if (call.isOutgoing == NO  && call.hasConnected == NO && call.hasEnded == NO && call != nil) {
        NSLog(@"CXCallState : Incoming");
    }
    
    if (call.hasConnected == YES && call.hasEnded == NO) {
        NSLog(@"CXCallState : Connected");
    }
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider
{
    NSLog(@"ProviderDidReset");
}

- (void)providerDidBegin:(CXProvider *)provider
{
    NSLog(@"providerDidBegin");
    
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession
{
    NSLog(@"provider:didActivateAudioSession");
    
    [[Phone sharedInstance] startAudioDevice];
    
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession
{
    NSLog(@"provider:didDeactivateAudioSession:");
    
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action
{
    NSLog(@"provider:timedOutPerformingAction:");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action
{
    NSLog(@"provider:performStartCallAction:");
    
    [FIRAnalytics logEventWithName:@"PerformStartCallAction"
                        parameters:nil];
    
    [[Phone sharedInstance] configureAudioSession];
    
    //Set extra headers
    NSDictionary * extraHeaders = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   @"Value1", @"X-PH-Header1",
                                   @"Value2", @"X-PH-Header2",
                                   nil];
    
    NSString *dest = action.handle.value;
    
    NSLog(@"%@",[[NSString alloc]initWithFormat:@"- Make a call to '%@'", dest]);
    
    //Make the call
    outCall = [[Phone sharedInstance] callWithDest:dest andHeaders:extraHeaders];
    
    if(outCall)
    {
        [action fulfillWithDateStarted:[NSDate date]];

    }
    else
    {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action
{
    if(action.onHold)
    {
        [[Phone sharedInstance] stopAudioDevice];
        
    }
    else
    {
        [[Phone sharedInstance] startAudioDevice];
        
    }
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action
{
    
    if(action.muted)
    {
        [self.muteButton setImage:[UIImage imageNamed:@"Unmute.png"] forState:UIControlStateNormal];
        
        if(incCall)
        {
            [incCall unmute];
        }
        
        if(outCall)
        {
            [outCall unmute];
        }
        
    }
    else
    {
        [self.muteButton setImage:[UIImage imageNamed:@"MuteIcon.png"] forState:UIControlStateNormal];
        
        if(incCall)
        {
            [incCall mute];
        }
        
        if(outCall)
        {
            [outCall mute];
        }
        
    }
    
}


- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action
{
    [FIRAnalytics logEventWithName:@"performAnswerCallAction"
                        parameters:nil];
    
    NSLog(@"provider:performAnswerCallAction:");
    
    //Answer the call
    
    if(incCall)
    {
        [CallKitInstance sharedInstance].callUUID = [action callUUID];

        [incCall answer];
        
    }
    
    outCall = nil;
    
    [action fulfill];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self unhideActiveCallView];
        
        self.muteButton.enabled = YES;
        self.holdButton.enabled = YES;
        self.keypadButton.enabled = YES;

        if(!self.timer)
        {
            self.timer = [[MZTimerLabel alloc] initWithLabel:self.callStateLabel andTimerType:MZTimerLabelTypeStopWatch];
            self.timer.timeFormat = @"HH:mm:ss";
            [self.timer start];
            
        }else
        {
            [self.timer start];
            
        }        
    });
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action
{
    NSLog(@"provider:performPlayDTMFCallAction:");
    
    [FIRAnalytics logEventWithName:@"performPlayDTMFCallAction"
                        parameters:nil];

    NSString* dtmfDigits = action.digits;
    
    if(incCall)
    {
        [incCall sendDigits:dtmfDigits];
    }
    
    if(outCall)
    {
        [outCall sendDigits:dtmfDigits];
    }
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action
{
    
    NSLog(@"%@ -- %@",[CallKitInstance sharedInstance].callUUID,action.callUUID);
    
    if(!isItGSMCall || isItUserAction)
    {
        [FIRAnalytics logEventWithName:@"performEndCallAction"
                            parameters:nil];
        
        NSLog(@"provider:performEndCallAction:");
        
        [[Phone sharedInstance] stopAudioDevice];
        
        if(incCall)
        {
            
            if(incCall.state != Ongoing)
            {
                NSLog(@"Incoming call - Reject");
                [incCall reject];
            }
            else
            {
                NSLog(@"Incoming call - Hangup");
                [incCall hangup];
            }
            incCall = nil;
            
        }
        
        if(outCall)
        {
            NSLog(@"Outgoing call - Hangup");
            [outCall hangup];
            outCall = nil;
            
        }
        
        [action fulfill];
        
        isItUserAction = NO;
        
        self.tabBarController.tabBar.hidden = NO;
        self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:1];
        
    }
    else
    {
        [FIRAnalytics logEventWithName:@"performEndCallAction"
                            parameters:nil];
        
        NSLog(@"GSM - provider:performEndCallAction:");
        
    }
}

#pragma mark - Handling IBActions

- (IBAction)callButtonTapped:(id)sender
{
    
    switch ([[AVAudioSession sharedInstance] recordPermission]) {
            
        case AVAudioSessionRecordPermissionGranted:
        {
            
            if((![self.userNameTextField.text isEqualToString:@"SIP URI or Phone Number"] && ![UtilityClass isEmptyString:self.userNameTextField.text]) || ![UtilityClass isEmptyString:self.pad.digitsTextField.text] || incCall || outCall )
            {
                [FIRAnalytics logEventWithName:@"MakeCallButtonTapped"
                                    parameters:nil];
                
                UIImage *img = [sender imageForState:UIControlStateNormal];
                NSData *data1 = UIImagePNGRepresentation(img);
                if ([data1  isEqual:UIImagePNGRepresentation([UIImage imageNamed:@"MakeCall.png"])])
                {
                    
                    self.callStateLabel.text = @"Calling...";
                    self.callerNameLabel.text = self.pad.digitsTextField.text;
                    
                    [self unhideActiveCallView];
                    
                    NSString* handle;
                    
                    if(![self.pad.digitsTextField.text isEqualToString:@""])
                    {
                        handle = self.pad.digitsTextField.text;
                        
                    }else if(![self.userNameTextField.text isEqualToString:@""])
                    {
                        handle = self.userNameTextField.text;
                        
                    }else
                    {
                        
                        [UtilityClass makeToast:kINVALIDSIPENDPOINTMSG];
                        
                        return;
                        
                    }
                    
                    self.userNameTextField.text = @"";
                    self.pad.digitsTextField.text = @"";;
                    self.pad.rawText = @"";
                    
                    [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
                    /* outgoing call */
                    [self performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:handle];
                    
                }
                else if ([data1  isEqual: UIImagePNGRepresentation([UIImage imageNamed:@"EndCall.png"])])
                {
                    [FIRAnalytics logEventWithName:@"EndCallButtonTapped"
                                        parameters:nil];
                    isItUserAction = YES;
                    [self performEndCallActionWithUUID:[CallKitInstance sharedInstance].callUUID];
                    
                }
            }else
            {
                [UtilityClass makeToast:kINVALIDSIPENDPOINTMSG];
                
            }
            break;
        }
        case AVAudioSessionRecordPermissionDenied:
        {
            [UtilityClass makeToast:@"Please go to settings and turn on Microphone service for incoming/outgoing calls."];
            break;
        }
        case AVAudioSessionRecordPermissionUndetermined:
            // This is the initial state before a user has made any choice
            // You can use this spot to request permission here if you want
            break;
        default:
            break;
            
    }
}

/*
 * Display Dial pad to enter DTMF text
 * Hide Mute/Unmute button
 * Hide Hold/Unhold button
 */

- (IBAction)keypadButtonTapped:(id)sender
{
    [FIRAnalytics logEventWithName:@"KeypadButtonTapped"
                        parameters:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Keypad Enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.holdButton.hidden = YES;
    self.muteButton.hidden = YES;
    self.keypadButton.hidden = YES;
    self.hideButton.hidden = NO;
    self.activeCallImageView.hidden = YES;
    self.userNameTextField.text = @"";
    [self.view bringSubviewToFront:self.hideButton];
    
    self.userNameTextField.hidden = NO;
    self.userNameTextField.textColor = [UIColor whiteColor];
    
    self.dialPadView.hidden = NO;
    [self.dialPadView setBackgroundColor:[UIColor colorWithRed:0.0/255.0 green:75.0/255.0 blue:58.0/255.0 alpha:1.0]];

    self.dialPadView.alpha = 0.7;
    self.pad.buttons = [JCDialPad defaultButtons];
    [self.pad layoutSubviews];
    
    self.callerNameLabel.hidden = YES;
    self.callStateLabel.hidden = YES;
    
}

/*
 * Hide Dial pad view
 * UnHide Mute/Unmute button
 * UnHide Hold/Unhold button
 */
- (IBAction)hideButtonTapped:(id)sender;
{
    [FIRAnalytics logEventWithName:@"HideButtonTapped"
                        parameters:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Keypad Enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.holdButton.hidden = NO;
    self.muteButton.hidden = NO;
    self.keypadButton.hidden = NO;
    self.dialPadView.hidden = YES;
    self.hideButton.hidden = YES;
    self.activeCallImageView.hidden = NO;
    
    self.userNameTextField.hidden = YES;
    self.userNameTextField.textColor = [UIColor darkGrayColor];

    self.pad.rawText = @"";

    self.callerNameLabel.hidden = NO;
    self.callStateLabel.hidden = NO;
    
    [self.dialPadView setBackgroundColor:[UIColor whiteColor]];
    self.pad.buttons = [JCDialPad defaultButtons];
    [self.pad layoutSubviews];

}


/*
 * Mute/Unmute calls
 */
- (IBAction)muteButtonTapped:(id)sender
{
    
    UIImage *img = [sender imageForState:UIControlStateNormal];
    NSData *data1 = UIImagePNGRepresentation(img);
    if ([data1  isEqual:UIImagePNGRepresentation([UIImage imageNamed:@"Unmute.png"])])
    {
        [FIRAnalytics logEventWithName:@"MuteButtonTapped"
                            parameters:nil];
        
        [self.muteButton setImage:[UIImage imageNamed:@"MuteIcon.png"] forState:UIControlStateNormal];
        
        if(incCall)
        {
            [incCall mute];
        }
        
        if(outCall)
        {
            [outCall mute];
        }

    }
    else
    {
        [FIRAnalytics logEventWithName:@"UnmuteButtonTapped"
                            parameters:nil];
        
        [self.muteButton setImage:[UIImage imageNamed:@"Unmute.png"] forState:UIControlStateNormal];

        if(incCall)
        {
            [incCall unmute];
        }
        
        if(outCall)
        {
            [outCall unmute];
        }

    }
}

/*
 * Hold/Unhold calls
 */
- (IBAction)holdButtonTapped:(id)sender
{
    UIImage *img = [sender imageForState:UIControlStateNormal];
    NSData *data1 = UIImagePNGRepresentation(img);

    if ([data1  isEqual:UIImagePNGRepresentation([UIImage imageNamed:@"UnholdIcon.png"])])
    {
        [FIRAnalytics logEventWithName:@"HoldButtonTapped"
                            parameters:nil];
        
        [self.holdButton setImage:[UIImage imageNamed:@"HoldIcon.png"] forState:UIControlStateNormal];
        
        if(incCall)
        {
            [incCall hold];
        }
        
        if(outCall)
        {
            [outCall hold];
        }

        [[Phone sharedInstance] stopAudioDevice];
        

    }
    else
    {
        [FIRAnalytics logEventWithName:@"UnholdButtonTapped"
                            parameters:nil];
        
        [self.holdButton setImage:[UIImage imageNamed:@"UnholdIcon.png"] forState:UIControlStateNormal];
        
        if(incCall)
        {
            [incCall unhold];
        }
        
        if(outCall)
        {
            [outCall unhold];
        }

        [[Phone sharedInstance] startAudioDevice];
        

    }

}

/*
 * Will be called when app terminates
 * End on going calls(If any)
 */
- (void)appWillTerminate
{
    [FIRAnalytics logEventWithName:@"AppWillTerminate"
                        parameters:nil];
    
    [self performEndCallActionWithUUID:[CallKitInstance sharedInstance].callUUID];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    if(touch.phase == UITouchPhaseBegan)
    {
        [self.userNameTextField resignFirstResponder];
    }
}


- (void)hideActiveCallView
{
    self.callerNameLabel.hidden = YES;
    self.callStateLabel.hidden = YES;
    self.activeCallImageView.hidden = YES;
    self.muteButton.hidden = YES;
    self.keypadButton.hidden = YES;
    self.holdButton.hidden = YES;
    
    self.dialPadView.hidden = NO;
    self.userNameTextField.hidden = NO;
    self.userNameTextField.enabled = YES;
    self.pad.digitsTextField.hidden = NO;
    self.pad.showDeleteButton = YES;
    self.pad.rawText = @"";
    
    self.userNameTextField.text = @"SIP URI or Phone Number";
    self.tabBarController.tabBar.hidden = NO;
    
    [self.callButton setImage:[UIImage imageNamed:@"MakeCall.png"] forState:UIControlStateNormal];
    
    [self.timer reset];
    [self.timer removeFromSuperview];
    self.timer = nil;
    
    self.callStateLabel.text = @"Calling...";
    
    self.dialPadView.alpha = 1.0;
    self.dialPadView.backgroundColor = [UIColor whiteColor];

}

- (void)unhideActiveCallView
{
    self.callerNameLabel.hidden = NO;
    self.callStateLabel.hidden = NO;
    self.activeCallImageView.hidden = NO;
    
    self.muteButton.hidden = NO;
    self.keypadButton.hidden = NO;
    self.holdButton.hidden = NO;

    self.dialPadView.hidden = YES;
    self.userNameTextField.hidden = YES;
    self.pad.digitsTextField.hidden = YES;
    self.pad.showDeleteButton = NO;
    
    self.tabBarController.tabBar.hidden = YES;

    [self.callButton setImage:[UIImage imageNamed:@"EndCall.png"] forState:UIControlStateNormal];
}

/*
 * Handle audio interruptions
 * AVAudioSessionInterruptionTypeBegan
 * AVAudioSessionInterruptionTypeEnded
 */
- (void)handleInterruption:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        @try {
            
            UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
            
            NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
            
            if (theInterruptionType == AVAudioSessionInterruptionTypeBegan)
            {
                NSLog(@"isItGSMCall = YES");
                isItGSMCall = YES;
                [[Phone sharedInstance] stopAudioDevice];
                
                NSLog(@"----------AVAudioSessionInterruptionTypeBegan-------------");
                
                [FIRAnalytics logEventWithName:@"AVAudioSessionInterruptionTypeBegan"
                                    parameters:nil];
            }
            
            if (theInterruptionType == AVAudioSessionInterruptionTypeEnded)
            {
                NSLog(@"isItGSMCall = NO");

                isItGSMCall = NO;
                // make sure to activate the session
                NSError *error = nil;
                [[AVAudioSession sharedInstance] setActive:YES error:&error];
                if (nil != error) NSLog(@"AVAudioSession set active failed with error: %@", error);
                
                [[Phone sharedInstance] startAudioDevice];
                
                NSLog(@"----------AVAudioSessionInterruptionTypeEnded-------------");
                
                [FIRAnalytics logEventWithName:@"AVAudioSessionInterruptionTypeEnded"
                                    parameters:nil];
                
            }
            
        }
        @catch (NSException *exception)
        {
            [FIRAnalytics logEventWithName:@"AVAudioSessionInterruption"
                                parameters:@{
                                             @"Error": exception.description
                                             }];
            
            NSLog(@"Exception: %@",exception.description);
            
        }
        @finally {
            
        }
        
    });
    
}


- (void)handleRouteChange:(NSNotification *)notification
{
    
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue)
    {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
    
    [FIRAnalytics logEventWithName:@"AudioRouteChange"
                        parameters:nil];
}

- (void)handleMediaServerReset:(NSNotification *)notification
{
    NSLog(@"Media server has reset");
    
    // rebuild the audio chain
    [[Phone sharedInstance] configureAudioSession];
    [[Phone sharedInstance] startAudioDevice];
    
    [FIRAnalytics logEventWithName:@"HandleMediaServerReset"
                        parameters:nil];

}

#pragma mark - JCDialPadDelegates

- (BOOL)dialPad:(JCDialPad *)dialPad shouldInsertText:(NSString *)text forButtonPress:(JCPadButton *)button
{
    
    if(!incCall && !outCall)
    {
        self.userNameTextField.enabled = NO;
        self.userNameTextField.text = @"";
        
    }
    
    return YES;
}

- (BOOL)dialPad:(JCDialPad *)dialPad shouldInsertText:(NSString *)text forLongButtonPress:(JCPadButton *)button
{
    
    if(!incCall && !outCall)
    {
        self.userNameTextField.text = @"";
        self.userNameTextField.enabled = NO;
    }

    return YES;
}

- (void)getDtmfText:(NSString *)dtmfText withAppendStirng:(NSString*)appendText
{
    [FIRAnalytics logEventWithName:@"DTMFTextHandling"
                        parameters:nil];
    
    if(incCall)
    {
        [incCall sendDigits:dtmfText];
        self.userNameTextField.text = appendText;
    }
    
    if(outCall)
    {
        [outCall sendDigits:dtmfText];
        self.userNameTextField.text = appendText;
    }
}

#pragma mark - Handling TextField
/**
 * Hide keyboard after user press 'return' key
 */
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if (theTextField == self.userNameTextField)
    {
        [theTextField resignFirstResponder];
    }
    return YES;
}

/**
 * Hide keyboard when text filed being clicked
 */
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField       // return NO to disallow editing.
{
    self.userNameTextField.text = @"";
    return YES;
}
@end
