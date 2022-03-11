
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef enum {
    Registered,
    NotRegistered
} RegistrationEvent;

typedef enum {
    IncomingCall,
    TerminateCall,
    CallAccepted
} CallEvent;

typedef enum {
    WebRtcError,
    SipStackError
} ErrorType;



@interface SipAdapter : NSObject

@property (nonatomic, readwrite) NSString *callId;
@property (nonatomic, readwrite) NSString *appId;

- (void)registerUserWithUsername:(NSString *)username andPassword:(NSString *)password;
- (void)registerUserWithUsername:(NSString *)username andPassword:(NSString *)password andToken:(NSString *)token;
- (void)registerUserWithUsername:(NSString *)username andPassword:(NSString *)password andToken:(NSString *)token andCertificateId:(NSString *)certid;
- (void)registerUserWithUsername:(NSString *)username andPassword:(NSString *)password andToken:(NSString *)token andCertificateId:(NSString *)certid andproxy:(NSString *)proxy andHeaders:(NSDictionary *)headers;
- (void)setRegisterTimeout:(NSNumber *)time;
- (void)registerRegistrationHandler:(void (^)(RegistrationEvent, NSString*))handler;
- (void)registerCallHandler:(void (^)(CallEvent, NSString*))handler;
- (void)registerLogHandler:(void (^)(NSString*))handler;
- (void)registerErrorHandler:(void (^)(ErrorType, NSString*))handler;
- (void)unregisterUser;

- (void)makeCallTo:(NSString *)sipUri andLocalSdp:(NSString *)localSdp;
- (void)makeCallTo:(NSString *)sipUri andLocalSdp:(NSString *)localSdp andHeaders:(NSDictionary *)headers;
- (void)answer:(NSString *)localSdp;
- (void)rejectCall;
- (void)resetStack;
- (void)networkChange;
- (void)sendRinging;
- (void)endCallAndDestroyLocalStream:(BOOL) destroyLocalStream;
- (void) onIceCandidate: (NSString *)sdp andMid:(NSString *)mid;
- (void) onIceGatheringFinished;
- (void) hangupSession;

- (void)sipSDPHandler:(void (^)(NSString*))handler;
- (void)sipCallInfoHandler:(void (^)(NSString*))handler;
- (void)sipCallStateHandler:(void (^)(NSString*, int))handler;

@end
