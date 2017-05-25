//
//  UtilityClass.swift
//  SwiftVoiceCallingApp
//
//  Created by Siva  on 24/05/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

class UtilClass: NSObject
{
    
    static let utilitySharedInstance = UtilClass()
    
    var container: UIView = UIView()
    var loadingView: UIView = UIView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    
    static func isNetworkAvailable() -> Bool
    {
        
        guard let flags = getFlags() else { return false }
        
        let isReachable = flags.contains(.reachable)
        
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
        
    }
    
    static func getFlags() -> SCNetworkReachabilityFlags?
    {
        
        guard let reachability = ipv4Reachability() ?? ipv6Reachability() else {
            
            return nil
            
        }
        
        var flags = SCNetworkReachabilityFlags()
        
        if !SCNetworkReachabilityGetFlags(reachability, &flags)
        {
            
            return nil
            
        }
        
        return flags
        
    }
    
    static func ipv6Reachability() -> SCNetworkReachability?
    {
        
        var zeroAddress = sockaddr_in6()
        
        zeroAddress.sin6_len = UInt8(MemoryLayout<sockaddr_in>.size)
        
        zeroAddress.sin6_family = sa_family_t(AF_INET6)
        
        return withUnsafePointer(to: &zeroAddress, {
            
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                
                SCNetworkReachabilityCreateWithAddress(nil, $0)
                
            }
            
        })
        
    }
    
    static func ipv4Reachability() -> SCNetworkReachability?
    {
        
        var zeroAddress = sockaddr_in()
        
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        return withUnsafePointer(to: &zeroAddress, {
            
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                
                SCNetworkReachabilityCreateWithAddress(nil, $0)
                
            }
            
        })
        
    }
    
    
    /*
     Show customized activity indicator,
     actually add activity indicator to passing view
     
     @param uiView - add activity indicator to this view
     */
    func showActivityIndicator(uiView: UIView) {
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColorFromHex(rgbValue: 0xffffff, alpha: 0.3)
        
        
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColorFromHex(rgbValue: 0x444444, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40);
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        
        loadingView.addSubview(activityIndicator)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }
    
    /*
     Hide activity indicator
     Actually remove activity indicator from its super view
     
     @param uiView - remove activity indicator from this view
     */
    func hideActivityIndicator() {
        
        activityIndicator.stopAnimating()
        container.removeFromSuperview()
        
        
    }
    
    /*
     Define UIColor from hex value
     
     @param rgbValue - hex color value
     @param alpha - transparency level
     */
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    
    
    
    func dateConvertionFromStringToDate(dateString: NSString) -> String {
        //2017-02-12 00:00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dateObj = dateFormatter.date(from: dateString as String)
        
        dateFormatter.dateFormat = "EEE, dd MMM yyyy"
        //print("Dateobj: \(dateFormatter.string(from: dateObj!))")
        
        return dateFormatter.string(from: dateObj!)
    }
    
    func timeConvertionFromStringTotime(dateString: NSString) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        
        let dateObj = dateFormatter.date(from: dateString as String)
        
        dateFormatter.dateFormat = "HH:mm"
        
        return dateFormatter.string(from: dateObj!)
    }
    
    func displayAlertView(titleText: String, message: String, viewController: UIViewController) {
        let errorAlert = UIAlertController(title: titleText, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        viewController.present(errorAlert, animated: true, completion: nil)
        
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler:{ action in
            switch action.style {
            case .default:
                break
            default:
                break
            }
        }))
    }
    // Email address Validation
    class func isValidEmail(testStr:String) -> Bool {
        print("validate emilId: \(testStr)")
        let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
        return result
    }
    
    class func validateEmail(validateEmailString: String) -> Bool {
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: validateEmailString)
    }
    
    func calculateDynamicheightOfControl(value:Float)-> Float{
        
        
        return (value * Float(UIScreen.main.bounds.size.height))/568.0
    }
    
    func calculateDynamicWidthOfControl(width: Float) -> Float {
        
        return (width * Float(UIScreen.main.bounds.size.width))/320.0
    }
    
    
    func byte(to byteData: [UInt8], length: Int) -> Int {
        var val: Int = 0
        for idx in 0..<length {
            val *= 256
            var j: Int = Int(byteData[idx])
            if j < 0 {
                j = 256 + j
            }
            val += j
        }
        return val
    }
    
    
    func addBoldText(fullString: NSString, boldPartsOfString: Array<NSString>, font: UIFont!, boldFont: UIFont!, textColor: UIColor!) -> NSAttributedString {
        let nonBoldFontAttribute = [NSFontAttributeName:font!, NSForegroundColorAttributeName: textColor] as [String : Any]
        let boldFontAttribute = [NSFontAttributeName:boldFont!, NSForegroundColorAttributeName: textColor] as [String : Any]
        let boldString = NSMutableAttributedString(string: fullString as String, attributes:nonBoldFontAttribute)
        for i in 0 ..< boldPartsOfString.count {
            boldString.addAttributes(boldFontAttribute, range: fullString.range(of: boldPartsOfString[i] as String))
        }
        return boldString
    }
    
    func alertTextAttributeString(fullString: NSString, boldPartsOfString: Array<NSString>, font: UIFont!, boldFont: UIFont!, textColor: UIColor!, boldTextColor: UIColor!) -> NSAttributedString {
        
        let nonBoldFontAttribute = [NSFontAttributeName:font!, NSForegroundColorAttributeName: textColor] as [String : Any]
        let boldFontAttribute = [NSFontAttributeName:boldFont!, NSForegroundColorAttributeName: boldTextColor] as [String : Any]
        let boldString = NSMutableAttributedString(string: fullString as String, attributes:nonBoldFontAttribute)
        
        for i in 0 ..< boldPartsOfString.count {
            
            boldString.addAttributes(boldFontAttribute, range: fullString.range(of: boldPartsOfString[i] as String))
            
        }
        return boldString
    }
    
    func setNavbarBGImage(navgationBar:UINavigationBar)
    {
        let image =  UIImage(named:"Nav_BG")!
        navgationBar.setBackgroundImage(image.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 0, 0, 0), resizingMode: .stretch), for: .default)
    }
    func setComNavbarBGImage(navgationBar:UINavigationBar)
    {
        let image =  UIImage(named:"com_nav_bg")!
        navgationBar.setBackgroundImage(image.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 0, 0, 0), resizingMode: .stretch), for: .default)
    }
    // Round Corner UIVIEW
    class func setViewRoundCorner(cornerView : UIView) {
        
        cornerView.layer.masksToBounds = false
        cornerView.layer.cornerRadius = 20
        cornerView.clipsToBounds = true
    }
    func removeSpecialCharactersFromPhNum(number : String) -> String {
        
        let numericSet = "0123456789"
        let filteredCharacters = number.characters.filter {
            return numericSet.contains(String($0))
        }
        return String(filteredCharacters)
    }
    
    class func makeToastActivity() {
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        appDelegate?.window?.rootViewController?.view?.isUserInteractionEnabled = false
        appDelegate?.window?.rootViewController?.view?.makeToastActivity(CSToastPositionCenter)
    }
    
    class func hideToastActivity() {
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        appDelegate?.window?.rootViewController?.view?.isUserInteractionEnabled = true
        appDelegate?.window?.rootViewController?.view?.hideToastActivity()
    }
    
    class func makeToast(_ toastMsg: String) {
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        appDelegate?.window?.rootViewController?.view?.makeToast(toastMsg)
    }
    
    /**
     *  User's authentication status
     *
     *  @param status of the user's authentication
     */
    
    class func setUserAuthenticationStatus(_ status: Bool) {
        UserDefaults.standard.set(status, forKey: kAUTHENTICATIONSTATUS)
        UserDefaults.standard.synchronize()
    }
    
    /**
     *  Status of the user's authentication
     *
     *  @return true if user is valid user
     */
    class func getUserAuthenticationStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: kAUTHENTICATIONSTATUS)
    }
    
    /*
     * To check empty string
     */
    class func isEmpty(_ text: String) -> Bool {
        return (nil == text || true == (self.trimWhiteSpaces(text) == "")) ? true : false
    }
    
    /*
     * To trim white spaces in string
     */
    class func trimWhiteSpaces(_ text: String) -> String {
        return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
}
