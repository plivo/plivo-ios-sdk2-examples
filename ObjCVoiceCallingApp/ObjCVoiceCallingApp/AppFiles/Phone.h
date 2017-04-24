//
//  Phone.h
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PlivoVoiceKit/PlivoVoiceKit.h>

/*!
 * @discussion Phone class to handle Plivo voice SDK
 */
@interface Phone : NSObject

+ (Phone *)sharedInstance;

/* login */
// To register with SIP Server
- (void)loginWithUserName:(NSString*)userName andPassword:(NSString*)password;

//To unregister with SIP Server
- (void)logout;

//Register pushkit token
- (void)registerToken:(NSData*)token;

//receive and pass on (information or a message)
- (void)relayVoipPushNotification:(NSDictionary*)pushdata;

/* make call with extra headers */
- (PlivoOutgoing *)callWithDest:(NSString *)dest andHeaders:(NSDictionary *)headers;

/* set delegate for plivo endpoint object */
- (void)setDelegate:(id)delegate;

- (void)configureAudioSession;

- (void)startAudioDevice;

- (void)stopAudioDevice;


//- (void)enableAudio;
//
//- (void)disableAudio;

@end
