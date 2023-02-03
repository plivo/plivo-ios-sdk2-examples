//
//  Phone.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import Foundation
import PlivoVoiceKit
import Alamofire

class Phone {
    
    static let sharedInstance = Phone()
    var deviceToken: Data?
    var endpoint: PlivoEndpoint = PlivoEndpoint(["debug":true,"enableTracking":true,"enableQualityTracking": CallAndMediaMetrics.ALL])
    private var outCall: PlivoOutgoing?
    
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
    
    func login(withAccessToken accessToken: String, deviceToken token: Data?) {
        UtilClass.makeToastActivity()
        
        if (kLOGINWITHTOKENGENERATOR != 0) {
            loginWithTokenGenerator(deviceToken: token)
        } else {
            endpoint.loginWithAccessToken(accessToken, deviceToken: token)
        }
        
    }
    
    func login(withAccessToken accessToken: String) {
        UtilClass.makeToastActivity()
        if (kLOGINWITHTOKENGENERATOR != 0) {
            loginWithTokenGenerator(deviceToken: nil)
        } else {
            endpoint.loginWithAccessToken(accessToken)
        }
        endpoint.loginWithAccessToken(accessToken)
    }
    
    func loginWithTokenGenerator(deviceToken token: Data?) {
        
        UtilClass.makeToastActivity()
        deviceToken = token
        endpoint.loginWithAccessTokenGenerator(jwtDelegate: self)
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
    func loginForIncomingWithToken(withAccessToken accessToken: String, withDeviceToken deviceToken: Data?, withCertificateId certificateId: String, withNotificationInfo pushInfo: [AnyHashable: Any]) {
        UtilClass.makeToastActivity()
        if (kLOGINWITHTOKENGENERATOR != 0) {
            loginWithTokenGenerator(deviceToken: deviceToken)
        } else {
            endpoint.loginForIncomingWithJWT(withAccessToken: accessToken, withDeviceToken: deviceToken, withCertificateId: certificateId, withNotificationInfo: pushInfo)
        }
    }
    
    //receive and pass on (information or a message)
    func loginForIncomingWithUsername(withUserName username: String, withPassword password: String, withDeviceToken deviceToken: Data?, withCertifateId certificateId: String, withNotificationInfo pushInfo: [AnyHashable: Any]) {
        UtilClass.makeToastActivity()
        endpoint.loginForIncomingWithUsername(withUserName: username, withPassword: password, withDeviceToken: deviceToken, withCertifateId: certificateId, withNotificationInfo: pushInfo)
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




extension Phone: JWTDelegate {
    func getAccessToken() {
        
        
        let Url = String(format: "") // TODO: Add your url here
           guard let serviceUrl = URL(string: Url) else { return }
            let timeInterval = Int(Date().timeIntervalSince1970)
            let parameterDictionary: [String: Any] = [
                "iss": "",  // TODO: Enter you auth id here
                "sub": "test",
                "per": ["voice": ["incoming_allow": true, "outgoing_allow": true]]
            ]
//           let parameterDictionary = ["username" : "Test", "password" : "123456"]
           var request = URLRequest(url: serviceUrl)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
               return
           }
           request.httpBody = httpBody
            request.headers =  ["Authorization": ""]  // TODO: Add authorization here
           let session = URLSession.shared
           session.dataTask(with: request) { (data, response, error) in
               if let response = response {
                   print(response)
               }
               if let data = data {
                   do {
                       var dataAsString:String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String

                       let token: JWTDecoder = try JSONDecoder().decode(JWTDecoder.self, from: data)
                       if let deviceToken = self.deviceToken {
                           print(token.token)
                           self.endpoint.loginWithAccessToken(token.token, deviceToken: deviceToken)
                       
                       } else {
                           self.endpoint.loginWithAccessToken(token.token)
                       }
                   } catch let decoderError {
                       print(decoderError)
                   }
               }
              
           }.resume()
    }
}




struct JWTDecoder: Codable {
    var api_id: String
    var token: String
}
