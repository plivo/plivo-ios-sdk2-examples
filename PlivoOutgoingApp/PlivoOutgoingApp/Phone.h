//
//  Phone.h
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlivoEndpoint.h"

@interface Phone : NSObject

/* login */
- (void)login;

- (void)registerToken:(NSData*)token;

- (void)relayVoipPushNotification:(NSDictionary*)pushdata;

/* make call with extra headers */
- (PlivoOutgoing *)callWithDest:(NSString *)dest andHeaders:(NSDictionary *)headers;

/* set delegate for plivo endpoint object */
- (void)setDelegate:(id)delegate;

- (void)enableAudio;

- (void)disableAudio;

- (void)startAudioDevice;

- (void)stopAudioDevice;

- (void)configureAudioSession;

@end
