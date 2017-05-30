//
//  CallKitInstance.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import CallKit

class CallKitInstance: NSObject {

    var callUUID: UUID?
    var callKitProvider: CXProvider?
    var callKitCallController: CXCallController?
    var callObserver: CXCallObserver?
    
    //Singleton instance
    static let sharedInstance = CallKitInstance()

    override init() {
        
        super.init()
        
        let configuration = CXProviderConfiguration(localizedName: "Plivo")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        callKitProvider = CXProvider(configuration: configuration)
        callKitCallController = CXCallController()
        callObserver = CXCallObserver()
        
    }

}
