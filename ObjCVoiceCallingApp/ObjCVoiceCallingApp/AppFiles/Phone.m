//
//  Phone.m
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import "Phone.h"
#import <PlivoVoiceKit/PlivoVoiceKit.h>

@implementation Phone
{
    PlivoEndpoint *endpoint;
	PlivoOutgoing *outCall;
}

+ (Phone *)sharedInstance
{
    static Phone *sharedInstance = nil;
    if(sharedInstance == nil)
    {
        sharedInstance = [[Phone alloc] init];
    }
    return sharedInstance;

}

- (id) init
{
    self = [super init];
    
    if (self)
    {
        endpoint = [[PlivoEndpoint alloc] init];
    }
    
    return self;
}

- (void)loginWithUserName:(NSString*)userName andPassword:(NSString*)password
{
    [endpoint login:userName AndPassword:password];
}

- (void)logout
{
    [endpoint logout];
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
