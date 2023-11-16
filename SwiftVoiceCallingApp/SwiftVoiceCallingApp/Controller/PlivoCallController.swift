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
import PlivoVoiceKit

class PlivoCallController: UIViewController, CXProviderDelegate, CXCallObserverDelegate, JCDialPadDelegate {
    
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
    
    var ratingVC: RatingViewController?
    
    var pad: JCDialPad?
    var timer: MZTimerLabel?
    var answerTimer: Timer?
    var callObserver: CXCallObserver?
    
    var isItUserAction: Bool = false
    var isItGSMCall: Bool = false
    
    var outCall: PlivoOutgoing?
    var incCall: PlivoIncoming?
    
    var isSpeakerOn: Bool = false
    var isIncomingCallAnswered: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pad = JCDialPad(frame: self.view.bounds)
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.delegate = self
        pad?.showDeleteButton = true
        pad?.formatTextToPhoneNumber = false
        
        dialPadView.addSubview(pad!)
        timer = MZTimerLabel(label: callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
        timer?.timeFormat = "HH:mm:ss"
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
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func addObservers() {
        // add interruption handler
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        // we don't do anything special in the route change notification
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.handleRouteChange), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        // if media services are reset, we need to rebuild our audio chain
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.handleMediaServerReset), name: AVAudioSession.mediaServicesWereResetNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(PlivoCallController.appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    //To unregister with SIP Server
    func unRegisterSIPEndpoit() {
        Phone.sharedInstance.logout()
    }
    
    @objc func invalidateTimerWhenAnswered(){
        if (isIncomingCallAnswered) {
            DispatchQueue.main.async{
                self.callStateLabel.text = "Answered..."
                if !(self.timer != nil) {
                    self.timer = MZTimerLabel(label: self.callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
                    self.timer?.timeFormat = "HH:mm:ss"
                    self.timer?.start()
                }
                else {
                    self.timer?.start()
                }
            }
            self.answerTimer?.invalidate()
        } else {
            self.callStateLabel.text = "Connecting..."
        }
    }
  
    
    func callSubmitFeddbackUI(){
        DispatchQueue.main.async{
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            self.ratingVC = _mainStoryboard.instantiateViewController(withIdentifier: "RatingViewController") as? RatingViewController
            self.present(self.ratingVC!, animated: true, completion: nil)
        }
    }
    
    // MARK: - Handling IBActions
    @IBAction func callButtonTapped(_ sender: Any) {
        if UtilClass.isNetworkAvailable(){
            if (!(userNameTextField.text! == "") && !UtilClass.isEmpty(userNameTextField.text!)) || !UtilClass.isEmpty(pad!.digitsTextField.text!) || (incCall != nil) || (outCall != nil) {
                
                let img: UIImage? = (sender as AnyObject).image(for: .normal)
                let data1: NSData? = img!.pngData() as NSData?
                
                if (data1?.isEqual(UIImage(named: "MakeCall.png")!.pngData()))! {
                    
                    callStateLabel.text = "Calling..."
                    callerNameLabel.text = pad?.digitsTextField.text
                    unhideActiveCallView()
                    var handle: String
                    if !(pad?.digitsTextField.text == "") {
                        handle = (pad?.digitsTextField.text!)!
                    }else if !(userNameTextField.text == "") {
                        handle = userNameTextField.text!
                    }else {
                        UtilClass.makeToast(kINVALIDSIPENDPOINTMSG)
                        return
                    }
                    
                    userNameTextField.text = ""
                    pad?.digitsTextField.text = ""
                    pad?.rawText = ""
                    CallKitInstance.sharedInstance.callUUID = UUID()
                    /* outgoing call */
                    performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: handle)
                    
                }else if (data1?.isEqual(UIImage(named: "EndCall.png")!.pngData()))! {
                    isItUserAction = true
                    performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true)
                }
            }else {
                UtilClass.makeToast(kINVALIDSIPENDPOINTMSG)
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
        UserDefaults.standard.set(true, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        holdButton.isHidden = true
        muteButton.isHidden = true
        keypadButton.isHidden = true
        hideButton.isHidden = false
        speakerButton.isHidden = true
        activeCallImageView.isHidden = true
        userNameTextField.text = ""
        view.bringSubviewToFront(hideButton)
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
        
        let data1: NSData? = img!.pngData() as NSData?
        
        if (data1?.isEqual(UIImage(named: "Unmute.png")!.pngData()))! {
            
            DispatchQueue.main.async{
                self.muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            }
            
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
        else {
            
            DispatchQueue.main.async{
                self.muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            }
            
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
        
        let data1: NSData? = img!.pngData() as NSData?
        
        if (data1?.isEqual(UIImage(named: "UnholdIcon.png")!.pngData()))! {
            
            DispatchQueue.main.async{
                self.holdButton.setImage(UIImage(named: "HoldIcon.png"), for: .normal)
            }
            
            if (incCall != nil) {
                incCall?.hold()
            }
            if (outCall != nil) {
                outCall?.hold()
            }
        }
        else {
            
            DispatchQueue.main.async{
                self.holdButton.setImage(UIImage(named: "UnholdIcon.png"), for: .normal)
            }
            
            if (incCall != nil) {
                incCall?.unhold()
            }
            if (outCall != nil) {
                outCall?.unhold()
            }
        }
    }
    
    
    @IBAction func speakerButtonTapped(_ sender: Any) {
        handleSpeaker()
    }
    
    
    func handleSpeaker() {
        let audioSession = AVAudioSession.sharedInstance()
        if(isSpeakerOn){
            self.speakerButton.setImage(UIImage(named: "Speaker.png"), for: .normal)
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            
            isSpeakerOn = false
        }else{
            self.speakerButton.setImage(UIImage(named: "Speaker_Selected.png"), for: .normal)
            
            /* Enable Speaker Phone mode */
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }

            isSpeakerOn = true
        }
    }
    
    func hideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = false
        callerNameLabel?.isHidden = true
        callStateLabel?.isHidden = true
        activeCallImageView?.isHidden = true
        muteButton?.isHidden = true
        keypadButton?.isHidden = true
        holdButton?.isHidden = true
        dialPadView?.isHidden = false
        userNameTextField?.isHidden = false
        userNameTextField?.isEnabled = true
        pad?.digitsTextField.isHidden = false
        pad?.showDeleteButton = true
        pad?.rawText = ""
        userNameTextField?.text = "SIP URI or Phone Number"
        self.tabBarController?.tabBar.isHidden = false
        self.tabBarController?.tabBar.isTranslucent = false
        callButton?.setImage(UIImage(named: "MakeCall.png"), for: .normal)
        timer?.reset()
        timer?.removeFromSuperview()
        timer = nil
        callStateLabel?.text = "Calling..."
        dialPadView?.alpha = 1.0
        dialPadView?.backgroundColor = UIColor.white
        
        //handleSpeaker()
        resetCallButtons()
    }
    
    func resetCallButtons() {
        self.speakerButton?.setImage(UIImage(named: "Speaker.png"), for: .normal)
        isSpeakerOn = false
        muteButton?.setImage(UIImage(named: "Unmute.png"), for: .normal)
        self.holdButton?.setImage(UIImage(named: "UnholdIcon.png"), for: .normal)
        
    }
    
    func unhideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = true
        callerNameLabel?.isHidden = false
        callStateLabel?.isHidden = false
        activeCallImageView?.isHidden = false
        muteButton?.isHidden = false
        keypadButton?.isHidden = false
        holdButton?.isHidden = false
        dialPadView?.isHidden = true
        userNameTextField?.isHidden = true
        pad?.digitsTextField.isHidden = true
        pad?.showDeleteButton = false
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.tabBar.isTranslucent = true
        callButton?.setImage(UIImage(named: "EndCall.png"), for: .normal)
    }
    
    
    /*
     * Handle audio interruptions
     * AVAudioSessionInterruptionTypeBegan
     * AVAudioSessionInterruptionTypeEnded
     */
    
    @objc func handleInterruption(_ notification: Notification){
        if self.incCall != nil || self.outCall != nil{
            guard let userInfo = notification.userInfo,
                  let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue) else {
                      return
                  }
            
            switch interruptionType {
                
            case .began:
                
                self.isItGSMCall = true
                Phone.sharedInstance.stopAudioDevice()
                print("----------AVAudioSessionInterruptionTypeBegan-------------")
                break
                
            case .ended:
                
                self.isItGSMCall = false
                
                // make sure to activate the session
                let error: Error? = nil
                try? AVAudioSession.sharedInstance().setActive(true)
                if nil != error {
                    print("AVAudioSession set active failed with error")
                    Phone.sharedInstance.startAudioDevice()
                    if incCall != nil && incCall?.state == Ongoing {
                        incCall?.unhold()
                    }
                    if outCall != nil && outCall?.state == Ongoing {
                        outCall?.unhold()
                    }
                }
                print("----------AVAudioSessionInterruptionTypeEnded-------------")
                break
            @unknown default:
                fatalError("issue here")
            }
            
        }
    }
    
    @objc func handleRouteChange(_ notification: Notification){
        
    }
    
    @objc func handleMediaServerReset(_ notification: Notification) {
        print("Media server has reset");
        //        // rebuild the audio chain
        Phone.sharedInstance.configureAudioSession()
        Phone.sharedInstance.startAudioDevice()
    }
    
    /*
     * Will be called when app terminates
     * End on going calls(If any)
     */
    
    @objc func appWillTerminate() {
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID ?? UUID() ,isFeedback: false)
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
        if incCall == nil && outCall == nil {
            if appendText == "" {
                userNameTextField.isEnabled = true
                userNameTextField.text = ""
            }
        } else {
            if (incCall != nil) {
                incCall?.sendDigits(dtmfText)
                userNameTextField.text = appendText
            }
            if (outCall != nil) {
                outCall?.sendDigits(dtmfText)
                userNameTextField.text = appendText
            }
        }
    }
    
    // MARK: - Handling TextField
    /**
     * Hide keyboard after user press 'return' key
     */
    func textFieldShouldReturn(_ theTextField: UITextField) -> Bool {
        if theTextField == userNameTextField {
            if theTextField.text == "" {
                theTextField.text = "SIP URI or Phone Number"
            }
            theTextField.resignFirstResponder()
        }
        return true
    }
    
    /**
     * Hide keyboard when text filed being clicked
     */
    @objc func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // return NO to disallow editing.
        let img: UIImage? = callButton.image(for: .normal)
        let data1: NSData? = img!.pngData() as NSData?
        if (data1?.isEqual(UIImage(named: "EndCall.png")!.pngData()))! {
            return false
        } else {
            userNameTextField.text = ""
            return true
        }
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




extension PlivoCallController:PlivoEndpointDelegate{
    
    func onPermissionDenied(_ error: Error) {
        print(error.localizedDescription)
    }
    
    func onLogin() {
        DispatchQueue.main.async{
            UtilClass.hideToastActivity()
            UtilClass.makeToast(kLOGINSUCCESS)
        }
        print("Ready to make a call");
    }
    
    /**
     * onLoginFailed delegate implementation.
     */
    func onLoginFailedWithError(_ error: Error) {
        DispatchQueue.main.async{
            UtilClass.makeToast(error.localizedDescription)
            UtilClass.hideToastActivity()
            print(error.localizedDescription)
            
            switch error._code {
            case 502:
                //Bad Gateway
                break
                
            case 503:
                //Service Unavailable
                break
                
            default:
                UtilClass.setUserAuthenticationStatus(false)
                UserDefaults.standard.removeObject(forKey: kUSERNAME)
                UserDefaults.standard.removeObject(forKey: kPASSWORD)
                UserDefaults.standard.synchronize()
                let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC: LoginViewController? = _mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
                Phone.sharedInstance.setDelegate(loginVC!)
                let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
                _appDelegate?.window?.rootViewController = loginVC
                break
            }
        }
    }
    
    /**
     * onLogout delegate implementation.
     */
    func onLogout() {
        DispatchQueue.main.async{
            
            if (CallKitInstance.sharedInstance.callUUID != nil){
                self.performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: false)
            }
            
            UtilClass.makeToast(kLOGOUTSUCCESS)
            UtilClass.setUserAuthenticationStatus(false)
            UserDefaults.standard.removeObject(forKey: kUSERNAME)
            UserDefaults.standard.removeObject(forKey: kPASSWORD)
            UserDefaults.standard.removeObject(forKey: kACCESSTOKEN)
            UserDefaults.standard.synchronize()
            UtilClass.hideToastActivity()
            
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC: LoginViewController? = _mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
            Phone.sharedInstance.setDelegate(loginVC!)
            let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            _appDelegate?.window?.rootViewController = loginVC
        }
    }
    
    /**
     * onIncomingCall delegate implementation
     */
    
    func onIncomingCall(_ incoming: PlivoIncoming) {
        DispatchQueue.main.async{
            self.ratingVC?.dismiss(animated: true, completion: nil)
        }
        print("Call id in incoming is:")
        isItUserAction = true
        
        CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
        CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
        CallInfo.addCallsInfo(callInfo:[incoming.fromUser,Date()])
        
        print("Incoming Call from %@", incoming.fromContact);
        print("Call id in incoming is: \(String(describing: incoming.callId))")
        /* assign incCall var */
        incCall = incoming
        outCall = nil
        CallKitInstance.sharedInstance.callUUID = UUID()
        reportIncomingCall(from: incoming.fromUser, with: CallKitInstance.sharedInstance.callUUID!)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            DispatchQueue.main.async {
                self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[2]
                self.userNameTextField.text = ""
                self.pad?.digitsTextField.text = ""
                self.pad?.rawText = ""
                self.callerNameLabel.text = incoming.fromUser
                self.callStateLabel.text = "Incoming call..."
            }
        }
    }
    
    func onIncomingCallConnected(_ incoming: PlivoIncoming) {
        print("- Incoming call answered");
        print("Call id in incoming answered is: \(String(describing: incoming.callId)) and voice flow is started")
        isIncomingCallAnswered = true
    }
    
    
    /**
     * onIncomingCallAnswered delegate implementation.
     */
    
    func onIncomingCallAnswered(_ incoming: PlivoIncoming) {
        print("- Incoming call answered");
        print("Call id in incoming answered is: \(String(describing: incoming.callId))")
    }
    
    /**
     * onIncomingCallInvalid delegate implementation.
     */
    
    func onIncomingCallInvalid(_ incoming: PlivoIncoming) {
        print("- Incoming call is invalid");
        print("Call id in incoming call invalid is: \(String(describing: incoming.callId))")
        if (incCall != nil) {
            self.isItUserAction = true
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true)
            incCall = nil
        }
        callSubmitFeddbackUI()
    }
    
    
    /**
     * onIncomingCallHangup delegate implementation.
     */
    
    func onIncomingCallHangup(_ incoming: PlivoIncoming) {
        print("- Incoming call ended");
        print("Call id in incoming hangup is: \(String(describing: incoming.callId))")
        if (incCall != nil) {
            self.isItUserAction = true
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true)
            incCall = nil
        }
        isIncomingCallAnswered = false
        callSubmitFeddbackUI()
    }
    
    /**
     * onIncomingCallRejected implementation.
     */
    func onIncomingCallRejected(_ incoming: PlivoIncoming) {
        /* log it */
        print("Call id in incoming rejected is: \(String(describing: incoming.callId))")
        self.isItUserAction = true
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true)
        incCall = nil
        callSubmitFeddbackUI()
    }
    
    /**
     * onOutgoingCallAnswered delegate implementation
     */
    func onOutgoingCallAnswered(_ call: PlivoOutgoing) {
        print("Call id in Answerd is: \(String(describing: call.callId))")
        
        print("- On outgoing call answered");
        
        DispatchQueue.main.async{
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
            CallKitInstance.sharedInstance.callKitProvider?.reportOutgoingCall(with: CallKitInstance.sharedInstance.callUUID!, connectedAt: Date())
        }
    }
    
    /**
     * onOutgoingCallHangup delegate implementation.
     */
    
    func onOutgoingCallHangup(_ call: PlivoOutgoing) {
        print("Call id in Hangup is: \(String(describing: call.callId))")
        if (outCall != nil) {
            self.isItUserAction = true
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true)
            outCall = nil
        }
        callSubmitFeddbackUI()
    }
    
    func onCalling(_ call: PlivoOutgoing) {
        print("Call id in onCalling is: \(String(describing: call.callId))")
        print("On Caling");
    }
    
    /**
     * onOutgoingCallRinging delegate implementation.
     */
    func onOutgoingCallRinging(_ call: PlivoOutgoing) {
        print("Call id in Ringing is: \(String(describing: call.callId))")
        
        DispatchQueue.main.async{
            self.callStateLabel.text = "Ringing..."
        }
    }
    
    /**
     * mediaMetrics delegate implementation
     */
    func mediaMetrics(_ metricdata: [AnyHashable: Any]) {
        let active = metricdata["active"] as! Bool
        let type = metricdata["type"] as! String
        if active == true {
            UtilClass.makeToastWithStyle(String(format:"warning | %@", type))
        }
    }
    
    func speakingOnMute() {
        print("User Speaking on mute")
    }
    
    
    
    /**
     * onOutgoingCallrejected delegate implementation.
     */
    func onOutgoingCallRejected(_ call: PlivoOutgoing) {
        print("Call id in Rejected is: \(String(describing: call.callId))")
        
        self.isItUserAction = true
        
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true)
        callSubmitFeddbackUI()
    }
    
    /**
     * onOutgoingCallInvalid delegate implementation.
     */
    func onOutgoingCallInvalid(_ call: PlivoOutgoing) {
        print("Call id in Invalid is: \(String(describing: call.callId))")
        
        self.isItUserAction = true
        
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true)
        callSubmitFeddbackUI()
    }
    
    
    /**
     * onSubmitFeedback delegate implementation
     */
    
    func onFeedbackSuccess(_ statusCode: Int) {
        print("Success  :  ",statusCode)
    }
    
    func onFeedbackValidationError(_ validationErrorMessage: String){
        print("Validation error  :  ",validationErrorMessage)
    }
    
    func onFeedbackFailure(_ error: Error) {
        print("Submit Feedback Failure ")
    }
    
}


extension PlivoCallController{
    
    // MARK: - CallKit Actions
    func performStartCallAction(with uuid: UUID, handle: String) {
        hideActiveCallView()
        unhideActiveCallView()
        
        print("Outgoing call uuid is: %@", uuid);
        CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
        CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
        print("provider:performStartCallActionWithUUID:");
        if uuid.uuidString == "" || handle == "" {
            print("UUID or Handle nil");
            return
        }
        
        CallInfo.addCallsInfo(callInfo:[handle,Date()])
        
        var newHandleString: String = handle.replacingOccurrences(of: "-", with: "")
        if (newHandleString as NSString).range(of: "+91").location == NSNotFound && (newHandleString.count) == 10 {
            newHandleString = "+91\(newHandleString)"
        }
        let callHandle = CXHandle(type: .generic, value: newHandleString)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        let transaction = CXTransaction(action:startCallAction)
        CallKitInstance.sharedInstance.callKitCallController?.request(transaction, completion: {(_ error: Error?) -> Void in
            if error != nil {
                print("StartCallAction transaction request failed: %@", error.debugDescription);
                DispatchQueue.main.async {
                    UtilClass.makeToast(kSTARTACTIONFAILED)
                }
            }
            else {
                print("StartCallAction transaction request successful");
                let callUpdate = CXCallUpdate()
                callUpdate.remoteHandle = callHandle
                callUpdate.supportsDTMF = true
                callUpdate.supportsHolding = true
                callUpdate.supportsGrouping = false
                callUpdate.supportsUngrouping = false
                callUpdate.hasVideo = false
                DispatchQueue.main.async{
                    self.callerNameLabel.text = handle
                    self.callStateLabel.text = "Calling..."
                    self.unhideActiveCallView()
                    CallKitInstance.sharedInstance.callKitProvider?.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
                }
            }
        })
    }
    
    func reportIncomingCall(from: String, with uuid: UUID) {
        
        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        
        CallKitInstance.sharedInstance.callKitProvider?.reportNewIncomingCall(with: uuid, update: callUpdate, completion: {(_ error: Error?) -> Void in
            if error != nil {
                print("Failed to report incoming call successfully: %@", error.debugDescription);
                //[UtilityClass makeToast:kREQUESTFAILED];
                Phone.sharedInstance.stopAudioDevice()
                if (self.incCall != nil) {
                    print("Call id in incoming call error is:")
                    print(self.incCall?.callId as Any)
                    if self.incCall?.state != Ongoing {
                        print("Incoming call - Reject");
                        self.incCall?.reject()
                    }
                    else {
                        print("Incoming call - Hangup");
                        self.incCall?.hangup()
                    }
                    self.incCall = nil
                }
            }
            else {
                print("Incoming call successfully reported.");
                Phone.sharedInstance.configureAudioSession()
            }
        })
    }
    
    func performEndCallAction(with uuid: UUID , isFeedback: Bool) {
        
        DispatchQueue.main.async(execute: {() -> Void in
            
            print("performEndCallActionWithUUID: %@",uuid);
            let endCallAction = CXEndCallAction(call: uuid)
            let trasanction = CXTransaction(action:endCallAction)
            CallKitInstance.sharedInstance.callKitCallController?.request(trasanction, completion: {(_ error: Error?) -> Void in
                if error != nil {
                    print("EndCallAction transaction request failed: %@", error.debugDescription);
                    
                    DispatchQueue.main.async(execute: {() -> Void in
                        
                        Phone.sharedInstance.stopAudioDevice()
                        
                        if (self.incCall != nil) {
                            if self.incCall?.state != Ongoing {
                                print("Incoming call - Reject");
                                self.incCall?.reject()
                            }
                            else {
                                print("Incoming call - Hangup");
                                self.incCall?.hangup()
                            }
                            self.incCall = nil
                        }
                        
                        if (self.outCall != nil) {
                            print("Outgoing call - Hangup");
                            self.outCall?.hangup()
                            self.outCall = nil
                        }
                        if (!isFeedback){
                            self.hideActiveCallView()
                        }
                        
                        self.tabBarController?.tabBar.isHidden = false
                        self.tabBarController?.tabBar.isTranslucent = false
                        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[1]
                        
                    })
                }
                else {
                    
                    print("EndCallAction transaction request successful");
                    
                    
                }
            })
        })
    }
    
    
    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded == true {
            print("CXCallState : Disconnected");
            if (incCall != nil && incCall?.state == Ongoing) || (outCall != nil && outCall?.state == Ongoing) {
                let setHeldCallAction = CXSetHeldCallAction(call: CallKitInstance.sharedInstance.callUUID!, onHold: false)
                let transaction = CXTransaction()
                transaction.addAction(setHeldCallAction)
                CallKitInstance.sharedInstance.callKitCallController?.request(transaction, completion: {(_ error: Error?) -> Void in
                    if error != nil {
                        print("Unhold error", error.debugDescription)
                    }
                })
            }
        } else  if call.hasConnected == true {
            print("CXCallState : Connected");
        } else if call.isOutgoing == true {
            print("CXCallState : Dialing");
        } else {
            print("CXCallState : Incoming");
        }
    }
    
    
    // MARK: - CXProvider Handling
    
    func providerDidReset(_ provider: CXProvider) {
        print("ProviderDidReset");
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin");
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("provider:didActivateAudioSession");
        Phone.sharedInstance.startAudioDevice()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:");
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("provider:timedOutPerformingAction:");
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("provider:performStartCallAction:");
        Phone.sharedInstance.configureAudioSession()
        //Set extra headers
        let extraHeaders: [AnyHashable: Any] = [
            "X-PH-Header1" : "Value1",
            "X-PH-Header2" : "Value2"
        ]
        
        let dest: String = action.handle.value
        //Make the call
        var error: NSError? = nil
        outCall = Phone.sharedInstance.call(withDest: dest, andHeaders: extraHeaders, error: &error)
        action.fulfill(withDateStarted: Date())
        if (error != nil) {
            outCall = nil
            UtilClass.makeToast((error?.localizedDescription)!)
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!, isFeedback: true )
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if action.isOnHold {
            if (incCall != nil) {
                incCall?.hold()
            }
            if (outCall != nil) {
                outCall?.hold()
            }
        }else {
            if (incCall != nil) {
                incCall?.unhold()
            }
            if (outCall != nil) {
                outCall?.unhold()
            }
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if action.isMuted {
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            }
            if (incCall != nil) {
                incCall?.unmute()
            }
            if (outCall != nil) {
                outCall?.unmute()
            }
        }
        else {
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            }
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider:performAnswerCallAction:");
        //Answer the call
        if (incCall != nil) {
            CallKitInstance.sharedInstance.callUUID = action.callUUID
            incCall?.answer()
        }
        outCall = nil
        action.fulfill()
        DispatchQueue.main.async{
            self.unhideActiveCallView()
            self.muteButton.isEnabled = true
            self.holdButton.isEnabled = true
            self.keypadButton.isEnabled = true
        }
        answerTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(invalidateTimerWhenAnswered), userInfo: nil, repeats: true)
    }
    
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        print("provider:performPlayDTMFCallAction:");
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
        DispatchQueue.main.async{
            print("provider:performEndCallAction:");
            
            Phone.sharedInstance.stopAudioDevice()
            if (self.incCall != nil) {
                if self.incCall?.state != Ongoing {
                    print("Incoming call - Reject");
                    self.incCall?.reject()
                }
                else {
                    print("Incoming call - Hangup");
                    self.incCall?.hangup()
                }
                self.incCall = nil
            }
            if (self.outCall != nil) {
                print("Outgoing call - Hangup");
                self.outCall?.hangup()
                self.outCall = nil
            }
            action.fulfill()
            self.isItUserAction = false
            self.tabBarController?.tabBar.isHidden = false
            self.tabBarController?.tabBar.isTranslucent = false
            self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[1]
        }
    }
}
