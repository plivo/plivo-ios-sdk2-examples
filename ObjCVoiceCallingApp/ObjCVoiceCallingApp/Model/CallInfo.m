//
//  CallInfo.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 12/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "CallInfo.h"
#import "Constants.h"

@implementation CallInfo

+(void)addCallInfo:(NSDictionary*)callInfo
{
    NSUserDefaults *callHistoryDefaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *callHistoryArray = [[callHistoryDefaults objectForKey:kCALLSINFO] mutableCopy];
    
    if (!callHistoryArray)
        callHistoryArray = [[NSMutableArray alloc] init];
    
    NSMutableArray* tempCallHistoryArray = [NSMutableArray new];
    
    [tempCallHistoryArray addObject:callInfo];
    [tempCallHistoryArray addObjectsFromArray:callHistoryArray];
    
    [[NSUserDefaults standardUserDefaults] setObject:tempCallHistoryArray forKey:kCALLSINFO];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

+(NSArray*)getCallsInfoArray
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kCALLSINFO];
}

@end
