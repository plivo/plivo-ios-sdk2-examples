//
//  SIPContactsDetails.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 20/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIPContactsDetails : NSObject
+ (NSArray*)getSIPContactsDetails:(NSArray*)contactsJsonResponse;
@end
