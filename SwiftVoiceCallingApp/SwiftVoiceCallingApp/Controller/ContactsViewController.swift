//
//  ContactsViewController.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import APAddressBook

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

    var phoneContacts = [APContact]()
    var searchController: UISearchController?
    var contactsSegmentControl: UISegmentedControl?
    var phoneSearchResults = [Any]()
    var sipSearchResults = [Any]()
    var isSearchControllerActive: Bool = false
    var sipDetailsArray = [Any]()
    
    let addressBook = APAddressBook()
    
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var noContactsLabel: UILabel!
    
    // MARK: - Life cycle
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder);
        addressBook.fieldsMask = [APContactField.default, APContactField.thumbnail]
        addressBook.sortDescriptors = [NSSortDescriptor(key: "name.firstName", ascending: true),
                                       NSSortDescriptor(key: "name.lastName", ascending: true)]
        addressBook.filterBlock =
            {
                (contact: APContact) -> Bool in
                if let phones = contact.phones
                {
                    return phones.count > 0
                }
                return false
        }
        addressBook.startObserveChanges
            {
                [unowned self] in
                self.loadContacts()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadContacts()
        
        if (UserDefaults.standard.object(forKey: kSIPDETAILS) != nil)
        {
            sipDetailsArray = (UserDefaults.standard.object(forKey: kSIPDETAILS) as? [Any])!
            var tempSipArray = [Any]()
            
            for i in 0..<sipDetailsArray.count
            {
                let sipDict: [AnyHashable: Any] = sipDetailsArray[i] as! [AnyHashable : Any]
                
                if UtilClass.validateEmail(validateEmailString:sipDict["eMail"] as! String) {
                    tempSipArray.append(sipDict)
                }
                
            }
            
            sipDetailsArray = []
            sipDetailsArray = tempSipArray
            tempSipArray = []

        }
        
        
        self.contactsTableView.delegate = self
        self.contactsTableView.dataSource = self
        
        if sipDetailsArray.count > 0
        {
            let itemArray: [Any] = ["Phone", "SIP"]
            // Create UISegmentedControl object to add control UISegment.
            contactsSegmentControl = UISegmentedControl(items: itemArray)
            // Set frame for objSegment Control (formate: (x, y, width, height)). where, y = (height of view - height of control).
            contactsSegmentControl?.frame = CGRect(x: CGFloat(UIScreen.main.bounds.size.width * 0.28125), y: CGFloat(27), width: CGFloat(UIScreen.main.bounds.size.width * 0.4375), height: CGFloat(29))
            // handle UISegmentedControl action.
            contactsSegmentControl?.addTarget(self, action: #selector(self.handleSegmentControl(_:)), for: .valueChanged)
            
            contactsSegmentControl?.selectedSegmentIndex = 0
            view.addSubview(contactsSegmentControl!)
        }
        else
        {
            let label = UILabel(frame: CGRect(x: CGFloat(UIScreen.main.bounds.size.width * 0.28125), y: CGFloat(27), width: CGFloat(UIScreen.main.bounds.size.width * 0.4375), height: CGFloat(29)))
            label.text = "Contacts"
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: CGFloat(17))
            view.addSubview(label)
        }
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self as? UISearchResultsUpdating
        searchController?.searchBar.sizeToFit()
        contactsTableView.tableHeaderView = searchController?.searchBar
        // We want ourselves to be the delegate for this filtered table so didSelectRowAtIndexPath is called for both tables.
        searchController?.delegate = self as? UISearchControllerDelegate
        searchController?.dimsBackgroundDuringPresentation = false
        // default is YES
        searchController?.searchBar.delegate = self as? UISearchBarDelegate
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
    func loadContacts()
    {
        addressBook.loadContacts
            {
                [unowned self] (contacts: [APContact]?, error: Error?) in

                self.phoneContacts = [APContact]()

                if let contacts = contacts
                {
                    self.phoneContacts = contacts
                    
                    self.noContactsLabel.isHidden = true
                    self.view.bringSubview(toFront: self.contactsTableView)
                    self.contactsTableView.reloadData()
                    var contctArray = [Any]() /* capacity: contacts.count */

                    for i in 0..<self.phoneContacts.count {
                        
                        var contctDict = [AnyHashable: Any]()
                        contctDict["Name"] = self.contactName(self.phoneContacts[i])
                        contctDict["Number"] = self.contactPhones(self.phoneContacts[i])
                        contctArray.append(contctDict)
                        
                    }
                    
                    UserDefaults.standard.set(contctArray, forKey: "PhoneContacts")

                }
                else if let error = error
                {
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if isSearchControllerActive {
            
            if contactsSegmentControl?.selectedSegmentIndex == 1 {
                return sipSearchResults.count

            }
            else {
                return phoneSearchResults.count

            }
        }
        else
        {
            if (contactsSegmentControl != nil)
            {
                if contactsSegmentControl?.selectedSegmentIndex == 0 {
                    return phoneContacts.count
                }
                else {
                    return sipDetailsArray.count
                }
            }
            else {
                return phoneContacts.count
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearchControllerActive {
            if contactsSegmentControl?.selectedSegmentIndex == 1 {
                
                let editprofileIdentifier: String = "CallHistory"
                var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: editprofileIdentifier)
                if cell == nil {
                    cell = UITableViewCell(style: .subtitle, reuseIdentifier: editprofileIdentifier)
                }
                let sipDict: [AnyHashable: Any] = sipSearchResults[indexPath.row] as! [AnyHashable : Any]
                cell?.textLabel?.text = sipDict["eMail"] as? String
                cell?.detailTextLabel?.text = sipDict["endPoint"] as? String
                cell?.imageView?.image = UIImage(named: "TabbarIcon1")
                return cell!
                
            }
            else {
                
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
            }
        }
        else {
            if (contactsSegmentControl != nil) {
                if contactsSegmentControl?.selectedSegmentIndex == 0 {
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
                else {
                    let editprofileIdentifier: String = "CallHistory"
                    var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: editprofileIdentifier)
                    if cell == nil {
                        cell = UITableViewCell(style: .subtitle, reuseIdentifier: editprofileIdentifier)
                    }
                    let sipDict: [AnyHashable: Any] = sipDetailsArray[indexPath.row] as! [AnyHashable : Any]
                    cell?.textLabel?.text = sipDict["eMail"] as? String
                    cell?.detailTextLabel?.text = sipDict["endPoint"] as? String
                    cell?.imageView?.image = UIImage(named: "TabbarIcon1")
                    return cell!
                }
            }
            else {
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isSearchControllerActive
        {
            self.searchController?.dismiss(animated: false, completion: nil)
        
            if contactsSegmentControl?.selectedSegmentIndex == 1 {
                
                let sipDict: [AnyHashable: Any] = sipSearchResults[indexPath.row] as! [AnyHashable : Any]
                let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
                tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
                Phone.sharedInstance.setDelegate(plivoVC!)
                CallKitInstance.sharedInstance.callUUID = UUID()
                plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: sipDict["endPoint"] as! String)

                
            }
            else
            {
                
                let contactDetails: APContact? = phoneSearchResults[Int(indexPath.row)] as? APContact
                
                let apPhoneObj: APPhone? = contactDetails?.phones?[0]
                
                let phoneNumber: String = (apPhoneObj!.number! as NSString).replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: NSRange(location: 0, length: (apPhoneObj?.number!.characters.count )!))
                let phoneNumber2 = phoneNumber.replacingOccurrences(of: "(", with: "")
                let phoneNumber3 = phoneNumber2.replacingOccurrences(of: ")", with: "")
                let phoneNumber4 = phoneNumber3.replacingOccurrences(of: "-", with: "")
                
                let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
                tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
                Phone.sharedInstance.setDelegate(plivoVC!)
                CallKitInstance.sharedInstance.callUUID = UUID()
                plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber4)
            }
        }
        else
        {
            if (contactsSegmentControl != nil)
            {
                
                if contactsSegmentControl?.selectedSegmentIndex == 0
                {
                    let contactDetails: APContact? = phoneContacts[Int(indexPath.row)]
                    let apPhoneObj: APPhone? = contactDetails?.phones?[0]
                    
                    let phoneNumber: String = (apPhoneObj!.number! as NSString).replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: NSRange(location: 0, length: (apPhoneObj?.number!.characters.count )!))
                    let phoneNumber2 = phoneNumber.replacingOccurrences(of: "(", with: "")
                    let phoneNumber3 = phoneNumber2.replacingOccurrences(of: ")", with: "")
                    let phoneNumber4 = phoneNumber3.replacingOccurrences(of: "-", with: "")
                    
                    let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
                    tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
                    Phone.sharedInstance.setDelegate(plivoVC!)
                    CallKitInstance.sharedInstance.callUUID = UUID()
                    plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber4)
                }
                else
                {
                    let sipDict: [AnyHashable: Any] = sipDetailsArray[indexPath.row] as! [AnyHashable : Any]
                    let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
                    tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
                    Phone.sharedInstance.setDelegate(plivoVC!)
                    CallKitInstance.sharedInstance.callUUID = UUID()
                    plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: sipDict["endPoint"] as! String)
                }
            }
            else
            {
                let contactDetails: APContact? = phoneContacts[Int(indexPath.row)]
                let apPhoneObj: APPhone? = contactDetails?.phones?[0]
                
                let phoneNumber: String = (apPhoneObj!.number! as NSString).replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: NSRange(location: 0, length: (apPhoneObj?.number!.characters.count )!))
                let phoneNumber2 = phoneNumber.replacingOccurrences(of: "(", with: "")
                let phoneNumber3 = phoneNumber2.replacingOccurrences(of: ")", with: "")
                let phoneNumber4 = phoneNumber3.replacingOccurrences(of: "-", with: "")

                let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
                tabBarController?.selectedViewController = tabBarController?.viewControllers?[2]
                Phone.sharedInstance.setDelegate(plivoVC!)
                CallKitInstance.sharedInstance.callUUID = UUID()
                plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber4)
            }
        }
    }
    
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        // update the filtered array based on the search text
        let searchText: String = searchController.searchBar.text!
        
        if contactsSegmentControl?.selectedSegmentIndex == 1
        {
            sipSearchResults = sipDetailsArray
            // strip out all the leading and trailing spaces
            var strippedString: String = searchText.trimmingCharacters(in: CharacterSet.whitespaces)
            // break up the search terms (separated by spaces)
            var searchItems: [String]? = nil
            if (strippedString.characters.count) > 0 {
                searchItems = strippedString.components(separatedBy: " ")
            }
            // build all the "AND" expressions for each value in the searchString
            //
            var andMatchPredicates = [Any]()
            
            if(searchItems != nil)
            {
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
                    var lhs = NSExpression(forKeyPath: "eMail")
                    var rhs = NSExpression(forConstantValue: searchString)
                    var finalPredicate: NSPredicate? = NSComparisonPredicate(leftExpression: lhs, rightExpression: rhs, modifier: .direct, type: .contains, options: .caseInsensitive)
                    searchItemsPredicate.append(finalPredicate)
                    // yearIntroduced field matching
                    var numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .none
                    var targetNumber = numberFormatter.number(from: searchString)
                    if targetNumber != nil {
                        // searchString may not convert to a number
                        lhs = NSExpression(forKeyPath: "endPoint")
                        rhs = NSExpression(forConstantValue: targetNumber)
                        finalPredicate = NSComparisonPredicate(leftExpression: lhs, rightExpression: rhs, modifier: .direct, type: .equalTo, options: .caseInsensitive)
                        searchItemsPredicate.append(finalPredicate)
                    }
                    
                    // at this OR predicate to our master AND predicate
                    let orMatchPredicates:NSCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:searchItemsPredicate as! [NSPredicate])
                    andMatchPredicates.append(orMatchPredicates)
                }
            }
            // match up the fields of the Product object
            let finalCompoundPredicate:NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:andMatchPredicates as! [NSPredicate])
            sipSearchResults = sipSearchResults.filter { finalCompoundPredicate.evaluate(with: $0) }
            
            
        }else
        {
            
            phoneSearchResults = phoneContacts
            // strip out all the leading and trailing spaces
            let strippedString: String = searchText.trimmingCharacters(in: CharacterSet.whitespaces)
            // break up the search terms (separated by spaces)
            var searchItems: [String]? = nil
            if (strippedString.characters.count ) > 0 {
                searchItems = strippedString.components(separatedBy: " ")
            }
            // build all the "AND" expressions for each value in the searchString
            //
            var andMatchPredicates = [Any]()
            
            if(searchItems != nil)
            {
                
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
    
        }
        
        self.contactsTableView.reloadData()

    }
    
    /*
     * Making a call by using Siri
     */
    
    func makeCall(withSiriName name: String) {
        
        let contactsArray: [Any] = (UserDefaults.standard.object(forKey: "PhoneContacts") as! [Any])
        
        for i in 0..<contactsArray.count
        {
            let contact: [AnyHashable: String] = contactsArray[i] as! [AnyHashable : String]
            if (contact["Name"]?.contains(name))! {
                let contactNumber: String = contact["Number"]!
                let plivoVC: PlivoCallController? = (tabBarController?.viewControllers?[2] as? PlivoCallController)
                self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[2]
                Phone.sharedInstance.setDelegate(plivoVC!)
                CallKitInstance.sharedInstance.callUUID = UUID()
                
                let phoneNumber: String = (contactNumber as NSString).replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: NSRange(location: 0, length:contactNumber.characters.count))
                let phoneNumber2 = phoneNumber.replacingOccurrences(of: "(", with: "")
                let phoneNumber3 = phoneNumber2.replacingOccurrences(of: ")", with: "")
                let phoneNumber4 = phoneNumber3.replacingOccurrences(of: "-", with: "")
                
                plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber4)
            }
        }
    
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let yesButton = UIAlertAction(title: "Yes", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            //Handle your yes please button action here
            FIRAnalytics.logEvent(withName: "Logout", parameters: ["Class": "Contacts" as NSObject])
            UtilClass.makeToastActivity()
            let plivoVC: PlivoCallController? = (self.tabBarController?.viewControllers?[2] as? PlivoCallController)
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
    
}
