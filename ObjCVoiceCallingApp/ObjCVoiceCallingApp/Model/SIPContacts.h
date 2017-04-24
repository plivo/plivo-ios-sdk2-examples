//
//  SIPContacts.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 20/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIPContacts : NSObject
@property (strong, nonatomic) NSString* sipEndpoint;
@property (strong, nonatomic) NSString* sipEmail;
-(id)initWithContactObject:(NSDictionary*)contactDictionary;
@end
