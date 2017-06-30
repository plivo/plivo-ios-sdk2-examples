
//
//  LoginViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAnalytics
import Crashlytics
import Fabric

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, APIRequestManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    
    var apiMangerInstance = APIRequestManager.apiCallManagerSharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        loginButton.layer.cornerRadius = UIScreen.main.bounds.size.height * 0.04401408451
        googleButton.layer.cornerRadius = UIScreen.main.bounds.size.height * 0.04401408451
        
        apiMangerInstance.delegate = self
        
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
        
        if false == UtilClass.isEmpty(userNameTextField.text!) && false == UtilClass.isEmpty(passwordTextField.text!) && !(userNameTextField.text! == "SIP Username")
        {
            if UtilClass.isNetworkAvailable() {
                view.isUserInteractionEnabled = false
                UtilClass.makeToastActivity()
                Phone.sharedInstance.login(withUserName: userNameTextField.text!, andPassword: passwordTextField.text!)
                FIRAnalytics.logEvent(withName: "Login", parameters: ["Username": userNameTextField.text! as NSObject])
            }
            else {
                UtilClass.makeToast(kNOINTERNETMSG)
            }
        }
        else {
            UtilClass.makeToast(kINVALIDENTRIESMSG)
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
                Crashlytics.sharedInstance().setUserName(self.userNameTextField.text)
                FIRAnalytics.logEvent(withName: "LoginSuccess", parameters: ["Type": "Direct" as NSObject, "Username": self.userNameTextField.text! as NSObject])
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
    func onLoginFailed() {
        DispatchQueue.main.async(execute: {() -> Void in
            
            self.userNameTextField.delegate = self
            self.passwordTextField.delegate = self

            UtilClass.setUserAuthenticationStatus(false)
            
            UserDefaults.standard.removeObject(forKey: kUSERNAME)
            UserDefaults.standard.removeObject(forKey: kPASSWORD)
            UserDefaults.standard.synchronize()
            
            GIDSignIn.sharedInstance().signOut()
            UtilClass.hideToastActivity()
            UtilClass.makeToast(kLOGINFAILMSG)
            self.view.isUserInteractionEnabled = true
            FIRAnalytics.logEvent(withName: "LoginFailed", parameters: ["Username": kUSERNAME as NSObject])
        })
    }
    
    //Login with Google account
    
    @IBAction func googleloginTapped(_ sender: Any) {
        
        FIRAnalytics.logEvent(withName: "GoogleSignIn", parameters: nil)
        self.view.isUserInteractionEnabled = false
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = "900363642731-b014hv4khou88fokat0b7dkv3mocvtrm.apps.googleusercontent.com"
        // Replace with the value of CLIENT_ID key in GoogleService-Info.plist
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        GIDSignIn.sharedInstance().signIn()
        
    }
    
    // MARK: -Google SignIn Delegate
    //pragma mark - Google SignIn Delegate
    func sign(inWillDispatch signIn: GIDSignIn, error: Error?) {
        
    }
    
    // Dismiss the "Sign in with Google" view
    func sign(_ signIn: GIDSignIn, dismiss viewController: UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    // Present a view that prompts the user to sign in with Google
    func sign(_ signIn: GIDSignIn, present viewController: UIViewController) {
        present(viewController, animated: true, completion: { _ in })
    }
    
    //completed sign In
    func sign(_ signIn: GIDSignIn, didSignInFor user: GIDGoogleUser, withError error: Error?)
    {
        
        if(user.profile != nil)
        {
            if (user.profile.email as NSString).range(of: "@plivo.com").location == NSNotFound {
                FIRAnalytics.logEvent(withName: "InvalidEmail", parameters: nil)
                GIDSignIn.sharedInstance().signOut()
                UtilClass.makeToast(kINVALIDEMAIL)
                self.view.isUserInteractionEnabled = true
                return
            }
            else {
                
                if !UtilClass.isEmpty(user.profile.email) {
                    UtilClass.makeToastActivity()
                    getSIPEndpointCredentials(user.profile.email)
                    FIRAnalytics.logEvent(withName: "GoogleSignIn", parameters: ["Name": user.profile.name! as NSObject, "Email": user.profile.email! as NSObject])
                    Crashlytics.sharedInstance().setUserName(user.profile.name)
                    Crashlytics.sharedInstance().setUserEmail(user.profile.email)
                }
                else {
                    FIRAnalytics.logEvent(withName: "InvalidEmail", parameters: nil)
                    GIDSignIn.sharedInstance().signOut()
                    UtilClass.makeToast(kINVALIDEMAIL)
                    self.view.isUserInteractionEnabled = true
                    return
                }
            }
        }else{
            UtilClass.makeToast(kINVALIDEMAIL)
            self.view.isUserInteractionEnabled = true
            return
        }
    }

    /*
     * API Call to SIP Endpoint
     * To get Array of SIP Endpoints
     *
     */
    
    func getSIPEndpointCredentials(_ emailId: String)
    {
        if UtilClass.isNetworkAvailable()
        {
            
            self.apiMangerInstance.getTheResponceFromUrl(urlString:"\(kSERVERURL)\(emailId)" , parameters: [:])
            
        }
        else
        {
            FIRAnalytics.logEvent(withName: "JsonResponseFail", parameters: ["Error": kNOINTERNETMSG as NSObject])
            UtilClass.makeToast(kNOINTERNETMSG)
        }
    }


    //MARK: ServiceDelegate Methods
    func didGetResponseSuccessfully(jsonData : Any){
        
        OperationQueue.main.addOperation {
            
            let sipArray = jsonData as! [Any]
            
            let dict: [AnyHashable: Any] = sipArray[1] as! [AnyHashable : Any]
            UserDefaults.standard.set(sipArray[0], forKey: kUSERNAME)
            UserDefaults.standard.set("7bjbk5ib7f23ie05be2h5713hf1hl774j94c88244e2185b", forKey: kPASSWORD)
            Crashlytics.sharedInstance().setUserName(sipArray[0] as? String)
            var sipContactsArray = [[String:Any]]() /* capacity: dict.keys.count */
            
            let lazyMapCollection = dict.keys
            let emailArray = Array(lazyMapCollection)

            let lazyMapCollection2 = dict.values
            let endpointArray = Array(lazyMapCollection2)

            
            for i in 0..<emailArray.count
            {
                sipContactsArray.append(["eMail" : emailArray[i], "endPoint" : endpointArray[i]])

            }
            
            UserDefaults.standard.set(sipContactsArray, forKey: kSIPDETAILS)
            UserDefaults.standard.synchronize()
            
            Phone.sharedInstance.setDelegate(self)
            print("Username in G+ \(String(describing: UserDefaults.standard.object(forKey: kUSERNAME)))")
            print("Password in G+ \(String(describing: UserDefaults.standard.object(forKey: kPASSWORD)))")
            Phone.sharedInstance.login(withUserName: UserDefaults.standard.object(forKey: kUSERNAME) as! String, andPassword: UserDefaults.standard.object(forKey: kPASSWORD) as! String)
            FIRAnalytics.logEvent(withName: "JsonResponseSuccess", parameters: nil)
            
        }
    }
    
    func didGetResponseFail(error : String){
        
        print("Error is: \(error.description)")

    }
}
