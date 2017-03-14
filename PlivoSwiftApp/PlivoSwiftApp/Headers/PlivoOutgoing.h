//
//  PlivoOutgoing.h
//  PlivoEndpoint
//
//  Copyright (c) 2015 Plivo Inc. All rights reserved.
//  Use of this software is subject to the
//  terms mentioned here, http://plivo.com/terms/

#import "PlivoCall.h"

@interface PlivoOutgoing : NSObject

/* The accId of the registered Endpoint */
@property (nonatomic, readwrite) PlivoAccId accId;

/* The callId of the call */
@property (nonatomic, readwrite) NSString *callId;

/* Whether the call is muted */
@property (nonatomic, readonly) BOOL muted;

/* State of the call */
@property (nonatomic, readwrite) PlivoCallState state;

/* Make an outbound call
 
 Calling this method on the PlivoOutgoing object with the SIP URI
 would initiate an outbound call.
 */
- (void)call:(NSString *)sipURI;


/* Make an outbound call with custom SIP headers
 
 Calling this method on the PlivoOutgoing object with the SIP URI
 would initiate an outbound call with custom SIP headers.
 */
- (void)call:(NSString *)sipURI headers:(NSDictionary *)headers;

/* Mutes the call
 
 Calling this method on the PlivoOutgoing object would mute the call.
 */
- (void)mute;

/* Unmute the call
 
 Calling this method on the PlivoOutgoing object would unmute the call.
 */
- (void)unmute;

/* Send DTMF
 
 Calling this method on the PlivoOutgoing object with the digits
 would send DTMF on that call.
 */
- (void)sendDigits:(NSString *)digits;

/* Disconnect the call
 
 Calling this method on the PlivoOutgoing object would disconnect the call.
 This method is deprecated, please use 'hangup'
 */
- (void)disconnect __attribute__((deprecated));

- (void) hold;

- (void) unhold;

/**
 * Hangup the call.
 * Calling this method on the PlivoOutgoing object would disconnect the call.
 */
- (void)hangup;
@end
