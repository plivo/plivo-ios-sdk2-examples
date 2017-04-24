//
//  SIPContactsDetails.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 20/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "SIPContactsDetails.h"
#import "SIPContacts.h"

@implementation SIPContactsDetails

+ (NSArray*)getSIPContactsDetails:(NSArray*)contactsJsonResponse
{
    NSMutableArray* contactsMutableArray = [NSMutableArray new];
    
    for(int i = 0; i < contactsJsonResponse.count; i++)
    {
        if (contactsJsonResponse[i] != (id)[NSNull null])
        {
            SIPContacts *contactObj = [[SIPContacts alloc] initWithContactObject:contactsJsonResponse[i]];
            [contactsMutableArray addObject:contactObj];
        }
    }
    
    return [contactsMutableArray copy];
}
@end
