//
//  IntentHandler.m
//  IntentHandler
//
//  Created by Siva  on 27/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "IntentHandler.h"

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

@interface IntentHandler () <INStartAudioCallIntentHandling>

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent {
    // This is the default implementation.  If you want different objects to handle different intents,
    // you can override this and return the handler you want for that particular intent.
    
    return self;
}

#pragma mark - INStartAudioCallIntentHandling

-(void)resolveContactsForStartAudioCall:(INStartAudioCallIntent *)intent
                         withCompletion:(void (^)(NSArray<INPersonResolutionResult *> *resolutionResults))completion{
    NSArray<INPerson *> *recipients = intent.contacts;
    NSMutableArray<INPersonResolutionResult *> *resolutionResults = [NSMutableArray array];
    if (recipients.count == 0)
    {
        completion(@[[INPersonResolutionResult needsValue]]);
        return;
    }
    else if(recipients.count == 1)
    {
        if ([self contactExist:recipients.firstObject.displayName])
        {// check if person contains in contact or not
            
            [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:recipients.firstObject]];
            
        }else [resolutionResults addObject:[INPersonResolutionResult unsupported]];
    }
    else if(recipients.count > 1)
    {
        [resolutionResults addObject:[INPersonResolutionResult disambiguationWithPeopleToDisambiguate:recipients]];
    }else
    {
        [resolutionResults addObject:[INPersonResolutionResult unsupported]];
    }
    completion(resolutionResults);
}

- (BOOL)contactExist:(NSString*)contactName
{
    
    return YES;
}

-(void)confirmStartAudioCall:(INStartAudioCallIntent *)intent
                  completion:(void (^)(INStartAudioCallIntentResponse *response))completion
{
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INStartAudioCallIntent class])];
    INStartAudioCallIntentResponse *response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeReady userActivity:userActivity];
    completion(response);
}

-(void)handleStartAudioCall:(INStartAudioCallIntent *)intent
                 completion:(void (^)(INStartAudioCallIntentResponse *response))completion
{
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INStartAudioCallIntent class])];
    INStartAudioCallIntentResponse *response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeContinueInApp userActivity:userActivity];
    completion(response);
}

@end

//INPersonHandle* personHandle = [[INPersonHandle alloc] initWithValue:@"8686198299" type:INPersonHandleTypePhoneNumber];
//INPerson* person = [[INPerson alloc] initWithPersonHandle:personHandle nameComponents:nil displayName:@"Siva" image:nil contactIdentifier:[NSUUID UUID].UUIDString customIdentifier:[NSUUID UUID].UUIDString];

//            INPersonHandle* personHandle = [[INPersonHandle alloc] initWithValue:@"8686198299" type:INPersonHandleTypePhoneNumber];
//            INPerson* person = [[INPerson alloc] initWithPersonHandle:personHandle nameComponents:nil displayName:@"Siva" image:nil contactIdentifier:[NSUUID UUID].UUIDString customIdentifier:[NSUUID UUID].UUIDString];

//        INPersonHandle* personHandle = [[INPersonHandle alloc] initWithValue:@"8686198299" type:INPersonHandleTypePhoneNumber];
//        INPerson* person = [[INPerson alloc] initWithPersonHandle:personHandle nameComponents:nil displayName:@"Siva" image:nil contactIdentifier:[NSUUID UUID].UUIDString customIdentifier:[NSUUID UUID].UUIDString];
//        [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:person]];

//        INPersonHandle* personHandle = [[INPersonHandle alloc] initWithValue:@"8686198299" type:INPersonHandleTypePhoneNumber];
//        INPerson* person = [[INPerson alloc] initWithPersonHandle:personHandle nameComponents:nil displayName:@"Siva" image:nil contactIdentifier:[NSUUID UUID].UUIDString customIdentifier:[NSUUID UUID].UUIDString];
//        [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:person]];

