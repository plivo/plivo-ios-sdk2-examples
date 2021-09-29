//
//  ContactsViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import APAddressBook

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var phoneContacts = [APContact]()
    var searchController: UISearchController?
    var contactsSegmentControl: UISegmentedControl?
    var phoneSearchResults = [Any]()
    var isSearchControllerActive: Bool = false
    
    let addressBook = APAddressBook()
    
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var noContactsLabel: UILabel!
    
    
    // MARK: - Life cycle
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder);
        addressBook.fieldsMask = [APContactField.default, APContactField.thumbnail]
        addressBook.sortDescriptors = [NSSortDescriptor(key: "name.firstName", ascending: true),
                                       NSSortDescriptor(key: "name.lastName", ascending: true)]
        addressBook.filterBlock = { (contact: APContact) -> Bool in
            if let phones = contact.phones{
                return phones.count > 0
            }
            return false
        }
        
        addressBook.startObserveChanges{
            [weak self] in
            self?.loadContacts()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadContacts()
        self.contactsTableView.delegate = self
        self.contactsTableView.dataSource = self
        
        let label = UILabel(frame: CGRect(x: CGFloat(UIScreen.main.bounds.size.width * 0.28125), y: CGFloat(27), width: CGFloat(UIScreen.main.bounds.size.width * 0.4375), height: CGFloat(29)))
        label.text = "Contacts"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: CGFloat(17))
        view.addSubview(label)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.sizeToFit()
        contactsTableView.tableHeaderView = searchController?.searchBar
        // We want ourselves to be the delegate for this filtered table so didSelectRowAtIndexPath is called for both tables.
        searchController?.delegate = self
        searchController?.dimsBackgroundDuringPresentation = false
        // default is YES
        searchController?.searchBar.delegate = self
        // so we can monitor text changes + others
        // Search is now just presenting a view controller. As such, normal view controller
        // presentation semantics apply. Namely that presentation will walk up the view controller
        // hierarchy until it finds the root view controller or one that defines a presentation context.
        //
        definesPresentationContext = true
        
        // know where you want UISearchController to be displayed
        let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
        Phone.sharedInstance.setDelegate(plivoVC!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        contactsTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        isSearchControllerActive = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleSegmentControl(_ segment: UISegmentedControl) {
        contactsTableView.reloadData()
    }
    
    
    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UISearchControllerDelegate
    // Called after the search controller's search bar has agreed to begin editing or when
    // 'active' is set to YES.
    // If you choose not to present the controller yourself or do not implement this method,
    // a default presentation is performed on your behalf.
    //
    // Implement this method if the default presentation is not adequate for your purposes.
    //
    func presentSearchController(_ searchController: UISearchController) {
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        // do something before the search controller is presented
        isSearchControllerActive = true
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        // do something after the search controller is presented
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        // do something before the search controller is dismissed
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        // do something after the search controller is dismissed
        isSearchControllerActive = false
    }
    
    // MARK: - APContacts
    func loadContacts(){
        addressBook.loadContacts{
            [weak self] (contacts: [APContact]?, error: Error?) in
            
            guard let selfObj = self else {
                return
            }
            selfObj.phoneContacts = [APContact]()
            
            if let contacts = contacts{
                selfObj.phoneContacts = contacts
                selfObj.noContactsLabel.isHidden = true
                selfObj.view.bringSubviewToFront(selfObj.contactsTableView)
                selfObj.contactsTableView.reloadData()
                var contctArray = [Any]() /* capacity: contacts.count */
                
                for i in 0..<selfObj.phoneContacts.count{
                    var contctDict = [AnyHashable: Any]()
                    contctDict["Name"] = selfObj.contactName(selfObj.phoneContacts[i])
                    contctDict["Number"] = selfObj.contactPhones(selfObj.phoneContacts[i])
                    contctArray.append(contctDict)
                }
                UserDefaults.standard.set(contctArray, forKey: "PhoneContacts")
            }else if let error = error{
                print(error)
            }
        }
    }
    
    func contactName(_ contact :APContact) -> String {
        if let firstName = contact.name?.firstName, let lastName = contact.name?.lastName {
            return "\(firstName) \(lastName)"
        }
        else if let firstName = contact.name?.firstName {
            return "\(firstName)"
        }
        else if let lastName = contact.name?.lastName {
            return "\(lastName)"
        }
        else {
            return "Unnamed contact"
        }
    }
    
    func contactPhones(_ contact :APContact) -> String {
        if let phones = contact.phones {
            return (phones.first?.number)!;
        }
        return "No phone"
    }
    
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    /**
     * Actual array
     * Search results array
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if isSearchControllerActive {
            return phoneSearchResults.count
        }else{
            return phoneContacts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearchControllerActive{
            let editprofileIdentifier: String = "CallHistory"
            var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: editprofileIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: editprofileIdentifier)
            }
            let contact: APContact? = phoneSearchResults[Int(indexPath.row)] as? APContact
            cell?.textLabel?.text = contactName(contact!)
            cell?.detailTextLabel?.text = contactPhones(contact!)
            cell?.imageView?.image = UIImage(named: "TabbarIcon1")
            return cell!
        }else {
            let editprofileIdentifier: String = "CallHistory"
            var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: editprofileIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: editprofileIdentifier)
            }
            let contact: APContact? = phoneContacts[Int(indexPath.row)]
            cell?.textLabel?.text = contactName(contact!)
            cell?.detailTextLabel?.text = contactPhones(contact!)
            cell?.imageView?.image = UIImage(named: "TabbarIcon1")
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearchControllerActive{
            self.searchController?.dismiss(animated: false, completion: nil)
            let contactDetails: APContact? = phoneSearchResults[Int(indexPath.row)] as? APContact
            
            let apPhoneObj: APPhone? = contactDetails?.phones?[0]
            
            var phoneNumber: String = (apPhoneObj!.number! as NSString).replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: NSRange(location: 0, length: (apPhoneObj?.number!.count )!))
            phoneNumber = phoneNumber.replacingOccurrences(of: "(", with: "")
            phoneNumber = phoneNumber.replacingOccurrences(of: ")", with: "")
            phoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
            
            let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
            tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
            Phone.sharedInstance.setDelegate(plivoVC!)
            CallKitInstance.sharedInstance.callUUID = UUID()
            plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber)
        }else{
            
            let contactDetails: APContact? = phoneContacts[Int(indexPath.row)]
            let apPhoneObj: APPhone? = contactDetails?.phones?[0]
            
            var phoneNumber: String = (apPhoneObj!.number! as NSString).replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: NSRange(location: 0, length: (apPhoneObj?.number!.count )!))
            phoneNumber = phoneNumber.replacingOccurrences(of: "(", with: "")
            phoneNumber = phoneNumber.replacingOccurrences(of: ")", with: "")
            phoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
            
            let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
            tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
            Phone.sharedInstance.setDelegate(plivoVC!)
            CallKitInstance.sharedInstance.callUUID = UUID()
            plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber)
        }
    }
    
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        // update the filtered array based on the search text
        let searchText: String = searchController.searchBar.text!
        
        phoneSearchResults = phoneContacts
        // strip out all the leading and trailing spaces
        let strippedString: String = searchText.trimmingCharacters(in: CharacterSet.whitespaces)
        // break up the search terms (separated by spaces)
        var searchItems: [String]? = nil
        if (strippedString.count ) > 0 {
            searchItems = strippedString.components(separatedBy: " ")
        }
        // build all the "AND" expressions for each value in the searchString
        //
        var andMatchPredicates = [Any]()
        
        if(searchItems != nil){
            
            for searchString: String in searchItems! {
                // each searchString creates an OR predicate for: name, yearIntroduced, introPrice
                //
                // example if searchItems contains "iphone 599 2007":
                //      name CONTAINS[c] "iphone"
                //      name CONTAINS[c] "599", yearIntroduced ==[c] 599, introPrice ==[c] 599
                //      name CONTAINS[c] "2007", yearIntroduced ==[c] 2007, introPrice ==[c] 2007
                //
                var searchItemsPredicate = [Any]()
                // Below we use NSExpression represent expressions in our predicates.
                // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value)
                // name field matching
                var lhs = NSExpression(forKeyPath: "name.compositeName")
                var rhs = NSExpression(forConstantValue: searchString)
                var finalPredicate: NSPredicate? = NSComparisonPredicate(leftExpression: lhs, rightExpression: rhs, modifier: .direct, type: .contains, options: .caseInsensitive)
                searchItemsPredicate.append(finalPredicate as Any)
                // yearIntroduced field matching
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .none
                let targetNumber = numberFormatter.number(from: searchString)
                if targetNumber != nil {
                    // searchString may not convert to a number
                    lhs = NSExpression(forKeyPath: "phones")
                    rhs = NSExpression(forConstantValue: targetNumber)
                    finalPredicate = NSComparisonPredicate(leftExpression: lhs, rightExpression: rhs, modifier: .direct, type: .equalTo, options: .caseInsensitive)
                    searchItemsPredicate.append(finalPredicate as Any)
                }
                // at this OR predicate to our master AND predicate
                let orMatchPredicates:NSCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:searchItemsPredicate as! [NSPredicate])
                andMatchPredicates.append(orMatchPredicates)
            }
        }
        // match up the fields of the Product object
        let finalCompoundPredicate:NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:andMatchPredicates as! [NSPredicate])
        phoneSearchResults = phoneSearchResults.filter { finalCompoundPredicate.evaluate(with: $0) }
        self.contactsTableView.reloadData()
    }
    
    /*
     * Making a call by using Siri
     */
    
    func makeCall(withSiriName name: String) {
        let contactsArray: [Any] = (UserDefaults.standard.object(forKey: "PhoneContacts") as! [Any])
        for i in 0..<contactsArray.count{
            let contact: [AnyHashable: String] = contactsArray[i] as! [AnyHashable : String]
            if (contact["Name"]?.contains(name))! {
                let contactNumber: String = contact["Number"]!
                let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
                self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[2]
                Phone.sharedInstance.setDelegate(plivoVC!)
                CallKitInstance.sharedInstance.callUUID = UUID()
                
                var phoneNumber: String = (contactNumber as NSString).replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: NSRange(location: 0, length:contactNumber.count))
                phoneNumber = phoneNumber.replacingOccurrences(of: "(", with: "")
                phoneNumber = phoneNumber.replacingOccurrences(of: ")", with: "")
                phoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
                
                plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber)
            }
        }
    }
    
    @IBAction func feedbackButtonTapped(_ sender: Any) {
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let yesButton = UIAlertAction(title: "Yes", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            //Handle your yes please button action here
            UtilClass.makeToastActivity()
            let plivoVC: PlivoCallController? = (self.tabBarController?.viewControllers?[2] as? PlivoCallController)
            Phone.sharedInstance.setDelegate(plivoVC!)
            plivoVC?.unRegisterSIPEndpoit()
        })
        let noButton = UIAlertAction(title: "No", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            //Handle no, thanks button
        })
        alert.addAction(noButton)
        alert.addAction(yesButton)
        present(alert, animated: true, completion: { })
    }
    
}
