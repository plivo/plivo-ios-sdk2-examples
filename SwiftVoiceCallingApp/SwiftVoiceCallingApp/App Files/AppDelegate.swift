//
//  AppDelegate.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 03/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import PushKit
import Crashlytics
import Fabric
import FirebaseAnalytics
import Google
import AVFoundation
import Intents
import UserNotifications
import GoogleSignIn

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var viewController: ContactsViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Fabric.with([Crashlytics.self])
        // Use Firebase library to configure APIs
        FIRApp.configure()
        
        var configureError: Error?
        GGLContext.sharedInstance().configuration
        assert(configureError == nil, "Error configuring Google services: \(String(describing: configureError))")
        
        //For VOIP Notificaitons
        if #available(iOS 10.0, *)
        {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization.
            }
            application.registerForRemoteNotifications()
        }
        
        //Request Record permission
        let session = AVAudioSession.sharedInstance()
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("granted")
                    
                    do {
                        try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
                        try session.setActive(true)
                    }
                    catch {
                        
                        print("Couldn't set Audio session category")
                    }
                } else{
                    print("not granted")
                }
            })
        }
        
        //Request Siri authorization
        INPreferences.requestSiriAuthorization({(_ status: INSiriAuthorizationStatus) -> Void in
            if status == .authorized {
                print("User gave permission to use Siri")
            }
            else {
                print("User did not give permission to use Siri")
            }
        })
        //One time signIn
        //Save User's credentials in NSUserDefaults
        //Check Authenticaiton status
        if UtilClass.getUserAuthenticationStatus() {
            //Default View Controller: ContactsViewController
            //Landing page
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarContrler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
            viewController = tabBarContrler?.viewControllers?[1] as? ContactsViewController
            //ContactsViewController
            Phone.sharedInstance.setDelegate(viewController!)
            tabBarContrler?.selectedViewController = tabBarContrler?.viewControllers?[1]
            window?.rootViewController = tabBarContrler
            //Get Username and Password from NSUserDefaults and Login
            Phone.sharedInstance.login(withUserName: UserDefaults.standard.object(forKey: kUSERNAME) as! String, andPassword: UserDefaults.standard.object(forKey: kPASSWORD) as! String)
        }
        else {
            //First time Log-In setup
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC: LoginViewController? = _mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
            Phone.sharedInstance.setDelegate(loginVC!)
            window?.rootViewController = loginVC
        }
        
        return true
    }
    
    // Register for VoIP notifications
    func voipRegistration() {
        
        let mainQueue = DispatchQueue.main
        // Create a push registry object
        let voipResistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipResistry.delegate = (self as? PKPushRegistryDelegate)
        //Set the push type to VOIP
        voipResistry.desiredPushTypes = Set<AnyHashable>([PKPushType.voIP]) as? Set<PKPushType>
    }
    
    // MARK: PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {
        
        NSLog("pushRegistry:didUpdatePushCredentials:forType:");
        
        if credentials.token.count == 0 {
            print("VOIP token NULL")
            return
        }
        print("Credentials token: \(credentials.token)")
        FIRAnalytics.logEvent(withName: "PushKit", parameters: ["Token": credentials.token as NSObject])
        Phone.sharedInstance.registerToken(credentials.token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenForType type: PKPushType) {
        NSLog("pushRegistry:didInvalidatePushTokenForType:")
        
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:")
        
        if (type == PKPushType.voIP) {
            
            DispatchQueue.main.async(execute: {() -> Void in
                FIRAnalytics.logEvent(withName: "PushKit", parameters: ["Payload": payload.dictionaryPayload as NSObject])
                Phone.sharedInstance.relayVoipPushNotification(payload.dictionaryPayload)
            })
        }
    }
    

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (_ options: UNNotificationPresentationOptions) -> Void) {
        //Called when a notification is delivered to a foreground app.
        print("willPresentNotification Userinfo \(notification.request.content.userInfo)")
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //Called to let your app know which action was selected by the user for a given notification.
        print("didReceiveNotificationResponse Userinfo \(response.notification.request.content.userInfo)")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    @nonobjc func application(_ app: UIApplication, open url: URL, options: [String: Any]) -> Bool {
        
        return application(app, processOpenURLAction: url, sourceApplication:UIApplicationOpenURLOptionsKey.sourceApplication.rawValue, annotation: UIApplicationOpenURLOptionsKey.annotation, iosVersion: 9)
        
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return self.application(application, processOpenURLAction: url, sourceApplication: sourceApplication!, annotation: annotation, iosVersion: 8)
    }
    
    func application(_ application: UIApplication, processOpenURLAction url: URL, sourceApplication: String, annotation: Any, iosVersion version: Int) -> Bool {
        //Deep linking
        if url.absoluteString.contains("plivo://") {
            let latlngArray: [Any] = url.absoluteString.components(separatedBy: "://")
            handleDeepLinking(latlngArray[1] as! String)
            FIRAnalytics.logEvent(withName: "DeepLinking", parameters: ["Link": url.absoluteString as NSObject])
            return true
        }
        else {
            return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping (_ restorableObjects: [Any]?) -> Void) -> Bool {
        if UtilClass.getUserAuthenticationStatus() {
            //When user taps on iPhone's native call list
            //This method will be called only if the call is related to Plivo
            let interaction: INInteraction? = userActivity.interaction
            let startAudioCallIntent: INStartAudioCallIntent? = (interaction?.intent as? INStartAudioCallIntent)
            let contact: INPerson? = startAudioCallIntent?.contacts?[0]
            print("\(String(describing: contact?.displayName))")
            let personHandle: INPersonHandle? = contact?.personHandle
            let contactValue: String? = personHandle?.value
            /*
             * Handle Siri input
             * From Siri we will get contact name
             * Check whether this name exists in phone contacts
             * If yes make a call
             */
            if !(contactValue != nil) && ((contact?.displayName) != nil)
            {
                //PlivoCallController handles the incoming/outgoing calls
                let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let tabBarContrler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
                let plivoVC: ContactsViewController? = (tabBarContrler?.viewControllers?[1] as? ContactsViewController)
                tabBarContrler?.selectedViewController = tabBarContrler?.viewControllers?[1]
                plivoVC?.makeCall(withSiriName: (contact?.displayName)!)
                window?.rootViewController = tabBarContrler
            }
            else
            {
                //Maintaining unique Call Id
                //Singleton
                CallKitInstance.sharedInstance.callUUID = UUID()
                //PlivoCallController handles the incoming/outgoing calls
                let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let tabBarContrler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
                let plivoVC: PlivoCallController? = (tabBarContrler?.viewControllers?[2] as? PlivoCallController)
                tabBarContrler?.selectedViewController = tabBarContrler?.viewControllers?[2]
                Phone.sharedInstance.setDelegate(plivoVC!)
                plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: contactValue!)
                window?.rootViewController = tabBarContrler
                FIRAnalytics.logEvent(withName: "INInteraction", parameters: ["Contact": contactValue! as NSObject])
            }
            return true
        }
        else {
            UtilClass.makeToast("Please login to make a call")
            return false
        }
    }

    func handleDeepLinking(_ phoneNumber: String) {
        
        //Maintaining unique Call Id
        //Singleton
        CallKitInstance.sharedInstance.callUUID = UUID()
        //PlivoCallController handles the incoming/outgoing calls
        let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarContrler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
        let plivoVC: PlivoCallController? = (tabBarContrler?.viewControllers?[2] as? PlivoCallController)
        tabBarContrler?.selectedViewController = tabBarContrler?.viewControllers?[2]
        Phone.sharedInstance.setDelegate(plivoVC!)
        plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber)
        window?.rootViewController = tabBarContrler
    }
}

