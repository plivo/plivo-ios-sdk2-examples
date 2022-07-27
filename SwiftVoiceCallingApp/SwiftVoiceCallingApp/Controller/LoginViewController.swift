
//
//  LoginViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import PlivoVoiceKit

class LoginViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var jwtSwitch: UISwitch!
    @IBOutlet weak var jwtTextView: UITextView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 10
        jwtSwitch.isOn = false
        self.userNameTextField.delegate = self
        
        self.passwordTextField.delegate = self
        jwtTextView.text = "Paste your Access Token here"
        jwtTextView.textColor = UIColor.lightGray
        jwtTextView.delegate = self
        jwtTextView.layer.cornerRadius = 10
        
        jwtTextView.text = kACCESSTOKEN
        self.userNameTextField.text = kUSERNAME
        self.passwordTextField.text = kPASSWORD
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        if jwtSwitch.isOn {
            guard let accessToken = jwtTextView.text, UtilClass.isEmpty(accessToken) == false else {
                return UtilClass.makeToast(kINVALIDENTRIESUSNMSG)
            }
            
            
            if UtilClass.isNetworkAvailable() {
                view.isUserInteractionEnabled = false
                UtilClass.makeToastActivity()
                let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
                if let token = appDelegate?.deviceToken{
                    appDelegate?.didUpdatePushCredentials = true
                    Phone.sharedInstance.login(withAccessToken: accessToken, deviceToken: token)
                }else{
                    Phone.sharedInstance.login(withAccessToken: accessToken)
                }
            }else {
                UtilClass.makeToast(kNOINTERNETMSG)
            }
        } else {
            guard let userName = userNameTextField.text, UtilClass.isEmpty(userName) == false else {
                return UtilClass.makeToast(kINVALIDENTRIESUSNMSG)
            }
            
            guard let password = passwordTextField.text, UtilClass.isEmpty(password) == false else {
                return UtilClass.makeToast(kINVALIDENTRIESPSWDMSG)
            }
            
            if UtilClass.isNetworkAvailable() {
                view.isUserInteractionEnabled = false
                UtilClass.makeToastActivity()
                let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
                if let token = appDelegate?.deviceToken{
                    appDelegate?.didUpdatePushCredentials = true
                    Phone.sharedInstance.login(withUserName: userName, andPassword: password, deviceToken: token)
                }else{
                    Phone.sharedInstance.login(withUserName: userName, andPassword: password)
                }
            }else {
                UtilClass.makeToast(kNOINTERNETMSG)
            }
        }
       
    }
    
    @IBAction func jwtToggle(_ sender: UISwitch) {

        if sender.isOn {
            userNameTextField.isHidden = true
            passwordTextField.isHidden = true
            jwtTextView.isHidden = false
        } else {
            userNameTextField.isHidden = false
            passwordTextField.isHidden = false
            jwtTextView.isHidden = true
        }
        print("jwt switch status is \(jwtSwitch.isOn)")
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if jwtTextView.textColor == UIColor.lightGray {
            jwtTextView.text = nil
            jwtTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if jwtTextView.text.isEmpty {
            jwtTextView.text = "Paste your Access Token here"
            jwtTextView.textColor = UIColor.lightGray
        }
    }
    
    
    /**
     * Hide keyboard after user press 'return' key
     */
    
    func textFieldShouldReturn(_ theTextField: UITextField) -> Bool {
        theTextField.resignFirstResponder()
        return true
    }
    
    /**
     * Hide keyboard when text filed being clicked
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    /**
     *  Hide keyboard when user touches on UI
     *
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.phase == .began{
                userNameTextField.resignFirstResponder()
                passwordTextField.resignFirstResponder()
                jwtTextView.resignFirstResponder()
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
}


extension LoginViewController: PlivoEndpointDelegate{
    /**
     * onLogin delegate implementation.
     */
    
    @objc func onLogin() {
        DispatchQueue.main.async{ [self] in
            self.userNameTextField.delegate = nil
            self.passwordTextField.delegate = nil
            
            UtilClass.hideToastActivity()
            UtilClass.makeToast(kLOGINSUCCESS)
            
            if (self.jwtSwitch.isOn && self.jwtTextView.text != nil && !self.userNameTextField.text!.isEmpty) {
                UserDefaults.standard.set(self.jwtTextView.text, forKey: kACCESSTOKEN)
                UserDefaults.standard.synchronize()
            } else if (!self.jwtSwitch.isOn && self.userNameTextField.text != nil && !self.userNameTextField.text!.isEmpty) {
                UserDefaults.standard.set(self.userNameTextField.text, forKey: kUSERNAME)
                UserDefaults.standard.set(self.passwordTextField.text, forKey: kPASSWORD)
                UserDefaults.standard.synchronize()
            }
//            if !(UserDefaults.standard.object(forKey: kUSERNAME) != nil) {
//                UserDefaults.standard.set(self.userNameTextField.text, forKey: kUSERNAME)
//                UserDefaults.standard.set(self.passwordTextField.text, forKey: kPASSWORD)
//                UserDefaults.standard.synchronize()
//            }
            
            UtilClass.setUserAuthenticationStatus(true)
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            let tabbarControler: UITabBarController? = mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
            let plivoVC: PlivoCallController? = (tabbarControler?.viewControllers?[2] as? PlivoCallController)
            Phone.sharedInstance.setDelegate(plivoVC!)
            tabbarControler?.selectedViewController = tabbarControler?.viewControllers?[1]
            appDelegate?.window?.rootViewController = tabbarControler
        }
    }
    
    /**
     * onLoginFailed delegate implementation.
     */
    func onLoginFailedWithError(_ error: Error!) {
        DispatchQueue.main.async{
            self.userNameTextField.delegate = self
            self.passwordTextField.delegate = self
            
            UtilClass.setUserAuthenticationStatus(false)
            
            UserDefaults.standard.removeObject(forKey: kUSERNAME)
            UserDefaults.standard.removeObject(forKey: kPASSWORD)
            UserDefaults.standard.synchronize()
            
            UtilClass.hideToastActivity()
            UtilClass.makeToast(error.localizedDescription)
            self.view.isUserInteractionEnabled = true
        }
    }
    
}
