//
//  SceneDelegate.swift
//  NihonRyokou
//
//  Created by m.li on 2025/11/30.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    private let tabBarDelegate = SlidingTabBarDelegate()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        setupTabBar()
        window.makeKeyAndVisible()
    }
    
    func setupTabBar() {
        let inputVC = InputViewController()
        let inputNav = UINavigationController(rootViewController: inputVC)
        inputNav.tabBarItem = UITabBarItem(title: "input_tab".localized, image: UIImage(systemName: "plus.circle.fill"), tag: 0)
        
        let itineraryVC = ViewController()
        let itineraryNav = UINavigationController(rootViewController: itineraryVC)
        itineraryNav.tabBarItem = UITabBarItem(title: "itinerary_tab".localized, image: UIImage(systemName: "list.clipboard.fill"), tag: 1)
        
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "settings_title".localized, image: UIImage(systemName: "gearshape.fill"), tag: 2)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [inputNav, itineraryNav, settingsNav]
        tabBarController.tabBar.tintColor = Theme.accentColor
        tabBarController.tabBar.backgroundColor = .white
        tabBarController.tabBar.isTranslucent = true
        tabBarController.delegate = tabBarDelegate
        
        window?.rootViewController = tabBarController
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTabBarTheme), name: NSNotification.Name("ThemeChanged"), object: nil)
        updateTabBarTheme()
    }
    
    @objc private func updateTabBarTheme() {
        guard let tabBarController = window?.rootViewController as? UITabBarController else { return }
        tabBarController.tabBar.tintColor = Theme.accentColor
        
        // Opaque White Tab Bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
        
        // Global Navigation Bar Appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear] // Hide text
        
        // Use Template mode to allow Tint Color (Theme Color) to apply
        let backImage = UIImage(named: "back-1")?.withRenderingMode(.alwaysTemplate)
        navAppearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .systemBlue
    }
    
    func reloadRootViewController() {
        // Animate the transition
        guard let window = window else { return }
        
        let snapshot = window.snapshotView(afterScreenUpdates: true)
        if let snapshot = snapshot {
            window.addSubview(snapshot)
        }
        
        setupTabBar()
        
        if let snapshot = snapshot {
            window.bringSubviewToFront(snapshot)
            UIView.animate(withDuration: 0.3, animations: {
                snapshot.alpha = 0
            }) { _ in
                snapshot.removeFromSuperview()
            }
        }
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

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

