//
//  URLRequest.swift
//  FindMyBus
//
//  Created by Matthew Wynyard on 21/06/18.
//  Copyright © 2018 Niobium. All rights reserved.
//

import Foundation

internal protocol APIRequestDelegate: class {
    
    func getData(data: Data)
    //func removeAnnotations()
}

class APIRequest: NSObject {

    //private var jsonResponse: String?
    weak var delegate: APIRequestDelegate?

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

    //DispatchQueue.main.async (execute: { () -> Void in
        self.httpGet(url: url, query: query) { (data, error) -> Void in
            if error != nil {
                print(error!)
            } else {
                print("Sending Request..")
                //self.delegate?.removeAnnotations()
                self.delegate?.getData(data: data)
               
            }
        } //end closure
    //})
} //end fun

}//end class

