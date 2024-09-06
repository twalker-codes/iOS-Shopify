//
//  AccountController.swift
//  Storefront
//
//  Created by Shopify.
//  Copyright (c) 2017 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// This class provides insufficient security for
/// storing customer access token and is provided
/// for sample purposes only. All secure credentials
/// should be stored using Keychain.
///
class AccountController {
    
    static let shared = AccountController()
    
    private(set) var accessToken: String?
    private(set) var customerID: String?
    private(set) var name: String?
    private(set) var email: String?

    private let defaults = UserDefaults.standard
    
    // ----------------------------------
    //  MARK: - Init -
    //
    private init() {
        self.loadToken()
        self.loadCustomerID()
        self.loadName()
        self.loadEmail()
    }
    
    // ----------------------------------
    //  MARK: - Management -
    //
    func save(accessToken: String) {
        self.accessToken = accessToken
        self.defaults.set(accessToken, forKey: Key.token)
        self.defaults.synchronize()
        
        Client.shared.fetchCustomerDetails(accessToken: accessToken) { result in
            switch result {
            case .success(let customer):
                self.name = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
                self.defaults.set(self.name, forKey: Key.name)
                self.defaults.synchronize()
                
                self.email = customer.email ?? ""
                self.defaults.set(self.email, forKey: Key.email)
                self.defaults.synchronize()
                
            case .failure(let error): break
            }
        }
        
        Client.shared.fetchCustomerID(accessToken: accessToken) { customerID in
            if let customerID = customerID?.base64DecodeCustomerID(), !customerID.isEmpty {
                self.customerID = customerID
                self.defaults.set(customerID, forKey: Key.customerID)
                self.defaults.synchronize()
                PushNotificationManager.shared().updateFirestorePushTokenIfNeeded()
            }
        }
    }
    
    func deleteAccessToken() {
        PushNotificationManager.shared().removeFirestorePushTokenIfNeeded()
        self.accessToken = nil
        self.defaults.removeObject(forKey: Key.token)
        self.customerID = nil
        self.defaults.removeObject(forKey: Key.customerID)
        self.defaults.synchronize()
    }
    
    @discardableResult
    func loadToken() -> String? {
        self.accessToken = self.defaults.string(forKey: Key.token)
        return self.accessToken
    }
    
    @discardableResult
    func loadCustomerID() -> String? {
        self.customerID = self.defaults.string(forKey: Key.customerID)
        return self.customerID
    }
    
    @discardableResult
    func loadName() -> String? {
        self.name = self.defaults.string(forKey: Key.name)
        return self.name
    }
    
    @discardableResult
    func loadEmail() -> String? {
        self.email = self.defaults.string(forKey: Key.email)
        return self.email
    }
}

private extension AccountController {
    enum Key {
        static let token = "com.shopify.storefront.customerAccessToken"
        static let customerID = "com.shopify.storefront.customerID"
        static let name = "com.shopify.storefront.name"
        static let email = "com.shopify.storefront.email"
    }
}
