//
//  ViewController.swift
//  PlivoSwiftApp
//
//  Created by Shailesh Patel on 03/03/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var phone: Phone? = nil
    var started: boolean_t = 0
    
    @IBOutlet weak var number: UITextField!
    
    @IBOutlet weak var hangup: UIButton!
    
    @IBOutlet weak var call: UIButton!
    
    @IBOutlet weak var debugText: UITextView!
    
    @IBOutlet weak var endcall: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        phone = Phone()
        phone?.setDelegate(delegate: self)
        phone?.login()
        logDebug("- Logging In")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func endPressed(_ sender: UIButton) {
        phone?.hangup()
        call.isEnabled = true
        endcall.isEnabled = false
    }
    
    @IBAction func callPressed(_ sender: UIButton) {
        var dest: String = number.text!
        
        if (dest.characters.count) == 0 {
            return
        }
        
        let extraHeaders: [AnyHashable: Any] = [
            "X-PH-Header1" : "Value1",
            "X-PH-Header2" : "Value2"
        ]
        
        phone?.call(withDest: dest, andHeaders: extraHeaders)
        view.endEditing(true)
        endcall.isEnabled = true
        call.isEnabled = false
    }
    
    /**
     * Print debug log to textview in the bottom of the view screen
     */
    func logDebug(_ message: String) {
        /**
         * Check if this code is executed from main thread.
         * Only main thread that can update the GUI.
         * Our plivo endpoint run in it's own thread
         */
        if !Thread.isMainThread {
            /* if it is not executed from main thread, give this to main thread and return */
            performSelector(onMainThread:#selector(logDebug(_:)), with: message, waitUntilDone: false)
            return
        }
        /* add newline to end of the message */
        let toLog: String = "\(message)\n"
        /* insert message */
        debugText.insertText(toLog)
        /* Scroll textview */
        debugText.scrollRangeToVisible(NSRange(location: debugText.text.characters.count, length: 0))
    }
    
    /**
     * onLogin delegate implementation.
     */
    func onLogin() {
        logDebug("- Login OK")
    }
    
    /**
     * onLoginFailed delegate implementation.
     */
    func onLoginFailed() {
        logDebug("- Login FAILED")
        logDebug("- Login failed. Please check your username and password")
        print("- Login failed. Please check your username and password")
    }
    
    /**
     * onOutgoingCallAnswered delegate implementation
     */
    func onOutgoingCallAnswered(_ call: PlivoOutgoing) {
        self.logDebug("- On outgoing call answered")
        print("- On outgoing call answered")
    }
    
    /**
     * onOutgoingCallHangup delegate implementation.
     */
    func onOutgoingCallHangup(_ call: PlivoOutgoing) {
        self.logDebug("- On outgoing call hangup")
        print("- On outgoing call hangup")
    }
    
    /**
     * onCalling delegate implementation.
     */
    func onCalling(_ call: PlivoOutgoing) {
        self.logDebug("- On calling")
        print("- On calling")
    }
    
    /**
     * onOutgoingCallRinging delegate implementation.
     */
    func onOutgoingCallRinging(_ call: PlivoOutgoing) {
        self.logDebug("- On outgoing call ringing")
        print("- On outgoing call ringing")
    }
    
    /**
     * onOutgoingCallrejected delegate implementation.
     */
    func onOutgoingCallRejected(_ call: PlivoOutgoing) {
        self.logDebug("- On outgoing call rejected")
        print("- On outgoing call rejected")
    }
    
    /**
     * onOutgoingCallInvalid delegate implementation.
     */
    func onOutgoingCallInvalid(_ call: PlivoOutgoing) {
        self.logDebug("- On outgoing call invalid")
        print("- On outgoing call invalid")
    }

    /**
     * onIncomingCall delegate implementation
     */
    
    func onIncomingCall(_ incoming: PlivoIncoming) {
        /* display caller name in call status label */
        print("Incoming call from \(incoming.fromContact)")
        /* log it */
        let logMsg: String = "- Call from \(incoming.fromContact)"
        self.logDebug(logMsg)
        /* print extra header */
        if incoming.extraHeaders.count > 0 {
            self.logDebug("- Extra headers:")
            for (key, val) in incoming.extraHeaders {
                print("Property: \"\(key as! String)\"")
                let keyVal: String = "-- \(key) => \(val)"
                self.logDebug(keyVal)
            }
        }
    }
    /**
     * onIncomingCallHangup delegate implementation.
     */
    func onIncomingCallHangup(_ incoming: PlivoIncoming) {
        /* log it */
        self.logDebug("- Incoming call ended")
        print("- Incoming call ended")
    }
    /**
     * onIncomingCallRejected implementation.
     */
    func onIncomingCallRejected(_ incoming: PlivoIncoming) {
        /* log it */
        self.logDebug("- Incoming call rejected")
        print("- Incoming call rejected")
    }
}

