//
//  RatingViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Rahul Dhek on 03/06/19.
//  Copyright © 2019 Plivo. All rights reserved.
//

import UIKit

import CallKit
import AVFoundation
import PlivoVoiceKit
import ReachabilitySwift

class RatingViewController: UIViewController , PlivoEndpointDelegate{
    var viewController: ContactsViewController?
    
    @IBOutlet weak var fiveStarHiddenView: UIView!
    @IBOutlet weak var sendConsoleLog: UISwitch!
    @IBOutlet weak var comments: UITextView!
    
    @IBOutlet var issues: [UIButton]!
    var starRating=0;
    @IBOutlet var starButtons: [UIButton]!
    @IBAction func startButtonTapped(_ sender: UIButton) {
        self.starRating=sender.tag+1
        let tag = sender.tag
        for button in starButtons{
            if button.tag<=tag{
                button.setTitle("★", for: .normal)
            }else{
                button.setTitle("☆", for: .normal)
            }
        }
        if (sender.tag == 4){
            fiveStarHiddenView.isHidden = true
        }
        else{
            fiveStarHiddenView.isHidden = false
        }
    }
    
    
    
    
    @IBAction func onIssueTapped(_ sender: UIButton) {
        if sender.backgroundColor == UIColor.blue {
            sender.backgroundColor=UIColor.lightGray
        }
        else{
            sender.backgroundColor=UIColor.blue
        }
    }
    
    
    @IBAction func onSkipTapped(_ sender: Any) {
        let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        let tabbarControler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
        let plivoVC: PlivoCallController? = (tabbarControler?.viewControllers?[2] as? PlivoCallController)
        Phone.sharedInstance.setDelegate(plivoVC!)
        tabbarControler?.selectedViewController = tabbarControler?.viewControllers?[1]
        _appDelegate?.window?.rootViewController = tabbarControler
    }
    
    @IBAction func onSubmitButtonTapped(_ sender: Any) {
        var issueList = [AnyObject]()
        for issue in issues{
            if issue.backgroundColor == UIColor.blue{
                let issueName = issue.title(for: .normal)
                issueList.append(issueName as AnyObject)
            }
        }
        var validationMessage = ""
        var validationFlag = false
        if (starRating==0){
            validationFlag = true
            validationMessage = "Rating cannot be empty"
        }
        
        else if (starRating<5 && issueList.count==0){
            validationFlag = true
            validationMessage = "You need to choose at least one issue"
        }
        else if(comments.text.count>280){
            validationFlag = true
            validationMessage = "Maximum 280 characters allowed in comment section"
        }
        if (validationFlag){
            let alert = UIAlertController(title: "Validation", message: validationMessage , preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else{
            Phone.sharedInstance.submitFeedback(starRating: self.starRating, issueList: issueList, notes : comments.text, sendConsoleLog : sendConsoleLog.isOn)
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            let tabbarControler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
            let plivoVC: PlivoCallController? = (tabbarControler?.viewControllers?[2] as? PlivoCallController)
            Phone.sharedInstance.setDelegate(plivoVC!)
            tabbarControler?.selectedViewController = tabbarControler?.viewControllers?[1]
            _appDelegate?.window?.rootViewController = tabbarControler
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
                comments.resignFirstResponder()
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func onIncomingCall(_ incoming: PlivoIncoming) {
        let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        let tabbarControler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
        let plivoVC: PlivoCallController? = (tabbarControler?.viewControllers?[2] as? PlivoCallController)
        Phone.sharedInstance.setDelegate(plivoVC!)
        tabbarControler?.selectedViewController = tabbarControler?.viewControllers?[2]
        _appDelegate?.window?.rootViewController = tabbarControler
        plivoVC!.onIncomingCall(incoming)
    }
    
    
    /**
     * onSubmitFeedback
     */
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
