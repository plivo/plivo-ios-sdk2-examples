//
//  PlivoOutgoingApp.h
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlivoOutgoingApp : NSObject

- (void)login;

- (void)callSIPUriOrNumber:(NSString *)sipURIorNumber;

@end
