//
//  PlivoCallController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import CallKit
import AVFoundation
import GoogleSignIn
import FirebaseAnalytics
import Crashlytics
import PlivoVoiceKit

class PlivoCallController: UIViewController, CXProviderDelegate, CXCallObserverDelegate, JCDialPadDelegate, PlivoEndpointDelegate {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var callerNameLabel: UILabel!
    @IBOutlet weak var callStateLabel: UILabel!
    @IBOutlet weak var dialPadView: UIView!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var hideButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var holdButton: UIButton!
    @IBOutlet weak var keypadButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var activeCallImageView: UIImageView!

    var pad: JCDialPad?
    var timer: MZTimerLabel?
    var callObserver: CXCallObserver?
    
    var isItUserAction: Bool = false
    var isItGSMCall: Bool = false
    
    var outCall: PlivoOutgoing?
    var incCall: PlivoIncoming?
    
    var isSpeakerOn: Bool = false

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Dial pad to enter phone number or to Enter DTMF Text
        pad = JCDialPad(frame: dialPadView.bounds)
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.delegate = self
        pad?.showDeleteButton = true
        pad?.formatTextToPhoneNumber = false
        dialPadView.backgroundColor = UIColor.white
        dialPadView.addSubview(pad!)
        timer = MZTimerLabel(label: callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
        timer?.timeFormat = "HH:mm:ss"
        CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
        CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
        //Add Call Interruption observers
        addObservers()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Phone.sharedInstance.setDelegate(self)
        hideActiveCallView()
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.layoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        UserDefaults.standard.set(false, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        pad?.layoutSubviews()
        pad?.digitsTextField.text = ""
        pad?.showDeleteButton = false
        pad?.rawText = ""
        muteButton.isEnabled = false
        holdButton.isEnabled = false
        keypadButton.isEnabled = false
        hideActiveCallView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func addObservers() {
        // add interruption handler
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.handleInterruption), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        // we don't do anything special in the route change notification
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.handleRouteChange), name: NSNotification.Name.AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())
        // if media services are reset, we need to rebuild our audio chain
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.handleMediaServerReset), name: NSNotification.Name.AVAudioSessionMediaServicesWereReset, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.appWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    //To unregister with SIP Server
    
    func unRegisterSIPEndpoit() {
        FIRAnalytics.logEvent(withName: "SIPEndpointUnregister", parameters: nil)
        Phone.sharedInstance.logout()
    }
    
    // MARK: - PlivoSDK Delegate Methods

    /**
     * onLogin delegate implementation.
     */
    func onLogin() {
        DispatchQueue.main.async(execute: {() -> Void in
            UtilClass.hideToastActivity()
            UtilClass.makeToast(kLOGINSUCCESS)
            Crashlytics.sharedInstance().setUserName(UserDefaults.standard.object(forKey: kUSERNAME) as? String)
            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            appDelegate?.voipRegistration()
        })
        //NSLog(@"Ready to make a call");
    }
    
    /**
     * onLoginFailed delegate implementation.
     */
    func onLoginFailed() {
        DispatchQueue.main.async(execute: {() -> Void in
            UtilClass.makeToast("408:Timedout Error")
            UtilClass.hideToastActivity()
            //NSLog(@"%@",kLOGINFAILMSG);
            UtilClass.setUserAuthenticationStatus(false)
            UserDefaults.standard.removeObject(forKey: kUSERNAME)
            UserDefaults.standard.removeObject(forKey: kPASSWORD)
            UserDefaults.standard.synchronize()
            GIDSignIn.sharedInstance().signOut()
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC: LoginViewController? = _mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
            Phone.sharedInstance.setDelegate(loginVC!)
            let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            _appDelegate?.window?.rootViewController = loginVC
        })
    }
    
    /**
     * onLogout delegate implementation.
     */
    func onLogout() {
        
        DispatchQueue.main.async(execute: {() -> Void in
            
            if (CallKitInstance.sharedInstance.callUUID != nil){
                self.performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
            }
            
            UtilClass.makeToast(kLOGOUTSUCCESS)
            UtilClass.setUserAuthenticationStatus(false)
            UserDefaults.standard.removeObject(forKey: kUSERNAME)
            UserDefaults.standard.removeObject(forKey: kPASSWORD)
            UserDefaults.standard.synchronize()
            GIDSignIn.sharedInstance().signOut()
            UtilClass.hideToastActivity()
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC: LoginViewController? = _mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
            Phone.sharedInstance.setDelegate(loginVC!)
            let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            _appDelegate?.window?.rootViewController = loginVC
        })
    }

    /**
     * onIncomingCall delegate implementation
     */
    
    func onIncomingCall(_ incoming: PlivoIncoming) {
        
        switch AVAudioSession.sharedInstance().recordPermission()
        {
            case AVAudioSessionRecordPermission.granted:
               
                print("Permission granted")
            
                FIRAnalytics.logEvent(withName: "OnIncomingCall", parameters: ["CallId": "\(incoming.callId)" as NSObject, "Account Id": "\(incoming.accId)" as NSObject, "From": "\(incoming.fromUser)" as NSObject])
                
                DispatchQueue.main.async(execute: {() -> Void in
                    self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[2]
                    self.userNameTextField.text = ""
                    self.pad?.digitsTextField.text = ""
                    self.pad?.rawText = ""
                    self.callerNameLabel.text = incoming.fromUser
                    self.callStateLabel.text = "Incoming call..."
                })
                CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
                CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
                CallInfo.addCallsInfo(callInfo:[incoming.fromUser,Date()])
                
                //Added by Siva on Tue 11th, 2017
                if !(incCall != nil) && !(outCall != nil) {
                    /* log it */
                    //NSLog(@"%@",[[NSString alloc]initWithFormat:@"Incoming Call from %@", incoming.fromContact]);
                    /* assign incCall var */
                    incCall = incoming
                    outCall = nil
                    CallKitInstance.sharedInstance.callUUID = UUID()
                    //NSLog(@"Incoming Call UUID IS %@",[CallKitInstance sharedInstance].callUUID);
                    reportIncomingCall(from: incoming.fromUser, with: CallKitInstance.sharedInstance.callUUID!)
                }
                else {
                    FIRAnalytics.logEvent(withName: "OnIncomingCallReject", parameters: ["CallId": "\(incoming.callId)" as NSObject, "Account Id": "\(incoming.accId)" as NSObject, "From": "\(incoming.fromUser)" as NSObject])
                    /*
                     * Reject the call when we already have active ongoing call
                     */
                    incoming.reject()
                    return
                }
                break
            
            case AVAudioSessionRecordPermission.denied:
                print("Pemission denied")
                UtilClass.makeToast("Please go to settings and turn on Microphone service for incoming/outgoing calls.")
                incoming.reject()
                break
            
            case AVAudioSessionRecordPermission.undetermined:
                print("Request permission here")
                break
            
            default:
                break
        }
        
    }
    
    /**
     * onIncomingCallHangup delegate implementation.
     */
    
    func onIncomingCallHangup(_ incoming: PlivoIncoming) {
        //NSLog(@"- Incoming call ended");
        FIRAnalytics.logEvent(withName: "onIncomingCallHangup", parameters: ["CallId": "\(incoming.callId)" as NSObject, "Account Id": "\(incoming.accId)" as NSObject, "From": "\(incoming.fromUser)" as NSObject])
        if (incCall != nil) {
            //NSLog(@"Hangup Incoming call : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
            incCall = nil
        }
    }
    
    /**
     * onIncomingCallRejected implementation.
     */
    func onIncomingCallRejected(_ incoming: PlivoIncoming) {
        FIRAnalytics.logEvent(withName: "onIncomingCallRejected", parameters: ["CallId": "\(incoming.callId)" as NSObject, "Account Id": "\(incoming.accId)" as NSObject, "From": "\(incoming.fromUser)" as NSObject])
        /* log it */
        //NSLog(@"Incoming call Rejected : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
        incCall = nil
    }
    
    /**
     * onOutgoingCallAnswered delegate implementation
     */
    func onOutgoingCallAnswered(_ call: PlivoOutgoing) {
        FIRAnalytics.logEvent(withName: "onOutgoingCallAnswered", parameters: ["CallId": "\(call.callId)" as NSObject, "Account Id": "\(call.accId)" as NSObject])
        //NSLog(@"- On outgoing call answered");
        DispatchQueue.main.async(execute: {() -> Void in
            self.muteButton.isEnabled = true
            self.keypadButton.isEnabled = true
            self.holdButton.isEnabled = true
            self.pad?.digitsTextField.isHidden = true
            if !(self.timer != nil) {
                self.timer = MZTimerLabel(label: self.callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
                self.timer?.timeFormat = "HH:mm:ss"
                self.timer?.start()
            }
            else {
                self.timer?.start()
            }
        })
    }
    
    /**
     * onOutgoingCallHangup delegate implementation.
     */
    
    func onOutgoingCallHangup(_ call: PlivoOutgoing) {
        FIRAnalytics.logEvent(withName: "onOutgoingCallHangup", parameters: ["CallId": "\(call.callId)" as NSObject, "Account Id": "\(call.accId)" as NSObject])
        //NSLog(@"Hangup call : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    func onCalling(_ call: PlivoOutgoing) {
        FIRAnalytics.logEvent(withName: "onOutgoingCallonCalling", parameters: nil)
        //NSLog(@"On Caling");
    }
    
    /**
     * onOutgoingCallRinging delegate implementation.
     */
    func onOutgoingCallRinging(_ call: PlivoOutgoing) {
        FIRAnalytics.logEvent(withName: "onOutgoingCallRinging", parameters: ["Event": "onOutgoingCallRinging" as NSObject, "CallId": "\(call.callId)" as NSObject])
        //NSLog(@"- On outgoing call ringing");
        DispatchQueue.main.async(execute: {() -> Void in
            self.callStateLabel.text = "Ringing..."
        })
    }
    
    /**
     * onOutgoingCallrejected delegate implementation.
     */
    func onOutgoingCallRejected(_ call: PlivoOutgoing) {
        FIRAnalytics.logEvent(withName: "onOutgoingCallRejected", parameters: ["CallId": "\(call.callId)" as NSObject, "Account Id": "\(call.accId)" as NSObject])
        //NSLog(@"Outgoing call Rejected : UUID IS %@",[CallKitInstance sharedInstance].callUUID);
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    /**
     * onOutgoingCallInvalid delegate implementation.
     */
    func onOutgoingCallInvalid(_ call: PlivoOutgoing) {
        FIRAnalytics.logEvent(withName: "onOutgoingCallInvalid", parameters: ["CallId": "\(call.callId)" as NSObject, "Account Id": "\(call.accId)" as NSObject])
        //NSLog(@"- On outgoing call invalid");
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    
    // MARK: - CallKit Actions
    func performStartCallAction(with uuid: UUID, handle: String) {
        
        if UtilClass.isNetworkAvailable(){
            
            switch AVAudioSession.sharedInstance().recordPermission() {
                
            case AVAudioSessionRecordPermission.granted:
                //NSLog(@"Permission granted");
                FIRAnalytics.logEvent(withName: "performStartCallActionWithUUID", parameters: ["NSUUID": uuid.uuidString as NSObject, "Handle": handle as NSObject])
                hideActiveCallView()
                unhideActiveCallView()
                //NSLog(@"Outgoing call uuid is: %@", uuid);
                CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
                CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
                //NSLog(@"provider:performStartCallActionWithUUID:");
                if uuid == nil || handle == nil {
                    //NSLog(@"UUID or Handle nil");
                    return
                }
                
                CallInfo.addCallsInfo(callInfo:[handle,Date()])
                
                var newHandleString: String = handle.replacingOccurrences(of: "-", with: "")
                if (newHandleString as NSString).range(of: "+91").location == NSNotFound && (newHandleString.characters.count) == 10 {
                    newHandleString = "+91\(newHandleString)"
                }
                let callHandle = CXHandle(type: .generic, value: newHandleString)
                let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
                let transaction = CXTransaction(action:startCallAction)
                CallKitInstance.sharedInstance.callKitCallController?.request(transaction, completion: {(_ error: Error?) -> Void in
                    if error != nil {
                        //NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
                        DispatchQueue.main.async(execute: {() -> Void in
                            UtilClass.makeToast(kSTARTACTIONFAILED)
                        })
                    }
                    else {
                        //NSLog(@"StartCallAction transaction request successful");
                        let callUpdate = CXCallUpdate()
                        callUpdate.remoteHandle = callHandle
                        callUpdate.supportsDTMF = true
                        callUpdate.supportsHolding = true
                        callUpdate.supportsGrouping = false
                        callUpdate.supportsUngrouping = false
                        callUpdate.hasVideo = false
                        DispatchQueue.main.async(execute: {() -> Void in
                            self.callerNameLabel.text = handle
                            self.callStateLabel.text = "Calling..."
                            self.unhideActiveCallView()
                            CallKitInstance.sharedInstance.callKitProvider?.reportCall(with: uuid, updated: callUpdate)
                        })
                    }
                })
                break
            case AVAudioSessionRecordPermission.denied:
                UtilClass.makeToast("Please go to settings and turn on Microphone service for incoming/outgoing calls.")
                break
            case AVAudioSessionRecordPermission.undetermined:
                // This is the initial state before a user has made any choice
                // You can use this spot to request permission here if you want
                break
            default:
                break
            }
            
        }else{
            
            UtilClass.makeToast("Please connect to internet")
        }
        
    }
    
    func reportIncomingCall(from: String, with uuid: UUID) {
        FIRAnalytics.logEvent(withName: "reportIncomingCallFrom", parameters: ["NSUUID": uuid.uuidString as NSObject, "from": from as NSObject])
        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        
        //For testing added on May 30th, 2017
//        if (incCall != nil) {
//            CallKitInstance.sharedInstance.callUUID = uuid
//            incCall?.answer()
//        }
//        outCall = nil
//        
//        DispatchQueue.main.async(execute: {() -> Void in
//            self.unhideActiveCallView()
//            self.muteButton.isEnabled = true
//            self.holdButton.isEnabled = true
//            self.keypadButton.isEnabled = true
//            if !(self.timer != nil) {
//                self.timer = MZTimerLabel(label: self.callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
//                self.timer?.timeFormat = "HH:mm:ss"
//                self.timer?.start()
//            }
//            else {
//                self.timer?.start()
//            }
//        })
        
        CallKitInstance.sharedInstance.callKitProvider?.reportNewIncomingCall(with: uuid, update: callUpdate, completion: {(_ error: Error?) -> Void in
            if error != nil {
                //NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
                //[UtilityClass makeToast:kREQUESTFAILED];
                Phone.sharedInstance.stopAudioDevice()
                if (self.incCall != nil) {
                    if self.incCall?.state != Ongoing {
                        FIRAnalytics.logEvent(withName: "IncomingCallReject", parameters: ["CallUUID": uuid.uuidString as NSObject, "from": from as NSObject])
                        //NSLog(@"Incoming call - Reject");
                        self.incCall?.reject()
                    }
                    else {
                        FIRAnalytics.logEvent(withName: "IncomingCallHangup", parameters: ["CallUUID": uuid.uuidString as NSObject, "from": from as NSObject])
                        //NSLog(@"Incoming call - Hangup");
                        self.incCall?.hangup()
                    }
                    self.incCall = nil
                }
            }
            else {
                FIRAnalytics.logEvent(withName: "IncomingCallSuccessfullyReported.", parameters: nil)
                print("Incoming call successfully reported.");
                Phone.sharedInstance.configureAudioSession()
            }
        })
    }
    
    func performEndCallAction(with uuid: UUID) {
        
        DispatchQueue.main.async(execute: {() -> Void in
            //NSLog(@"performEndCallActionWithUUID: %@",uuid);
            if uuid == nil {
                //NSLog(@"UUID is null return from here");
                return
            }
            let endCallAction = CXEndCallAction(call: uuid)
            let trasanction = CXTransaction(action:endCallAction)
            CallKitInstance.sharedInstance.callKitCallController?.request(trasanction, completion: {(_ error: Error?) -> Void in
                if error != nil {
                    //NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
                    DispatchQueue.main.async(execute: {() -> Void in
                        //[UtilityClass makeToast:kREQUESTFAILED];
                        Phone.sharedInstance.stopAudioDevice()
                        if (self.incCall != nil) {
                            if self.incCall?.state != Ongoing {
                                FIRAnalytics.logEvent(withName: "IncomingCallReject", parameters: ["CallUUID": uuid.uuidString as NSObject, "from": "\(self.incCall!.fromUser)" as NSObject])
                                //NSLog(@"Incoming call - Reject");
                                self.incCall?.reject()
                            }
                            else {
                                FIRAnalytics.logEvent(withName: "IncomingCallHangup", parameters: ["CallUUID": uuid.uuidString as NSObject, "from": "\(self.incCall!.fromUser)" as NSObject])
                                //NSLog(@"Incoming call - Hangup");
                                self.incCall?.hangup()
                            }
                            self.incCall = nil
                        }
                        if (self.outCall != nil) {
                            FIRAnalytics.logEvent(withName: "OutgoingCallHangup", parameters: ["CallUUID": uuid.uuidString as NSObject])
                            //NSLog(@"Outgoing call - Hangup");
                            self.outCall?.hangup()
                            self.outCall = nil
                        }
                        self.tabBarController?.tabBar.isHidden = false
                        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[1]
                    })
                }
                else {
                    FIRAnalytics.logEvent(withName: "EndCallActionTransactionRequestSuccessful", parameters: nil)
                    //NSLog(@"EndCallAction transaction request successful");
                }
            })
        })
    }

    
    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call == nil || call.hasEnded == true {
            //NSLog(@"CXCallState : Disconnected");
        }
        if call.isOutgoing == true && call.hasConnected == false {
            //NSLog(@"CXCallState : Dialing");
        }
        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false && call != nil {
            //NSLog(@"CXCallState : Incoming");
        }
        if call.hasConnected == true && call.hasEnded == false {
            //NSLog(@"CXCallState : Connected");
        }
    }
    
    
    // MARK: - CXProvider Handling

    func providerDidReset(_ provider: CXProvider) {
        //NSLog(@"ProviderDidReset");
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        //NSLog(@"providerDidBegin");
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        //NSLog(@"provider:didActivateAudioSession");
        Phone.sharedInstance.startAudioDevice()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        //NSLog(@"provider:didDeactivateAudioSession:");
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        //NSLog(@"provider:timedOutPerformingAction:");
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        //NSLog(@"provider:performStartCallAction:");
        FIRAnalytics.logEvent(withName: "PerformStartCallAction", parameters: nil)
        Phone.sharedInstance.configureAudioSession()
        //Set extra headers
        let extraHeaders: [AnyHashable: Any] = [
            "X-PH-Header1" : "Value1",
            "X-PH-Header2" : "Value2"
        ]
        
        let dest: String = action.handle.value
        //NSLog(@"%@",[[NSString alloc]initWithFormat:@"- Make a call to '%@'", dest]);
        //Make the call
        outCall = Phone.sharedInstance.call(withDest: dest, andHeaders: extraHeaders)
        if (outCall != nil) {
            action.fulfill(withDateStarted: Date())
        }
        else {
            action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if action.isOnHold {
            Phone.sharedInstance.stopAudioDevice()
        }
        else {
            Phone.sharedInstance.startAudioDevice()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if action.isMuted {
            muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            if (incCall != nil) {
                incCall?.unmute()
            }
            if (outCall != nil) {
                outCall?.unmute()
            }
        }
        else {
            muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        FIRAnalytics.logEvent(withName: "performAnswerCallAction", parameters: nil)
        //NSLog(@"provider:performAnswerCallAction:");
        //Answer the call
        if (incCall != nil) {
            CallKitInstance.sharedInstance.callUUID = action.callUUID
            incCall?.answer()
        }
        outCall = nil
        action.fulfill()
        DispatchQueue.main.async(execute: {() -> Void in
            self.unhideActiveCallView()
            self.muteButton.isEnabled = true
            self.holdButton.isEnabled = true
            self.keypadButton.isEnabled = true
            if !(self.timer != nil) {
                self.timer = MZTimerLabel(label: self.callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
                self.timer?.timeFormat = "HH:mm:ss"
                self.timer?.start()
            }
            else {
                self.timer?.start()
            }
        })
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        //NSLog(@"provider:performPlayDTMFCallAction:");
        FIRAnalytics.logEvent(withName: "performPlayDTMFCallAction", parameters: nil)
        let dtmfDigits: String = action.digits
        if (incCall != nil) {
            incCall?.sendDigits(dtmfDigits)
        }
        if (outCall != nil) {
            outCall?.sendDigits(dtmfDigits)
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        //NSLog(@"%@ -- %@",[CallKitInstance sharedInstance].callUUID,action.callUUID);
        if !isItGSMCall || isItUserAction {
            FIRAnalytics.logEvent(withName: "performEndCallAction", parameters: nil)
            //NSLog(@"provider:performEndCallAction:");
            Phone.sharedInstance.stopAudioDevice()
            if (incCall != nil) {
                if incCall?.state != Ongoing {
                    //NSLog(@"Incoming call - Reject");
                    incCall?.reject()
                }
                else {
                    //NSLog(@"Incoming call - Hangup");
                    incCall?.hangup()
                }
                incCall = nil
            }
            if (outCall != nil) {
                //NSLog(@"Outgoing call - Hangup");
                outCall?.hangup()
                outCall = nil
            }
            action.fulfill()
            isItUserAction = false
            tabBarController?.tabBar.isHidden = false
            tabBarController?.selectedViewController = tabBarController?.viewControllers?[1]
        }
        else {
            FIRAnalytics.logEvent(withName: "performEndCallAction", parameters: nil)
            //NSLog(@"GSM - provider:performEndCallAction:");
        }
    }
    
    // MARK: - Handling IBActions
    @IBAction func callButtonTapped(_ sender: Any) {
        
        if UtilClass.isNetworkAvailable(){

        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.granted:
            if (!(userNameTextField.text! == "SIP URI or Phone Number") && !UtilClass.isEmpty(userNameTextField.text!)) || !UtilClass.isEmpty(pad!.digitsTextField.text!) || (incCall != nil) || (outCall != nil) {
                FIRAnalytics.logEvent(withName: "MakeCallButtonTapped", parameters: nil)
                let img: UIImage? = (sender as AnyObject).image(for: .normal)
                let data1: NSData? = UIImagePNGRepresentation(img!) as NSData?
                
                if (data1?.isEqual(UIImagePNGRepresentation(UIImage(named: "MakeCall.png")!)))! {
 
                    callStateLabel.text = "Calling..."
                    callerNameLabel.text = pad?.digitsTextField.text
                    unhideActiveCallView()
                    var handle: String
                    if !(pad?.digitsTextField.text == "") {
                        handle = (pad?.digitsTextField.text!)!
                    }
                    else if !(userNameTextField.text == "") {
                        handle = userNameTextField.text!
                    }
                    else {
                        UtilClass.makeToast(kINVALIDSIPENDPOINTMSG)
                        return
                    }
                    
                    userNameTextField.text = ""
                    pad?.digitsTextField.text = ""
                    pad?.rawText = ""
                    CallKitInstance.sharedInstance.callUUID = UUID()
                    /* outgoing call */
                    performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: handle)
                }
                else if (data1?.isEqual(UIImagePNGRepresentation(UIImage(named: "EndCall.png")!)))! {

                    FIRAnalytics.logEvent(withName: "EndCallButtonTapped", parameters: nil)
                    isItUserAction = true
                    performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
                }
            }
            else {
                UtilClass.makeToast(kINVALIDSIPENDPOINTMSG)
            }
            break
        case AVAudioSessionRecordPermission.denied:
            UtilClass.makeToast("Please go to settings and turn on Microphone service for incoming/outgoing calls.")
            break
        case AVAudioSessionRecordPermission.undetermined:
            // This is the initial state before a user has made any choice
            // You can use this spot to request permission here if you want
            break
        default:
            break
        }
        }else{
            UtilClass.makeToast("Please connect to internet")
        }
        
    }
    
    /*
     * Display Dial pad to enter DTMF text
     * Hide Mute/Unmute button
     * Hide Hold/Unhold button
     */
    @IBAction func keypadButtonTapped(_ sender: Any) {
        FIRAnalytics.logEvent(withName: "KeypadButtonTapped", parameters: nil)
        UserDefaults.standard.set(true, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        holdButton.isHidden = true
        muteButton.isHidden = true
        keypadButton.isHidden = true
        hideButton.isHidden = false
        speakerButton.isHidden = true
        activeCallImageView.isHidden = true
        userNameTextField.text = ""
        view.bringSubview(toFront: hideButton)
        userNameTextField.isHidden = false
        userNameTextField.textColor = UIColor.white
        dialPadView.isHidden = false
        dialPadView.backgroundColor = UIColor(red: CGFloat(0.0 / 255.0), green: CGFloat(75.0 / 255.0), blue: CGFloat(58.0 / 255.0), alpha: CGFloat(1.0))
        dialPadView.alpha = 0.7
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.layoutSubviews()
        callerNameLabel.isHidden = true
        callStateLabel.isHidden = true
    }
    
    /*
     * Hide Dial pad view
     * UnHide Mute/Unmute button
     * UnHide Hold/Unhold button
     */
    
    @IBAction func hideButtonTapped(_ sender: Any) {
        FIRAnalytics.logEvent(withName: "HideButtonTapped", parameters: nil)
        UserDefaults.standard.set(false, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        holdButton.isHidden = false
        muteButton.isHidden = false
        speakerButton.isHidden = false
        keypadButton.isHidden = false
        dialPadView.isHidden = true
        hideButton.isHidden = true
        activeCallImageView.isHidden = false
        userNameTextField.isHidden = true
        userNameTextField.textColor = UIColor.darkGray
        pad?.rawText = ""
        callerNameLabel.isHidden = false
        callStateLabel.isHidden = false
        dialPadView.backgroundColor = UIColor.white
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.layoutSubviews()
    }
    
    /*
     * Mute/Unmute calls
     */
    @IBAction func muteButtonTapped(_ sender: Any) {
        let img: UIImage? = (sender as AnyObject).image(for: .normal)
        
        let data1: NSData? = UIImagePNGRepresentation(img!) as NSData?
        
        if (data1?.isEqual(UIImagePNGRepresentation(UIImage(named: "Unmute.png")!)))! {

            FIRAnalytics.logEvent(withName: "MuteButtonTapped", parameters: nil)
            DispatchQueue.main.async(execute: {() -> Void in
                self.muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
        else {
            
            FIRAnalytics.logEvent(withName: "UnmuteButtonTapped", parameters: nil)
            DispatchQueue.main.async(execute: {() -> Void in
                self.muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.unmute()
            }
            if (outCall != nil) {
                outCall?.unmute()
            }
        }
    }
    
    /*
     * Hold/Unhold calls
     */
    @IBAction func holdButtonTapped(_ sender: Any) {
        
        let img: UIImage? = (sender as AnyObject).image(for: .normal)
        
        let data1: NSData? = UIImagePNGRepresentation(img!) as NSData?
        
        if (data1?.isEqual(UIImagePNGRepresentation(UIImage(named: "UnholdIcon.png")!)))! {

            FIRAnalytics.logEvent(withName: "HoldButtonTapped", parameters: nil)
            DispatchQueue.main.async(execute: {() -> Void in
                self.holdButton.setImage(UIImage(named: "HoldIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.hold()
            }
            if (outCall != nil) {
                outCall?.hold()
            }
            Phone.sharedInstance.stopAudioDevice()
            
        }
        else {
            
            FIRAnalytics.logEvent(withName: "UnholdButtonTapped", parameters: nil)
            DispatchQueue.main.async(execute: {() -> Void in
                self.holdButton.setImage(UIImage(named: "UnholdIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.unhold()
            }
            if (outCall != nil) {
                outCall?.unhold()
            }
            Phone.sharedInstance.startAudioDevice()
            
        }
    }
    
    
    @IBAction func speakerButtonTapped(_ sender: Any) {
    
        handleSpeaker()
        
    }
    
    
    func handleSpeaker() {

        let audioSession = AVAudioSession.sharedInstance()
        
        if(isSpeakerOn)
        {
            self.speakerButton.setImage(UIImage(named: "Speaker.png"), for: .normal)
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.none)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            isSpeakerOn = false
        }
        else
        {
            self.speakerButton.setImage(UIImage(named: "Speaker_Selected.png"), for: .normal)

            /* Enable Speaker Phone mode */
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            
            isSpeakerOn = true
            
        }
    }
    
    func hideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = false
        callerNameLabel.isHidden = true
        callStateLabel.isHidden = true
        activeCallImageView.isHidden = true
        muteButton.isHidden = true
        keypadButton.isHidden = true
        holdButton.isHidden = true
        dialPadView.isHidden = false
        userNameTextField.isHidden = false
        userNameTextField.isEnabled = true
        pad?.digitsTextField.isHidden = false
        pad?.showDeleteButton = true
        pad?.rawText = ""
        userNameTextField.text = "SIP URI or Phone Number"
        tabBarController?.tabBar.isHidden = false
        callButton.setImage(UIImage(named: "MakeCall.png"), for: .normal)
        timer?.reset()
        timer?.removeFromSuperview()
        timer = nil
        callStateLabel.text = "Calling..."
        dialPadView.alpha = 1.0
        dialPadView.backgroundColor = UIColor.white
        
        handleSpeaker()
    }
    
    func unhideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = true
        callerNameLabel.isHidden = false
        callStateLabel.isHidden = false
        activeCallImageView.isHidden = false
        muteButton.isHidden = false
        keypadButton.isHidden = false
        holdButton.isHidden = false
        dialPadView.isHidden = true
        userNameTextField.isHidden = true
        pad?.digitsTextField.isHidden = true
        pad?.showDeleteButton = false
        tabBarController?.tabBar.isHidden = true
        callButton.setImage(UIImage(named: "EndCall.png"), for: .normal)
    }
    
    
    /*
     * Handle audio interruptions
     * AVAudioSessionInterruptionTypeBegan
     * AVAudioSessionInterruptionTypeEnded
     */
    
    func handleInterruption(_ notification: Notification)
    {
        
        guard let userInfo = notification.userInfo,
            let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSessionInterruptionType(rawValue: interruptionTypeRawValue) else {
                return
        }
        
        switch interruptionType {
            
        case .began:
            
            self.isItGSMCall = true
            Phone.sharedInstance.stopAudioDevice()
            print("----------AVAudioSessionInterruptionTypeBegan-------------")
            FIRAnalytics.logEvent(withName: "AVAudioSessionInterruptionTypeBegan", parameters: nil)
            break
            
        case .ended:
            
            self.isItGSMCall = false
            
            // make sure to activate the session
            let error: Error? = nil
            try? AVAudioSession.sharedInstance().setActive(true)
            if nil != error {
                print("AVAudioSession set active failed with error")
                Phone.sharedInstance.startAudioDevice()
            }
            print("----------AVAudioSessionInterruptionTypeEnded-------------")
            FIRAnalytics.logEvent(withName: "AVAudioSessionInterruptionTypeEnded", parameters: nil)
            break
        }
        
    }
    
    func handleRouteChange(_ notification: Notification)
    {
        
    }
    
    func handleMediaServerReset(_ notification: Notification) {
        //NSLog(@"Media server has reset");
        // rebuild the audio chain
        Phone.sharedInstance.configureAudioSession()
        Phone.sharedInstance.startAudioDevice()
        FIRAnalytics.logEvent(withName: "HandleMediaServerReset", parameters: nil)
    }
    
    /*
     * Will be called when app terminates
     * End on going calls(If any)
     */
    
    func appWillTerminate() {
        GIDSignIn.sharedInstance().signOut()
        FIRAnalytics.logEvent(withName: "AppWillTerminate", parameters: nil)
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    
    // MARK: - JCDialPadDelegates
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forButtonPress button: JCPadButton) -> Bool {
        if !(incCall != nil) && !(outCall != nil) {
            userNameTextField.isEnabled = false
            userNameTextField.text = ""
        }
        return true
    }
    
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forLongButtonPress button: JCPadButton) -> Bool {
        if !(incCall != nil) && !(outCall != nil) {
            userNameTextField.text = ""
            userNameTextField.isEnabled = false
        }
        return true
    }
    
    func getDtmfText(_ dtmfText: String, withAppendStirng appendText: String) {
        FIRAnalytics.logEvent(withName: "DTMFTextHandling", parameters: nil)
        if (incCall != nil) {
            incCall?.sendDigits(dtmfText)
            userNameTextField.text = appendText
        }
        if (outCall != nil) {
            outCall?.sendDigits(dtmfText)
            userNameTextField.text = appendText
        }
    }
    
    // MARK: - Handling TextField
    /**
     * Hide keyboard after user press 'return' key
     */
    func textFieldShouldReturn(_ theTextField: UITextField) -> Bool {
        if theTextField == userNameTextField {
            theTextField.resignFirstResponder()
        }
        return true
    }
    
    /**
     * Hide keyboard when text filed being clicked
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // return NO to disallow editing.
        userNameTextField.text = ""
        return true
    }
    
    /**
     *  Hide keyboard when user touches on UI
     *
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // ...
            if touch.phase == .began
            {
                userNameTextField.resignFirstResponder()
                
            }
        }
        super.touchesBegan(touches, with: event)
    }

}
