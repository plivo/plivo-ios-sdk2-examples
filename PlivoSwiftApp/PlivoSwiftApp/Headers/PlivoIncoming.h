//
//  PlivoIncoming.h
//  PlivoEndpoint
//
//  Copyright (c) 2015 Plivo Inc. All rights reserved.
//  Use of this software is subject to the
//  terms mentioned here, http://plivo.com/terms/

#import "PlivoCall.h"

@interface PlivoIncoming : NSObject

/* The accId of the registered Endpoint */
@property (nonatomic, readwrite) PlivoAccId accId;

/* The callId of the call */
@property (nonatomic, readwrite) NSString *callId;

/* The number/SIP URI from which the call is being received */
@property (nonatomic, readwrite) NSString *fromContact;

/* The SIP URI on which the call is being received */
@property (nonatomic, readwrite) NSString *toContact;

/* Extra headers */
@property NSDictionary *extraHeaders;

/* Whether the call is muted */
@property (nonatomic, readonly) BOOL muted;

/* State of the call */
@property (nonatomic, readwrite) PlivoCallState state;


/* Answers the call
 
 Calling this method on the PlivoIncoming object would answer the call.
 */
- (void)answer;

/* Mutes the call
 
 Calling this method on the PlivoIncoming object would mute the call.
 */
- (void)mute;

/* Unmute the call
 
 Calling this method on the PlivoIncoming object would unmute the call.
 */
- (void)unmute;

/* Send DTMF
 
 Calling this method on the PlivoIncoming object with the digits
 would send DTMF on that call.
 */
- (void)sendDigits:(NSString *)digits;

/* Disconnect the call
 
 Calling this method on the PlivoIncoming object would disconnect the call.
 */
- (void)hangup;

/* Rejects the call
 
 Calling this method on the PlivoIncoming object would reject the call.
 */
- (void)reject;

@end
