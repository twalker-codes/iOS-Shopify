//
//  PlistParser.swift
//  WebViewTemplate
//
//  Created by Mac on 30/12/20.
//

import Foundation

class PlistParser {
    // generic func to parse plist
    class func parsePlist<T: Codable>(plistName: String, completion: @escaping (_ data: T) -> ()) {
        let tabBarPlistName = plistName
        do {
            if let url = Bundle.main.url(forResource: tabBarPlistName, withExtension: "plist"),
               let data = try? Data(contentsOf: url) {
                let decoder = PropertyListDecoder()
                let model = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(model)
                }
            }
        } catch {
            // Handle error
            print(error)
        }
    }
}
