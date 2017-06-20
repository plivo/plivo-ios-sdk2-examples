//
//  IntentHandler.swift
//  IntentHandler
//
//  Created by Siva  on 25/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import Intents

class IntentHandler: INExtension, INStartAudioCallIntentHandling {
    
    func handle(startAudioCall intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void) {
        let response: INStartAudioCallIntentResponse
        defer {
            completion(response)
        }
        
        // Ensure there is a person handle
        guard intent.contacts?.first?.personHandle != nil else {
            response = INStartAudioCallIntentResponse(code: .failure, userActivity: nil)
            return
        }
        
        let userActivity = NSUserActivity(activityType: String(describing: INStartAudioCallIntent.self))
        response = INStartAudioCallIntentResponse(code: .continueInApp, userActivity: userActivity)

    }
    
}
