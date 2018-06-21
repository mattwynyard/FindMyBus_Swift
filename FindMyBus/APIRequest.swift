//
//  URLRequest.swift
//  FindMyBus
//
//  Created by Matthew Wynyard on 21/06/18.
//  Copyright © 2018 Niobium. All rights reserved.
//

import Foundation

internal protocol APIRequestDelegate {
    
    func getData(data: Data)
}

class APIRequest: NSObject {

    private var jsonResponse: String?
    var delegate: APIRequestDelegate?

func httpGet(url: String, query: String, callback: @escaping (Data, String?) -> Void) {
    
    var url = URLRequest(url: URL(string: "\(url)" + "\(String(describing: query))")!)
    url.httpMethod = "GET"
    url.addValue("application/json", forHTTPHeaderField: "Accept")
    url.timeoutInterval = 30
    
    
    let task = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
        if let error = error {
            print(url)
            let errString = error.localizedDescription
            print(errString)
        } else {
            callback(data!, nil)
            print("All done")
        }
    })
    task.resume()
} //end func

func sendRoutes(url: String, query: String) {
    
    httpGet(url: url, query: query) { (data, error) -> Void in
        if error != nil {
            print(error!)
        } else {
            print("Sending Request..")
            let str = String.init(data: data, encoding: .utf8)
            self.jsonResponse = str
            self.delegate?.getData(data: data)

            
        } //end else
    } //end closure
} //end fun

}//end class

