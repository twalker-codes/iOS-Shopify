//
//  UIViewControllerExtensions.swift
//  WebViewTemplate
//
//  Created by Mac on 01/01/21.
//

import UIKit

extension UIViewController {
    
    func barButtonItem(image: UIImage, tag: Int, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        button.tag = tag
        button.addTarget(self, action: action, for: .touchUpInside)
        let scene = UIApplication.shared.connectedScenes.first
        if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate), let uiSettings = sd.uiSettings {
            button.tintColor = UIColor(hexString: uiSettings.navigationForegroundColor)
        } else {
            button.tintColor = .black
        }
        let barButtonView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.frame = barButtonView.bounds
        barButtonView.addSubview(button)
        let barButtonItem = UIBarButtonItem(customView: barButtonView)
        return barButtonItem
    }
    
    func setNavItemTitleImage(imageName: String) {
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
    }
}

extension String {
    
    func base64DecodeCustomerID() -> String {
        var decodedString = ""
        if let decodedData = Data(base64Encoded: self) {
            decodedString = String(data: decodedData, encoding: .utf8)!
        } else {
            decodedString = self
        }
        let components = decodedString.components(separatedBy: "/")
        if let customerID = components.last {
            return customerID
        } else {
            return ""
        }
    }
    
    func base64Decode() -> String {
        let decodedData = Data(base64Encoded: self)!
        let decodedString = String(data: decodedData, encoding: .utf8)!
        return decodedString
    }

    func toBase64() -> String {
        return Data(utf8).base64EncodedString()
    }
}
