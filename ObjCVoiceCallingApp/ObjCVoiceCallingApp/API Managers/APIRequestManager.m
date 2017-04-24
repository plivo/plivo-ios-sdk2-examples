//
//  APIRequestManager.m
//  Lechal
//
//  Created by Ducere on 30/03/16.
//  Copyright © 2016 Ducere. All rights reserved.
//

#import "APIRequestManager.h"
#import "AppDelegate.h"

@implementation APIRequestManager

+(void)PostWithUrl:(NSString *)url Parameters:(NSDictionary*)params success:(void(^)(id json))success failure:(void (^)(NSError *error))failure
{
    
   // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        STHTTPRequest *apiRequest =[STHTTPRequest requestWithURLString:url];
        if (params !=nil) {
            apiRequest.POSTDictionary=params;
        }
        
        apiRequest.completionDataBlock=^(NSDictionary *header, NSData *body){
            NSError *error=nil;
            NSDictionary *responseData =[NSJSONSerialization JSONObjectWithData:body options:kNilOptions error:&error];
            
            success(responseData);
        };
        
        apiRequest.errorBlock=^(NSError *error){
            
            failure(error);
        };
        
        [apiRequest startAsynchronous];
        
   // });
    
}

@end
