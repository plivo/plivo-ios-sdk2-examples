//
//  APIRequestManager.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 12/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STHTTPRequest.h"

@interface APIRequestManager : NSObject
+(void)PostWithUrl:(NSString *)url Parameters:(NSDictionary*)params success:(void(^)(id json))success failure:(void (^)(NSError *error))failure;

@end
