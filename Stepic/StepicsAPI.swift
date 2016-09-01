//
//  StepicsAPI.swift
//  Stepic
//
//  Created by Alexander Karpov on 29.08.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON 

class StepicsAPI {
    
    
    init() {}
    
    let manager: Manager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        return Manager(configuration: configuration)
    }()

    
    func retrieveCurrentUser(headers: [String: String] = AuthInfo.shared.initialHTTPHeaders, success: User -> Void, error errorHandler: String -> Void) -> Request {
        let params = [String:AnyObject]()
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        
        return manager.request(.GET, "\(StepicApplicationsInfo.apiURL)/stepics/1", parameters: params, headers: headers, encoding: .URL).responseSwiftyJSON({
            (request, response, json, error) in
            
            print("headers while retrieving user: \(request.allHTTPHeaderFields)")
            
            if let e = error as? NSError {
                print(e.localizedDescription)
                
                errorHandler(e.localizedDescription)
                return
            }

            let user : User = User(json: json["users"].arrayValue[0])
            success(user)
        })

    }
}