//
//  CallKitInstance.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 17/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

/*!
 * @discussion CallKitInstance class to maintain single Callkit instance in entire app lifecycle
 */
@interface CallKitInstance : NSObject
+ (CallKitInstance *)sharedInstance;
@property (strong, nonatomic) NSUUID* callUUID;
@property (strong, nonatomic) CXProvider *callKitProvider;
@property (strong, nonatomic) CXCallController* callKitCallController;
@property (strong, nonatomic) CXCallObserver *callObserver;
@end
