//
//  PlivoCall.h
//  PlivoEndpoint
//
//  Copyright (c) 2015 Plivo Inc. All rights reserved.
//  Use of this software is subject to the
//  terms mentioned here, http://plivo.com/terms/

typedef int PlivoCallId;
typedef int PlivoAccId;

typedef enum
{
    Dialing = 0,
    Ringing,
    Ongoing,
    Terminated
} PlivoCallState;

@interface PlivoCall : NSObject

@end
