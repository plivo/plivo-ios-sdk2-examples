
//
//  LoginViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        loginButton.layer.cornerRadius = UIScreen.main.bounds.size.height * 0.04401408451
        
        self.userNameTextField.delegate = self
        self.passwordTextField.delegate = self

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        userNameTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            // ...
            if touch.phase == .began
            {
                userNameTextField.resignFirstResponder()
                passwordTextField.resignFirstResponder()

            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        if UtilClass.isEmpty(userNameTextField.text!) == true {
            UtilClass.makeToast(kINVALIDENTRIESMSG)
        } else if UtilClass.isEmpty(passwordTextField.text!) == true {
            UtilClass.makeToast(kINVALIDENTRIESPSWDMSG)
        } else {
            if UtilClass.isNetworkAvailable() {
                view.isUserInteractionEnabled = false
                UtilClass.makeToastActivity()
                Phone.sharedInstance.login(withUserName: userNameTextField.text!, andPassword: passwordTextField.text!)
            }
            else {
                UtilClass.makeToast(kNOINTERNETMSG)
            }
        }
    }

    /**
     * onLogin delegate implementation.
     */
    
    func onLogin() {
        
        DispatchQueue.main.async(execute: {() -> Void in
            
            self.userNameTextField.delegate = nil
            self.passwordTextField.delegate = nil

            UtilClass.hideToastActivity()
            UtilClass.makeToast(kLOGINSUCCESS)
            /**
             *  If user already logged in with G+ signIn
             *
             */
            if !(UserDefaults.standard.object(forKey: kUSERNAME) != nil) {
                
                UserDefaults.standard.set(self.userNameTextField.text, forKey: kUSERNAME)
                UserDefaults.standard.set(self.passwordTextField.text, forKey: kPASSWORD)
                UserDefaults.standard.synchronize()
            }
            
            UtilClass.setUserAuthenticationStatus(true)
            //Default View Controller: ContactsViewController
            //Landing page
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            let tabbarControler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
            let plivoVC: PlivoCallController? = (tabbarControler?.viewControllers?[2] as? PlivoCallController)
            Phone.sharedInstance.setDelegate(plivoVC!)
            tabbarControler?.selectedViewController = tabbarControler?.viewControllers?[1]
            _appDelegate?.window?.rootViewController = tabbarControler
            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            appDelegate?.voipRegistration()
        })
    }
    
    /**
     * onLoginFailed delegate implementation.
     */
    func onLoginFailedWithError(_ error: Error!) {
        DispatchQueue.main.async(execute: {() -> Void in
            
            self.userNameTextField.delegate = self
            self.passwordTextField.delegate = self

            UtilClass.setUserAuthenticationStatus(false)
            
            UserDefaults.standard.removeObject(forKey: kUSERNAME)
            UserDefaults.standard.removeObject(forKey: kPASSWORD)
            UserDefaults.standard.synchronize()
            
            UtilClass.hideToastActivity()
            UtilClass.makeToast(error.localizedDescription)
            self.view.isUserInteractionEnabled = true
        })
    }

}
