//
//  Phone.swift
//  PlivoSwiftApp
//
//  Created by Shailesh Patel on 03/03/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import Foundation

class Phone : NSObject {
    var endpoint: PlivoEndpoint
    var outCall: PlivoOutgoing? = nil
    
    override init(){
        endpoint = PlivoEndpoint()
        super.init()
    }

    func login() {
        //#warning Change to valid plivo endpoint username and password.
        let username: String = "username"
        let password: String = "password"
        endpoint.login(username, andPassword: password)
    }
    
    func call(withDest dest: String, andHeaders headers: [AnyHashable: Any]) {
        /* construct SIP URI */
        let sipUri: String = "sip:\(dest)@phone.plivo.com"
        /* create PlivoOutgoing object */
        print("Call to : ",sipUri)
        outCall = endpoint.createOutgoingCall()
        /* do the call */
        outCall?.call(sipUri, headers: headers)
    }
    
    func hangup(){
        print("Hangup Call - End Call")
        outCall?.hangup()
    }
    
    func setDelegate(delegate: AnyObject){
        endpoint.delegate = delegate
    }
    
    func disableAudio() {
        outCall?.hold()
    }
    
    func enableAudio() {
        outCall?.unhold()
    }
}
