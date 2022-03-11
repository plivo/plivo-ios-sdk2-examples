
//
//  LoginViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import PlivoVoiceKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 10
        
        self.userNameTextField.delegate = self
        self.passwordTextField.delegate = self
        
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
        DispatchQueue.main.async{
            self.userNameTextField.delegate = nil
            self.passwordTextField.delegate = nil
            
            UtilClass.hideToastActivity()
            UtilClass.makeToast(kLOGINSUCCESS)
            
            if (self.userNameTextField.text != nil && !self.userNameTextField.text!.isEmpty) {
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
