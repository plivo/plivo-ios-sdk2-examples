//
//  SIPContacts.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 20/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "SIPContacts.h"
#import "UtilityClass.h"

@implementation SIPContacts

-(id)initWithContactObject:(NSDictionary*)contactDictionary;
{
    
    if (self = [super init])
    {
        self.sipEndpoint =  contactDictionary[@"endpoint"];
        self.sipEmail = contactDictionary[@"email"];
        
    }
    return self;
}


@end
