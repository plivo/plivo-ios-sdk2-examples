//
//  ServiceManager.swift
//  AARP
//
//  Created by Ducere on 12/05/17.
//  Copyright © 2017 Ducere. All rights reserved.
//

import UIKit

class ServiceManager: NSObject {

    //    var completionBlock: ((Data?,HTTPURLResponse?,Error?) -> ())?
    
    //MARK: Singleton Instance
    static let sharedInstance = ServiceManager()
    
    //MARK: Create URL Request
    func createURLRequestForURLWithType(urlString:String,type:String) -> NSMutableURLRequest {
        let url:NSURL! = NSURL.init(string: urlString as String)
        let urlRequest: NSMutableURLRequest! = NSMutableURLRequest.init(url: url as URL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 30)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpMethod = type as String
        return urlRequest
    }
    
    //MARK: Create URL Response
    func getResponseForURLWithParameters(url:String, userInfo:NSDictionary?, type:String, completion:@escaping (Data?,HTTPURLResponse?,Error?)->()) {
        let urlRequest = createURLRequestForURLWithType(urlString: url as String,type: type as String)

        if userInfo != nil {
            let parametersData:Data = try! JSONSerialization.data(withJSONObject: userInfo!, options: .prettyPrinted)
            urlRequest.httpBody = parametersData as Data
            let string = NSString.init(data: urlRequest.httpBody!, encoding:String.Encoding.utf8.rawValue)
            print("user parameters \(String(describing: string))  \n \(urlRequest)")
            
        }
        
        let urlSessionConfiguration:URLSessionConfiguration! = URLSessionConfiguration.default
        let urlSession:URLSession! = URLSession.init(configuration: urlSessionConfiguration, delegate: nil, delegateQueue: OperationQueue.main)
        let urlDataTask:URLSessionDataTask = urlSession.dataTask(with: urlRequest as URLRequest) { (data, urlResponse, error) in
            
            guard error == nil else{
                completion(nil, nil, error)
                return
            }
            
            guard let responceData = data else{
                
                let userInfo: [NSObject : AnyObject] =
                    [
                        NSLocalizedDescriptionKey as NSObject :  NSLocalizedString("Unauthorized", value: "did not receive data", comment: "") as AnyObject,
                        NSLocalizedFailureReasonErrorKey as NSObject : NSLocalizedString("Unauthorized", value: "Account not activated", comment: "") as AnyObject
                ]
                let err = NSError(domain: "HttpResponseErrorDomain", code: 500, userInfo: userInfo)
                
                completion(data! as Data?,nil,err)

                return
            }
            
            do {
                let jsonResponce = try JSONSerialization.jsonObject(with: responceData, options: [])
                print(jsonResponce)
                let httpURLResponse:HTTPURLResponse = urlResponse as! HTTPURLResponse
                completion(data! as Data?,httpURLResponse,nil)

            } catch {
                
                completion(nil, nil, error)
                print("error parsing response from POST on ")
                return
            }
        }
        urlDataTask.resume()
    }
}

