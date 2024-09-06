//
//  PushNotificationManager.swift
//  EnvatoSalesTracker
//
//  Created by Mac on 27/05/23.
//

import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Properties
    private static var pushNotificationManager: PushNotificationManager = {
        let pushNotificationManager = PushNotificationManager()
        return pushNotificationManager
    }()
    
    // Initialization
    private override init() { }

    // MARK: - Accessors
    class func shared() -> PushNotificationManager {
        return pushNotificationManager
    }
    
    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
//        updateFirestorePushTokenIfNeeded()
    }
    
    func updateFirestorePushTokenIfNeeded() {
        if let customerID = AccountController.shared.customerID, !customerID.isEmpty, let token = Messaging.messaging().fcmToken {
            let docRef = Firestore.firestore().collection("shopifyusers").document(customerID)
            docRef.setData(["deviceToken": token], merge: true)
        }
    }
    
    func removeFirestorePushTokenIfNeeded() {
        if let customerID = AccountController.shared.customerID, !customerID.isEmpty {
            let docRef = Firestore.firestore().collection("shopifyusers").document(customerID)
            docRef.setData(["deviceToken": ""], merge: true)
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        updateFirestorePushTokenIfNeeded()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

