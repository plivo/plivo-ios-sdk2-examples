//
//  CallKitInstance.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 17/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "CallKitInstance.h"

@implementation CallKitInstance

+ (CallKitInstance *)sharedInstance
{
    //Singleton instance
    static CallKitInstance *sharedInstance = nil;
    if(sharedInstance == nil)
    {
        sharedInstance = [[CallKitInstance alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    if(self = [super init])
    {
        
        CXProviderConfiguration* configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"Plivo"];
        configuration.maximumCallGroups = 1;
        configuration.maximumCallsPerCallGroup = 1;
        
        self.callKitProvider = [[CXProvider alloc] initWithConfiguration:configuration];
        self.callKitCallController = [[CXCallController alloc] init];

        return self;
    }
    return nil;
}
@end
