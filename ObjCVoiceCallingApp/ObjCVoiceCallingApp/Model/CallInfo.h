//
//  CallInfo.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 12/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CallInfo : NSObject
+(void)addCallInfo:(NSDictionary*)callInfo;
+(NSArray*)getCallsInfoArray;
@end
