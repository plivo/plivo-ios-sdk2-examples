//
//  Phone.m
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import "Phone.h"
#import "PlivoEndpoint.h"



@implementation Phone {
    PlivoEndpoint *endpoint;
	PlivoOutgoing *outCall;
}

- (id) init
{
    self = [super init];
    
    if (self) {
        endpoint = [[PlivoEndpoint alloc] init];
    }
    
    return self;
}

- (void)login
{
//#warning Change to valid plivo endpoint username and password.
    NSString *username = @"mridulacc160606103956";
    NSString *password = @"123456";
    [endpoint login:username AndPassword:password];
}

- (void)registerToken:(NSData*)token
{
    [endpoint registerToken:token];
}

- (void)relayVoipPushNotification:(NSDictionary*)pushdata
{
    [endpoint relayVoipPushNotification:pushdata];
}

- (PlivoOutgoing *)callWithDest:(NSString *)dest andHeaders:(NSDictionary *)headers
{
    /* construct SIP URI */
    NSString *sipUri = [[NSString alloc]initWithFormat:@"sip:%@@phone.plivo.com", dest];
    
    /* create PlivoOutgoing object */
    outCall = [endpoint createOutgoingCall];
    
    /* do the call */
    [outCall call:sipUri headers:headers];
    
    return outCall;
}

- (void)setDelegate:(id)delegate
{
    [endpoint setDelegate:delegate];
}

- (void) disableAudio{
	[outCall hold];
}

- (void) enableAudio{
	[outCall unhold];
}

- (void)startAudioDevice{
    [endpoint startAudioDevice];
}

- (void)stopAudioDevice{
    [endpoint stopAudioDevice];
}

- (void)configureAudioSession{
    [endpoint configureAudioDevice];
}
@end
