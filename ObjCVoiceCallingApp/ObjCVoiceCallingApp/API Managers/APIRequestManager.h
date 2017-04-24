//
//  APIRequestManager.h
//  Lechal
//
//  Created by Ducere on 30/03/16.
//  Copyright © 2016 Ducere. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STHTTPRequest.h"

@interface APIRequestManager : NSObject
+(void)PostWithUrl:(NSString *)url Parameters:(NSDictionary*)params success:(void(^)(id json))success failure:(void (^)(NSError *error))failure;

@end
