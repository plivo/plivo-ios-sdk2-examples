//
//  CallKitInstance.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 17/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

@interface CallKitInstance : NSObject
+ (CallKitInstance *)sharedInstance;
@property (strong, nonatomic) NSUUID* callUUID;
@property (strong, nonatomic) CXProvider *callKitProvider;
@property (strong, nonatomic) CXCallController* callKitCallController;
@end
