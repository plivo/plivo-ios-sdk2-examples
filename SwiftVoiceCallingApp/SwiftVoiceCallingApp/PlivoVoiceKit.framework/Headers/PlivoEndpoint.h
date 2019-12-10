//
//  PlivoEndpoint.h
//  PlivoEndpoint
//
//  Copyright (c) 2015 Plivo Inc. All rights reserved.
//  Use of this software is subject to the
//  terms mentioned here, http://plivo.com/terms/

#include "PlivoIncoming.h"
#include "PlivoOutgoing.h"

typedef enum
{
    UnRegistered = 0,
    Registered
} PlivoEndpointState;

@class PlivoEndpoint;

// defining a protocol
@protocol PlivoEndpointDelegate<NSObject>

@optional
/* This delegate gets called when registration to an endpoint is successful.
 */
- (void)onLogin;

/* This delegate gets called when registration to an endpoint fails.
 This method will be deprecated, please use 'onLoginFailedWithError:'
 */
- (void)onLoginFailed;

/* This delegate gets called when registration to an endpoint fails.
 */
- (void)onLoginFailedWithError:(NSError *)error;

/**
 * This delegate gets called when endpoint logged out.
 */
- (void)onLogout;
 

/* On an incoming call to a registered endpoint, this delegate receives
 a PlivoIncoming object.
 */
- (void)onIncomingCall:(PlivoIncoming *)incoming;

/* On an incoming call, if the call is answered by the caller, this delegate
 would be triggered with the PlivoIncoming object.
 */
- (void)onIncomingCallAnswered:(PlivoIncoming *)incoming;

/* On an incoming call, if the call is disconnected by the caller, this delegate
 would be triggered with the PlivoIncoming object.
 */
- (void)onIncomingCallRejected:(PlivoIncoming *)incoming;

/* On an incoming call, if the call gets timed out, this delegate
 would be triggered.
 */
- (void)onIncomingCallInvalid:(PlivoIncoming *)incoming;

/* On an incoming call, if the call is disconnected by the caller after being answered,
 this delegate would be triggered with the PlivoIncoming object.
 */
- (void)onIncomingCallHangup:(PlivoIncoming *)incoming;

/* On an active endpoint, this delegate would be called with the digit
 received on the call.
 */
- (void)onIncomingDigit:(NSString *)digit;

/* When an outgoing call is started, this delegate would be called with
 the PlivoOutgoing object*/
- (void)onCalling:(PlivoOutgoing *)call;

/* When an outgoing call is answered, this delegate would be called with
 the PlivoOutgoing object
 */
- (void)onOutgoingCallAnswered:(PlivoOutgoing *)call;

/* When an outgoing call is ringing, this delegate would be called with
 the PlivoOutgoing object
 */
- (void)onOutgoingCallRinging:(PlivoOutgoing *)call;

/* When an outgoing call is rejected by the called number, this
 delegate would be called with the PlivoOutgoing object
 */
- (void)onOutgoingCallRejected:(PlivoOutgoing *)call;

/* When an outgoing call is made to an invalid number, this
 delagate would be called with the PlivoOutgoing object
 */
- (void)onOutgoingCallInvalid:(PlivoOutgoing *)call;

/* When an outgoing call is disconnected by the called number after the call
 has been answered
 */
- (void)onOutgoingCallHangup:(PlivoOutgoing *)call;


- (void)onFeedbackSuccess: (int) statusCode;

- (void)onFeedbackFailure: (NSError*) error;

- (void)onFeedbackValidationError:(NSString *) validationErrorMessage;

- (void)mediaMetrics:(NSDictionary *)mediaInfo;

@end


@interface PlivoEndpoint : NSObject {
    PlivoEndpointState state;
}

/* The delegate object on which events will be received.
 */
@property (nonatomic, weak) id delegate;
@property (nonatomic, readwrite) PlivoAccId accId;

/**
 * Init endpoint object.
 * It will initialize endpoint object and set debug flag to false.
 */
- (id)init;

/**
 * Init endpoint object and specify it's options like "enableTracking, debug etc."
 */
- (id)init:(NSDictionary *)initOptions;

/**
 * Init endpoint object and specify it's debug flag
 */
- (id)initWithDebug:(BOOL)isDebug __deprecated_msg("'initWithDebug:isDebug' is deprecated. Use `init:initOptions` or `init:` instead");

/**
 * Init endpoint object and specify it's debug flag and options like "enableTracking etc."
 */
- (id)initWithDebug:(BOOL)isDebug :(NSDictionary *)initOptions __deprecated_msg("'initWithDebug:isDebug:initOptions' is deprecated. Use `init:initOptions` or `init:` instead");

/* Registers an endpoint
 
 Calling this method with the username and password of your SIP endpoint would
 register the endpoint.
 */
- (void)login:(NSString *)username AndPassword:(NSString *)password;

/* Registers an endpoint with timeout in seconds
 
 Calling this method with the username, password and timeout of your SIP endpoint would
 register the endpoint.
 */
- (void)login:(NSString *)username AndPassword:(NSString *)password RegTimeout:(int)regTimeout;

/*
 
 This method is used for registering an endpoint with device token for VOIP push notifications.

 Calling this method with the username, password and device token would register the endpoint and get
 the device token from APNS and tell the PlivoVoiceKit about the push token
 
 */

- (void)login:(NSString *)username AndPassword:(NSString *)password DeviceToken:(NSData*)token;

/*
 
 This method is used for registering an endpoint with device token and certificate ID for VOIP push notifications.
 
 Calling this method with the username, password, device token and certificate ID would register the endpoint and get
 the device token from APNS and tell the PlivoVoiceKit about the push token
 
 */

- (void)login:(NSString *)username AndPassword:(NSString *)password DeviceToken:(NSData*)token CertificateId:(NSString*)certificateId;

/*
 
 This method is used to register the device token for VOIP push notifications.
 @param token
 Register for Push Notifications and get the device token from APNS and tell the PlivoVoiceKit about the push token
 
 */

- (void)registerToken:(NSData*)token __deprecated_msg("'registerToken:token' is deprecated. Use `login:username:password:token` instead");

/* 
    @param pushInfo is NSDictionary object, this is forwarded by the apple push notification.
    When the push arrives below Pushkit's delegate method will be called.
 
 */
- (void)relayVoipPushNotification:(NSDictionary *)pushinfo;

/*
  Following three apis required for the apple Callkit integration.
  Configure audio session before the call.
 */
- (void)configureAudioDevice;

/*
 Depending on the call status(Hold or Active) you’ll want to start, or stop processing the call’s audio.
 */
- (void)startAudioDevice;

/*
 Depending on the call status(Hold or Active) you’ll want to start, or stop processing the call’s audio.
 */
- (void)stopAudioDevice;

/* Send Keep Alive packet while in background mode
 */
- (void)keepAlive;

/* Unregisters an endpoint
 
 Calling this method with would unregister the SIP endpoint
 */
- (void)logout;

/* Create an Outgoing Call Object
 
 Calling this method would return an PlivoOutgoing object,
 linked to the registered endpoint. Calling this method on an unregistered PlivoEndpoint
 object would return an empty object.
 */
- (PlivoOutgoing *)createOutgoingCall;

- (void)submitCallQualityFeedback : (NSString *) callUUID : (NSInteger) startRating : (NSArray *) issues : (NSString *) notes : (Boolean) sendConsoleLog;

- (NSString *)getLastCallUUID;

- (NSString *)getCallUUID;



/* Calling this method resets the endpoint */

+ (void)resetEndpoint;


/* Notifications */
- (void)onLoginNotification;
- (void)onLoginFailedNotificationWithError:(NSError *)error;
- (void)onLogoutNotification;

- (void)onIncomingCallNotification:(PlivoIncoming *)incoming;
- (void)onIncomingCallAnsweredNotification:(PlivoIncoming *)incoming;
- (void)onIncomingCallRejectedNotification:(PlivoIncoming *)incoming;
- (void)onIncomingCallInvalidNotification:(PlivoIncoming *)incoming;
- (void)onIncomingCallHangupNotification:(PlivoIncoming *)incoming;

- (void)onIncomingDigitNotification:(NSString *)digit;

- (void)onOutgoingCallNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallRingingNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallAnsweredNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallRejectedNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallInvalidNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallHangupNotification:(PlivoOutgoing *)outgoing;
- (void)onSubmitCallQualityFeedbackSuccess : (int) statusCode;
- (void)onSubmitCallQualityFeedbackFailure : (NSError *) error;
- (void)onSubmitCallQualityFeedbackValidationError:(NSString *) errorMessage;
- (NSMutableDictionary *) validateInputs : (NSString *) callUUID : (NSInteger) rating : (NSArray *) issues : (NSString *) note;
+ (void)emitMediaMetrics:(NSString *)group :(NSString *)level :(NSString *)type :(float)value :(BOOL)active :(NSString *)desc :(NSString *)stream;
@end




