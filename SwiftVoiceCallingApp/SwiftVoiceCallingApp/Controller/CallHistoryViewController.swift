//
//  CallHistoryViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class CallHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var callHistoryTableView: UITableView!
    @IBOutlet weak var noRecentCallsLabel: UILabel!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
        Phone.sharedInstance.setDelegate(plivoVC!)
        
        self.callHistoryTableView.delegate = self
        self.callHistoryTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        if !(CallInfo.getCallsInfoArray().count > 0) {
            callHistoryTableView.isHidden = true
            noRecentCallsLabel.isHidden = false
            view.bringSubview(toFront: noRecentCallsLabel)
        }
        else {
            callHistoryTableView.isHidden = false
            noRecentCallsLabel.isHidden = true
            view.bringSubview(toFront: callHistoryTableView)
            callHistoryTableView.reloadData()
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableView Deleages, DataSources
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CallInfo.getCallsInfoArray().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let editprofileIdentifier: String = "CallHistory"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: editprofileIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: editprofileIdentifier)
        }
        let callInfoArray: [Any] = CallInfo.getCallsInfoArray()
        let callInfo: [Any] = callInfoArray[indexPath.row] as! [Any]
        cell?.textLabel?.text = callInfo[0] as? String
        cell?.detailTextLabel?.text = getStringFrom(callInfo[1] as! Date)
        cell?.imageView?.image = UIImage(named: "RecentCallIcon")
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
        tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
        Phone.sharedInstance.setDelegate(plivoVC!)
        let callInfoArray: [Any] = CallInfo.getCallsInfoArray()
        let callInfo: [Any] = callInfoArray[indexPath.row] as! [Any]
        CallKitInstance.sharedInstance.callUUID = UUID()
        plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: callInfo[0] as! String)
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let yesButton = UIAlertAction(title: "Yes", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            //Handle your yes please button action here
            FIRAnalytics.logEvent(withName: "Logout", parameters: ["Class": "RecentCalls" as NSObject])
            UtilClass.makeToastActivity()
            let plivoVC: PlivoCallController? = self.tabBarController?.viewControllers?[2] as? PlivoCallController
            Phone.sharedInstance.setDelegate(plivoVC!)
            plivoVC?.unRegisterSIPEndpoit()
        })
        let noButton = UIAlertAction(title: "No", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            //Handle no, thanks button
        })
        alert.addAction(yesButton)
        alert.addAction(noButton)
        present(alert, animated: true, completion: { _ in })
        
    }
    
    func getStringFrom(_ date: Date) -> String {
        
        let dateFormat = DateFormatter()
        // set the date format related to what the string already you have
        dateFormat.timeZone = NSTimeZone.system
        // again add the date format what the output u need
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let finalDate: String = dateFormat.string(from: date)
        return finalDate
    }

}
