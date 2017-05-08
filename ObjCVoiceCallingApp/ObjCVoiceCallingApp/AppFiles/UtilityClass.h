//
//  UtilityClass.h
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 11/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UtilityClass : NSObject
+ (void)setUserAuthenticationStatus:(BOOL)status;
+ (BOOL)getUserAuthenticationStatus;
+ (BOOL)isEmptyString:(NSString *)text;
+ (BOOL)isNetworkAvailable;
+ (void)makeToastActivity;
+ (void)hideToastActivity;
+ (void)makeToast:(NSString*)toastMsg;
@end
