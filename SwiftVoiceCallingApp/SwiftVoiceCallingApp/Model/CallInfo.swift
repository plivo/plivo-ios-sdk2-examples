//
//  CallInfo.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit

class CallInfo: NSObject {

    /**
     *  Add recent calls info
     *
     *  @param callInfo contains Phone number or SIP Endpoit, Time of call
     */
    
    class func addCallsInfo(callInfo: [Any])
    {
        var callInfoArrayOld = UserDefaults.standard.object(forKey: kCALLSINFO) as? [Any] ?? [Any]()
        
        if callInfoArrayOld.isEmpty {
            callInfoArrayOld = [Dictionary <String, Date>]()
        }
        
        var callInfoArrayNew = [Any]()
        callInfoArrayNew+=callInfoArrayOld
        callInfoArrayNew.append(callInfo)
        
        UserDefaults.standard.set(callInfoArrayNew, forKey: kCALLSINFO)
        UserDefaults.standard.synchronize()

    }
    
    /**
     *  Return recent calls info
     *
     */
    class func getCallsInfoArray() -> [Any] {
        
        let callInfoArray = UserDefaults.standard.object(forKey: kCALLSINFO) as? [Any] ?? [Any]()
        
        return callInfoArray.reversed()

    }
}
