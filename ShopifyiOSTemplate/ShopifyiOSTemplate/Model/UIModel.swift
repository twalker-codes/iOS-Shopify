//
//  UIModel.swift
//  WebViewTemplate
//
//  Created by Mac on 30/12/20.
//

import Foundation

class UIModel: Codable {
    var navigationBackgroundColor: String
    var navigationForegroundColor: String
    var sideMenuBackgroundColor: String
    var sideMenuTextColor: String
    var firebaseEnabled: Bool
    var firebaseListenerEnabled: Bool
    
    init(navigationBackgroundColor: String, navigationForegroundColor: String, sideMenuBackgroundColor: String, sideMenuTextColor: String, firebaseEnabled: Bool, firebaseListenerEnabled: Bool) {
        self.navigationBackgroundColor = navigationBackgroundColor
        self.navigationForegroundColor = navigationForegroundColor
        self.sideMenuBackgroundColor = sideMenuBackgroundColor
        self.sideMenuTextColor = sideMenuTextColor
        self.firebaseEnabled = firebaseEnabled
        self.firebaseListenerEnabled = firebaseListenerEnabled
    }
    
    init(firebaseDict: [String: Any]) {
        self.navigationBackgroundColor = firebaseDict["navigationBackgroundColor"] as? String ?? ""
        self.navigationForegroundColor = firebaseDict["navigationForegroundColor"] as? String ?? ""
        self.sideMenuBackgroundColor = firebaseDict["sideMenuBackgroundColor"] as? String ?? ""
        self.sideMenuTextColor = firebaseDict["sideMenuTextColor"] as? String ?? ""
        self.firebaseEnabled = firebaseDict["firebaseEnabled"] as? Bool ?? true
        self.firebaseListenerEnabled = firebaseDict["firebaseListenerEnabled"] as? Bool ?? true
    }
    
    required init(instance: UIModel) {
        self.navigationBackgroundColor = instance.navigationBackgroundColor
        self.navigationForegroundColor = instance.navigationForegroundColor
        self.sideMenuBackgroundColor = instance.sideMenuBackgroundColor
        self.sideMenuTextColor = instance.sideMenuTextColor
        self.firebaseEnabled = instance.firebaseEnabled
        self.firebaseListenerEnabled = instance.firebaseListenerEnabled
    }
}
