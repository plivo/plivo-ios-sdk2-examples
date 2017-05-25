//
//  APIRequestManager.swift
//  AARP
//
//  Created by Ducere on 14/03/17.
//  Copyright © 2017 Ducere. All rights reserved.
//

import UIKit

protocol APIRequestManagerDelegate {
    
    func didGetResponseSuccessfully(jsonData : Any)
    func didGetResponseFail(error : String)
    
}

class APIRequestManager: NSObject {
    
    
    
    var delegate: APIRequestManagerDelegate?
    static let apiCallManagerSharedInstance = APIRequestManager()

    func getTheResponceFromUrl(urlString : String , parameters : Dictionary<String, Any>)  {
        
        
       // let configuration = URLSessionConfiguration.default
        let session       = URLSession.shared
        guard let requsetURL = URL(string : urlString as String) else {
            
            return
        }
        var urlRequest = URLRequest(url : requsetURL)
        urlRequest.httpMethod = "POST"
        let jsonTodo : Data
        
        do {
            
          jsonTodo =  try JSONSerialization.data(withJSONObject: parameters, options: [])
          urlRequest.httpBody = jsonTodo
            
        } catch  {
            
            print("Error: cannot create JOSN from parameters dictionary")
            return
            
        }
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        let dataTask = session.dataTask(with: urlRequest, completionHandler: {(data,responce,error) in
        
            guard error == nil else{
                
                self.delegate?.didGetResponseFail(error: error!.localizedDescription as String)
                return
                
            }
            guard let responceData = data else{
                
                self.delegate?.didGetResponseFail(error: "did not receive data")
                return
            }
            do {
                
                let jsonResponce = try JSONSerialization.jsonObject(with: responceData, options: [])
                self.delegate?.didGetResponseSuccessfully(jsonData: jsonResponce)
                
            } catch {
                
                self.delegate?.didGetResponseFail(error: error.localizedDescription)
                print("error parsing response from POST on ")
                return
            }
            
        
        })
        dataTask.resume()
    
    }
}
