//
//  PlivoRest.h
//  PlivoEndpoint
//
//  Copyright (c) 2015 Plivo Inc. All rights reserved.
//  Use of this software is subject to the
//  terms mentioned here, http://plivo.com/terms/
@protocol PlivoRestDelegate<NSObject>

/* This delegate gets called on a successful response, along with the identifier of the API used.
 */
- (void)successWithResponse:(NSDictionary *)response andIdentifier:(NSString *)identifier;

- (void)failureWithError:(NSError *)error andIdentifier:(NSString *)identifier;

@end

@interface PlivoRest : NSObject

@property (nonatomic, assign) id delegate;
@property (readonly, copy) NSString *authID;

- (id)initWithAuthId:(NSString *)authID andAuthToken:(NSString *)authToken;

- (void)account;

- (void)accountUpdate:(NSDictionary *)params;

- (void)subaccountCreate:(NSDictionary *)params;

- (void)subaccount;
- (void)subaccount:(NSString *)subaccountID;

- (void)subaccountUpdate:(NSString *)subaccountID withParams:(NSDictionary *)params;

- (void)subaccountDelete:(NSString *)subaccountID;
- (void)subaccountDelete:(NSString *)subaccountID withParams:(NSDictionary *)params;

- (void)endpoint;
- (void)endpoint:(NSString *)endpointID;
- (void)endpoint:(NSString *)endpointID withParams:(NSDictionary *)params;

- (void)endpointCreate:(NSDictionary *)params;

- (void)endpointDelete:(NSString *)endpointID;
- (void)endpointDelete:(NSString *)endpointID withParams:(NSDictionary *)params;

- (void)endpointUpdate:(NSString *)endpointID withParams:(NSDictionary *)params;

- (void)application;
- (void)application:(NSString *)appID;

- (void)applicationCreate:(NSDictionary *)params;
- (void)applicationUpdate:(NSString *)appID withParams:(NSDictionary *)params;

- (void)applicationDelete:(NSString *)appID;

- (void)number;
- (void)number:(NSString *)number;

- (void)numberUpdate:(NSString *)number withParams:(NSDictionary *)params;

- (void)numberUnrent:(NSString *)number;
- (void)numberUnrent:(NSString *)number withParams:(NSDictionary *)params;

- (void)numberSearch:(NSString *)countryISO;
- (void)numberSearch:(NSString *)countryISO withParams:(NSDictionary *)params;

- (void)numberRent:(NSString *)groupID;
- (void)numberRent:(NSString *)groupID withParams:(NSDictionary *)params;

- (void)conference;
- (void)conference:(NSString *)conferenceName;

- (void)conferenceHangup;
- (void)conferenceHangup:(NSString *)conferenceName;

- (void)conferenceHangupMember:(NSString *)conferenceName andMemberID:(NSString *)memberID;
- (void)conferenceKickMember:(NSString *)conferenceName andMemberID:(NSString *)memberID;
- (void)conferenceMuteMember:(NSString *)conferenceName andMemberID:(NSString *)memberID;

- (void)conferenceUnmuteMember:(NSString *)conferenceName andMemberID:(NSString *)memberID;
- (void)conferencePlaySound:(NSString *)conferenceName andMemberID:(NSString *)memberID withParams:(NSDictionary *)params;
- (void)conferenceStopSound:(NSString *)conferenceName andMemberID:(NSString *)memberID;

- (void)conferencePlaySpeak:(NSString *)conferenceName andMemberID:(NSString *)memberID andText:(NSString *)text withParams:(NSDictionary *)params;
- (void)conferenceStopSpeak:(NSString *)conferenceName andMemberID:(NSString *)memberID;

- (void)conferenceDeafMember:(NSString *)conferenceName andMemberID:(NSString *)memberID;
- (void)conferenceUndeafMember:(NSString *)conferenceName andMemberID:(NSString *)memberID;

- (void)conferenceRecordStart:(NSString *)conferenceName;
- (void)conferenceRecordStart:(NSString *)conferenceName withParams:(NSDictionary *)params;

- (void)conferenceRecordStop:(NSString *)conferenceName;
- (void)conferenceRecordStop:(NSString *)conferenceName withParams:(NSDictionary *)params;

- (void)messageSend:(NSDictionary *)params;
- (void)messageDetails;
- (void)messageDetails:(NSString *)messageUUID;

- (void)recordings;
- (void)recordings:(NSDictionary *)params;

- (void)recording:(NSString *)recordingID;
- (void)recording:(NSString *)recordingID withParams:(NSDictionary *)params;

- (void)callOutbound:(NSDictionary *)params;

- (void)callDetails;
- (void)callDetails:(NSDictionary *)params;

- (void)callDetail:(NSString *)callUUID;
- (void)callDetail:(NSString *)callUUID withParams:(NSDictionary *)params;

- (void)callLiveDetails;

- (void)callLiveDetail:(NSString *)callUUID;

- (void)callHangup:(NSString *)callUUID;
- (void)callTransfer:(NSString *)callUUID;
- (void)callTransfer:(NSString *)callUUID withParams:(NSDictionary *)params;

- (void)callRecord:(NSString *)callUUID;
- (void)callRecord:(NSString *)callUUID withParams:(NSDictionary *)params;

- (void)callRecordStop:(NSString *)callUUID;
- (void)callRecordStop:(NSString *)callUUID withParams:(NSDictionary *)params;

- (void)callPlay:(NSString *)callUUID andUrl:(NSString *)url;
- (void)callPlay:(NSString *)callUUID andUrl:(NSString *)url withParams:(NSDictionary *)params;

- (void)callPlayStop:(NSString *)callUUID;
- (void)callPlayStop:(NSString *)callUUID withParams:(NSDictionary *)params;

- (void)callSpeak:(NSString *)callUUID andText:(NSString *)text;
- (void)callSpeak:(NSString *)callUUID andText:(NSString *)text withParams:(NSDictionary *)params;

- (void)callSpeakStop:(NSString *)callUUID;
- (void)callSpeakStop:(NSString *)callUUID withParams:(NSDictionary *)params;

- (void)dtmfSend:(NSString *)callUUID andDigits:(NSString *)digits;
- (void)dtmfSend:(NSString *)callUUID andDigits:(NSString *)digits withParams:(NSString *)params;

- (void)cancelRequest:(NSString *)requestUUID;
- (void)cancelRequest:(NSString *)requestUUID withParams:(NSString *)params;

@end
