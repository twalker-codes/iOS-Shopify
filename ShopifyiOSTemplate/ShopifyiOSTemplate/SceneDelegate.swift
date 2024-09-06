//
//  SceneDelegate.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 04/11/21.
//

import UIKit
import IQKeyboardManagerSwift
import SideMenuSwift
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var uiSettings: UIModel?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        (UIApplication.shared.delegate as? AppDelegate)?.self.window = window
        
        // enable IQKeyboardManager
        IQKeyboardManager.shared.enable = true
        FirebaseApp.configure()
        PushNotificationManager.shared().registerForPushNotifications()
        self.parseTabBar()
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
        }
    }

    // Parse tabBar
    func parseTabBar() {
        PlistParser.parsePlist(plistName: "ShopifyUIConfig") { (uiSettings: UIModel) in
            if uiSettings.firebaseEnabled {
                Firestore.firestore().collection("ShopifyUIConfig").getDocuments { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            self.uiSettings = UIModel(firebaseDict: document.data())
                        }
                        self.launchHomeScreen()
                    }
                }
            } else {
                self.uiSettings = uiSettings
                self.launchHomeScreen()
            }
            
            if uiSettings.firebaseListenerEnabled {
                Firestore.firestore().collection("ShopifyUIConfig").addSnapshotListener { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            self.uiSettings = UIModel(firebaseDict: document.data())
                        }
                        self.launchHomeScreen()
                    }
                }
            }
        }
    }
    
    func launchHomeScreen() {
        self.configureSideMenu()

        if let uiSettings = self.uiSettings {            
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor(hexString: uiSettings.navigationBackgroundColor)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(hexString: uiSettings.navigationForegroundColor)]
            UINavigationBar.appearance().tintColor = UIColor(hexString: uiSettings.navigationForegroundColor)
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController")
        let homeViewController = storyboard.instantiateViewController(withIdentifier: "HomeTabBarController")
        window?.rootViewController = SideMenuController(contentViewController: homeViewController, menuViewController: menuViewController)
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // Config side menu
    private func configureSideMenu() {
        SideMenuController.preferences.basic.menuWidth = 240
        SideMenuController.preferences.basic.defaultCacheKey = "0"
    }
}

