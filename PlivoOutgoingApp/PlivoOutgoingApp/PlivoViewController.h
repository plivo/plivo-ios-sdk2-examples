//
//  PlivoViewController.h
//  PlivoOutgoingApp
//
//  Created by Iwan BK on 10/2/13.
//  Copyright (c) 2013 Plivo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlivoEndpoint.h"
#import "Phone.h"

// Link to the PushKit framework
#import <PushKit/PushKit.h>
// User Notification framework
#import <UserNotifications/UserNotifications.h>
#import <CallKit/CallKit.h>

@interface PlivoViewController : UIViewController<PlivoEndpointDelegate, UITextViewDelegate, UITextFieldDelegate,CXProviderDelegate,PKPushRegistryDelegate>

@property Phone *phone;

@end
