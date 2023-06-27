import Foundation
import PlivoVoiceKit
import Alamofire

class Phone {
    
    static let sharedInstance = Phone()
    var deviceToken: Data?
    var endpoint: PlivoEndpoint = PlivoEndpoint(["debug":true,"enableTracking":true])
    private var outCall: PlivoOutgoing?
    private var pushInfo: Any?
    
    // To register with SIP Server
    
    func login(withUserName userName: String, andPassword password: String) {
        
        UtilClass.makeToastActivity()
        endpoint.login(userName, andPassword: password)
    }
    
    func login(withUserName userName: String, andPassword password: String, deviceToken token: Data?) {
        
        UtilClass.makeToastActivity()
        
//        if (endpoint.setRegTimeout(regTimeout: 10000)) {
            endpoint.login(userName, andPassword: password, deviceToken: token)
//        }
        
    }
    
    //To unregister with SIP Server
    func logout() {
        endpoint.logout()
    }
    
    //Register pushkit token
    func registerToken(_ token: Data) {
        endpoint.registerToken(token)
    }
    
    
    //receive and pass on (information or a message)
    func loginForIncomingWithUsername(withUserName username: String, withPassword password: String, withDeviceToken deviceToken: Data?, withCertifateId certificateId: String, withNotificationInfo pushInfo: [AnyHashable: Any]) {
//        UtilClass.makeToastActivity()
        endpoint.relayVoipPushNotification(pushInfo)
    }

    func call(withDest dest: String, andHeaders headers: [AnyHashable: Any], error: inout NSError?) -> PlivoOutgoing? {
        /* construct SIP URI */
        let sipUri: String = "sip:\(dest)\(kENDPOINTURL)"
        /* create PlivoOutgoing object */
        outCall = (endpoint.createOutgoingCall())
        /* do the call */
        if outCall == nil {
            error = NSError(domain: "outgoingCall", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
            return nil
        }
        outCall?.call(sipUri, headers: headers)
        return outCall
    }
    
    func setDelegate(_ controllerDelegate: AnyObject) {
        endpoint.delegate = controllerDelegate
    }
    
    //To Configure Audio
    func configureAudioSession() {
        endpoint.configureAudioDevice()
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeEnded
     */
    func startAudioDevice() {
        endpoint.startAudioDevice()
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeBegan
     */
    func stopAudioDevice() {
        endpoint.stopAudioDevice()
    }
    
    func submitFeedback(starRating: Int , issueList: [AnyObject], notes: String, sendConsoleLog: Bool) {
        let callUUID:String? = endpoint.getLastCallUUID();
        endpoint.submitCallQualityFeedback(callUUID, starRating,  issueList, notes, sendConsoleLog)
    }
}



struct JWTDecoder: Codable {
    var api_id: String
    var token: String
}
