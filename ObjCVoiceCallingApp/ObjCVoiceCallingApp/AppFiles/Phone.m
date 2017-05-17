//
//  Phone.m
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import "Phone.h"
#import "UtilityClass.h"
#import "UIView+Toast.h"
#import "Constants.h"
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

// To register with SIP Server
- (void)loginWithUserName:(NSString*)userName andPassword:(NSString*)password
{
    [UtilityClass makeToastActivity];
    
    [endpoint login:userName AndPassword:password];
}

//To unregister with SIP Server
- (void)logout
{
    [endpoint logout];
}

//Register pushkit token
- (void)registerToken:(NSData*)token
{
    [endpoint registerToken:token];
}

//receive and pass on (information or a message)
- (void)relayVoipPushNotification:(NSDictionary*)pushdata
{
    [endpoint relayVoipPushNotification:pushdata];
}

/* make call with extra headers */
- (PlivoOutgoing *)callWithDest:(NSString *)dest andHeaders:(NSDictionary *)headers
{
    /* construct SIP URI */
    NSString *sipUri = [[NSString alloc]initWithFormat:@"sip:%@%@", dest,kENDPOINTURL];
    
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

//To Configure Audio
- (void)configureAudioSession{
    [endpoint configureAudioDevice];
}

/*
 * To Start Audio service
 * To handle Audio Interruptions
 * AVAudioSessionInterruptionTypeEnded
 */
- (void)startAudioDevice{
    [endpoint startAudioDevice];
}

/*
 * To Start Audio service
 * To handle Audio Interruptions
 * AVAudioSessionInterruptionTypeBegan
 */
- (void)stopAudioDevice{
    [endpoint stopAudioDevice];
}


//- (void) disableAudio{
//	[outCall hold];
//}
//
//- (void) enableAudio{
//	[outCall unhold];
//}

@end
