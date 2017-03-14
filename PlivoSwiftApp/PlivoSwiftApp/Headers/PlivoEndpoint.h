//
//  PlivoEndpoint.h
//  PlivoEndpoint
//
//  Copyright (c) 2015 Plivo Inc. All rights reserved.
//  Use of this software is subject to the
//  terms mentioned here, http://plivo.com/terms/

#include "PlivoIncoming.h"
#include "PlivoOutgoing.h"
#include "PlivoRest.h"

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
 */
- (void)onLoginFailed;

/**
 * This delegate gets called when endpoint logged out.
 */
- (void)onLogout;
 

/* On an incoming call to a registered endpoint, this delegate receives
 a PlivoIncoming object.
 */
- (void)onIncomingCall:(PlivoIncoming *)incoming;

/* On an incoming call, if the call is disconnected by the caller, this delegate
 would be triggered with the PlivoIncoming object.
 */
- (void)onIncomingCallRejected:(PlivoIncoming *)incoming;

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


@end


@interface PlivoEndpoint : NSObject {
    PlivoEndpointState state;
}

/* The delegate object on which events will be received.
 */
@property (nonatomic, assign) id delegate;
@property (nonatomic, readwrite) PlivoAccId accId;

/**
 * Init endpoint object.
 * It will initialize endpoint object and set debug flag to false.
 */
- (id)init;

/**
 * Init endpoint object and specify it's debug flag
 */
- (id)initWithDebug:(BOOL)isDebug;

/* Registers an endpoint
 
 Calling this method with the username and password of your SIP endpoint would
 register the endpoint.
 */
- (void)login:(NSString *)username AndPassword:(NSString *)password;

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

/* Calling this method resets the endpoint */

+ (void)resetEndpoint;


/* Notifications */
- (void)onLoginNotification;
- (void)onLoginFailedNotification;
- (void)onLogoutNotification;

- (void)onIncomingCallNotification:(PlivoIncoming *)incoming;
- (void)onIncomingCallRejectedNotification:(PlivoIncoming *)incoming;
- (void)onIncomingCallHangupNotification:(PlivoIncoming *)incoming;

- (void)onIncomingDigitNotification:(NSString *)digit;

- (void)onOutgoingCallNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallRingingNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallAnsweredNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallRejectedNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallInvalidNotification:(PlivoOutgoing *)outgoing;
- (void)onOutgoingCallHangupNotification:(PlivoOutgoing *)outgoing;

@end




