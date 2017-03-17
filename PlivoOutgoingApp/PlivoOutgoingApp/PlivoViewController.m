//
//  PlivoViewController.m
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import "PlivoViewController.h"
#import "PlivoAppDelegate.h"

#import <AVFoundation/AVFoundation.h>

@interface PlivoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *callBtn;
@property (weak, nonatomic) IBOutlet UIButton *hangupBtn;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) CXProvider *callKitProvider;
@property (nonatomic, strong) CXCallController *callKitCallController;
@property (nonatomic, strong) NSUUID *uuid;


- (IBAction)makeCall:(id)sender;
- (IBAction)hangupCall:(id)sender;


@end

@implementation PlivoViewController {
    PlivoOutgoing *outCall;
    PlivoIncoming *incCall;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /** 
     * Disable call & hangup button.
     * We will enable it after it succesfully logged in.
     */
    [self.hangupBtn setEnabled:NO];
    [self.callBtn setEnabled:NO];
    [self.textField setEnabled:NO];
    
    /* set delegate for debug log text view */
    self.logTextView.delegate = self;
    
    /* Login */
    [self.logTextView setText:@"- Logging in\n"];
    [self voipRegistration];
    [self configureCallKit];
    [self.phone login];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Hide keyboard after user press 'return' key
 */
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.textField) {
        [theTextField resignFirstResponder];
    }
    return YES;
}

/**
 * Hide keyboard when text view being clicked
 */
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}


/**
 * Print debug log to textview in the bottom of the view screen
 */
- (void)logDebug:(NSString *)message
{
    /**
     * Check if this code is executed from main thread.
     * Only main thread that can update the GUI.
     * Our plivo endpoint run in it's own thread
     */
    if ( ![NSThread isMainThread] )
	{
        /* if it is not executed from main thread, give this to main thread and return */
        [self performSelectorOnMainThread:@selector(logDebug:) withObject:message waitUntilDone:NO];
		return;
	}
    /* add newline to end of the message */
    NSString *toLog = [[NSString alloc] initWithFormat:@"%@\n",message];
    
    /* insert message */
    [self.logTextView insertText:toLog];
    
	/* Scroll textview */
	[self.logTextView scrollRangeToVisible:NSMakeRange([self.logTextView.text length], 0)];
}


/**
 * onLogin delegate implementation.
 */
- (void)onLogin
{
    [self logDebug:@"- Login OK"];
    [self logDebug:@"- Ready to make a call"];
    [self enableCallDisableHangup];
}

/**
 * onLoginFailed delegate implementation.
 */
- (void)onLoginFailed
{
    [self logDebug:@"- Login failed. Please check your username and password"];
}

/**
 * Make a call
 */
- (IBAction)makeCall:(id)sender {
    /* get destination value */
    NSString *dest = [self.textField text];
    
    /* check if user already entered the destinantion number */
    if (dest.length == 0) {
        [self logDebug:@"- Please enter SIP URI or Phone Number"];
        return;
    }
 
    /* outgoing call */
    self.uuid = [NSUUID UUID];
    NSString *handle = dest;
    
    [self performStartCallActionWithUUID:self.uuid handle:handle];
    
    NSLog(@"UUID IS %@",self.uuid);
}

/**
 * Hangup the call
 */
- (IBAction)hangupCall:(id)sender {
    /* log it */
    [self logDebug:@"- Hangup the call"];
    
    NSLog(@"Hangup call : UUID IS %@",self.uuid);

    [self performEndCallActionWithUUID:self.uuid];
}

/**
 * Enable call UI and disable hangup UI
 */
- (void)enableCallDisableHangup
{
    [self.hangupBtn setEnabled:NO];
    [self.callBtn setEnabled:YES];
    [self.textField setEnabled:YES];
}

/**
 * Enable hangup UI and disable call UI
 */
- (void)enableHangupDisableCall
{
    [self.hangupBtn setEnabled:YES];
    [self.callBtn setEnabled:NO];
    [self.textField setEnabled:NO];
}

/**
 * onIncomingCall delegate implementation
 */
- (void)onIncomingCall:(PlivoIncoming *)incoming
{
    /* display caller name in call status label */
    NSLog(@"Incoming call from %@",incoming.fromContact);
    
    /* log it */
    NSString *logMsg = [[NSString alloc]initWithFormat:@"- Call from %@", incoming.fromContact];
    [self logDebug:logMsg];
    
    /* assign incCall var */
    incCall = incoming;
    
    outCall = nil;
    
    /* enable answer & hangup button */
    [self.hangupBtn setEnabled:YES];
    
    /* print extra header */
    if (incoming.extraHeaders.count > 0) {
        [self logDebug:@"- Extra headers:"];
        for (NSString *key in incoming.extraHeaders) {
            NSString *val = [incoming.extraHeaders objectForKey:key];
            NSString *keyVal = [[NSString alloc] initWithFormat:@"-- %@ => %@", key, val];
            [self logDebug:keyVal];
        }
    }
    
    self.uuid = [NSUUID UUID];
    
    NSLog(@"Incoming Call UUID IS %@",self.uuid);
    
    [self reportIncomingCallFrom:incoming.fromUser withUUID:self.uuid];
}

/**
 * onIncomingCallHangup delegate implementation.
 */
- (void)onIncomingCallHangup:(PlivoIncoming *)incoming
{
    /* log it */
    [self logDebug:@"- Incoming call ended"];
    
    if(incCall){
        NSLog(@"Hangup Incoming call : UUID IS %@",self.uuid);
        [self performEndCallActionWithUUID:self.uuid];
        incCall = nil;
    }
}

/**
 * onIncomingCallRejected implementation.
 */
- (void)onIncomingCallRejected:(PlivoIncoming *)incoming
{
    /* log it */
    [self logDebug:@"- Incoming call rejected"];
    
    NSLog(@"Incoming call Rejected : UUID IS %@",self.uuid);
    
    incCall = nil;
    
    [self performEndCallActionWithUUID:self.uuid];
    
}

/**
 * onOutgoingCallAnswered delegate implementation
 */
- (void)onOutgoingCallAnswered:(PlivoOutgoing *)call
{
    [self logDebug:@"- On outgoing call answered"];
}

/**
 * onOutgoingCallHangup delegate implementation.
 */
- (void)onOutgoingCallHangup:(PlivoOutgoing *)call
{
    [self logDebug:@"- On outgoing call hangup"];
    
    NSLog(@"Hangup call : UUID IS %@",self.uuid);
    
    [self performEndCallActionWithUUID:self.uuid];
}

/**
 * onCalling delegate implementation.
 */
- (void)onCalling:(PlivoOutgoing *)call
{
    [self logDebug:@"- On calling"];
}

/**
 * onOutgoingCallRinging delegate implementation.
 */
- (void)onOutgoingCallRinging:(PlivoOutgoing *)call
{
    [self logDebug:@"- On outgoing call ringing"];
}

/**
 * onOutgoingCallrejected delegate implementation.
 */
- (void)onOutgoingCallRejected:(PlivoOutgoing *)call
{
    [self logDebug:@"- On outgoing call rejected"];
    
    NSLog(@"Outgoing call Rejected : UUID IS %@",self.uuid);
    
    [self performEndCallActionWithUUID:self.uuid];
}

/**
 * onOutgoingCallInvalid delegate implementation.
 */
- (void)onOutgoingCallInvalid:(PlivoOutgoing *)call
{
    [self logDebug:@"- On outgoing call invalid"];
    
    [self enableCallDisableHangup];
    
    [self performEndCallActionWithUUID:self.uuid];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)configureCallKit {
    CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"CallKit Quickstart"];
    configuration.maximumCallGroups = 1;
    configuration.maximumCallsPerCallGroup = 1;
    
    self.callKitProvider = [[CXProvider alloc] initWithConfiguration:configuration];
    [self.callKitProvider setDelegate:self queue:nil];
    
    self.callKitCallController = [[CXCallController alloc] init];
}


// Register for VoIP notifications
- (void) voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // Create a push registry object
    PKPushRegistry *  _voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    // Set the registry's delegate to self
    [_voipRegistry setDelegate:(id<PKPushRegistryDelegate> _Nullable)self];
    // Set the push type to VoIP
    _voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

// Handle updated push credentials
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type {
    // Register VoIP push token (a property of PKPushCredentials) with server
    
    if([credentials.token length] == 0) {
        NSLog(@"voip token NULL");
        return;
    }
    NSLog(@"Credentials Token : %@",credentials.token);
    [self.phone registerToken:credentials.token];
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    if ([type isEqualToString:PKPushTypeVoIP]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.phone relayVoipPushNotification:payload.dictionaryPayload];
        });
    }
}

#pragma mark - CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"providerDidReset:");
}

- (void)providerDidBegin:(CXProvider *)provider {
    NSLog(@"providerDidBegin:");
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didActivateAudioSession:");
    [self.phone startAudioDevice];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didDeactivateAudioSession:");
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    NSLog(@"provider:timedOutPerformingAction:");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"provider:performStartCallAction:");
    
    [self.phone configureAudioSession];
    
    /* set extra headers */
    NSDictionary *extraHeaders = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  @"Value1", @"X-PH-Header1",
                                  @"Value2", @"X-PH-Header2",
                                  nil];
    
    NSString *dest = action.handle.value;
    
    NSString *debugStr = [[NSString alloc]initWithFormat:@"- Make a call to '%@'", dest];
    [self logDebug:debugStr];
    
    /* make the call */
    outCall = [self.phone callWithDest:dest andHeaders:extraHeaders];
    
    /* enable hangup and disable call*/
    [self enableHangupDisableCall];
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"provider:performAnswerCallAction:");
    /* answer the call */
    if (incCall) {
        [incCall answer];
        self.uuid = [action callUUID];
    }

    outCall = nil;
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action{
    NSString *dtmfDigits = action.digits;
    
    if (incCall){
        [incCall sendDigits:dtmfDigits];
    }
    
    if (outCall){
        [outCall sendDigits:dtmfDigits];
    }
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"provider:performEndCallAction:");
    
    [self.phone stopAudioDevice];

    if (incCall){
        [incCall hangup];
        incCall = nil;
    }
    
    if (outCall){
        /* hang it up */
        [outCall hangup];
        outCall = nil;
    }
    
    /* disable hangup and enable call*/
    [self enableCallDisableHangup];
    
    [action fulfill];
}

#pragma mark - CallKit Actions
- (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle {
    NSLog(@"provider:performStartCallActionWithUUID:");
    
    if (uuid == nil || handle == nil) {
        return;
    }
    
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:handle];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
    
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
        } else {
            NSLog(@"StartCallAction transaction request successful");
            
            CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
            callUpdate.remoteHandle = callHandle;
            callUpdate.supportsDTMF = YES;
            callUpdate.supportsHolding = NO;
            callUpdate.supportsGrouping = NO;
            callUpdate.supportsUngrouping = NO;
            callUpdate.hasVideo = NO;
            
            [self.callKitProvider reportCallWithUUID:uuid updated:callUpdate];
        }
    }];
}

- (void)reportIncomingCallFrom:(NSString *) from withUUID:(NSUUID *)uuid {
    NSLog(@"provider:reportIncomingCallFrom:");
    
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = callHandle;
    callUpdate.supportsDTMF = YES;
    callUpdate.supportsHolding = NO;
    callUpdate.supportsGrouping = NO;
    callUpdate.supportsUngrouping = NO;
    callUpdate.hasVideo = NO;
    
    [self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError *error) {
        if (!error) {
            NSLog(@"Incoming call successfully reported.");
            [self.phone configureAudioSession];
        }
        else {
            NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
        }
    }];
}

- (void)performEndCallActionWithUUID:(NSUUID *)uuid {
    NSLog(@"provider:performEndCallActionWithUUID: %@",uuid);
    
    if (uuid == nil) {
        NSLog(@"UUID is null return from here");
        return;
    }
    
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
    
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
        }
        else {
            NSLog(@"EndCallAction transaction request successful");
        }
    }];
}

@end
