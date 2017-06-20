//
//  Phone.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import Foundation
import PlivoVoiceKit

class Phone {
    
    static let sharedInstance = Phone()

    var endpoint: PlivoEndpoint = PlivoEndpoint()
    private var outCall: PlivoOutgoing?
    
    // To register with SIP Server
    
    func login(withUserName userName: String, andPassword password: String) {
        
        UtilClass.makeToastActivity()
        endpoint.login(userName, andPassword: password)
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
    func relayVoipPushNotification(_ pushdata: [AnyHashable: Any]) {
        endpoint.relayVoipPushNotification(pushdata)
    }

    func call(withDest dest: String, andHeaders headers: [AnyHashable: Any]) -> PlivoOutgoing {
        /* construct SIP URI */
        let sipUri: String = "sip:\(dest)\(kENDPOINTURL)"
        /* create PlivoOutgoing object */
        outCall = (endpoint.createOutgoingCall())!
        /* do the call */
        outCall?.call(sipUri, headers: headers)
        return outCall!
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
}
