//
//  AppDelegate.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit
import Firebase
import FBSDKCoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let loadingV = HTLanuchView.loadFromXib()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        /// Google初始化
        FirebaseApp.configure()
        
        /// FB初始化
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        Settings.shared.isAdvertiserTrackingEnabled = true
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        Settings.shared.isCodelessDebugLogEnabled = true
        
        HTTransUtil.shared.config()
        
        HTLog.turn_c()
        
        cofigRootVC()
        loadLaunch()
        
        if UserDefaults.standard.value(forKey: "iscoming") == nil {
            if let country = Locale.current.currencyCode {
                UserDefaults.standard.set(true, forKey: "iscoming")
                HTLog.m(country)
                HTLog.one()
            }
        }
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        loadLaunch()
        HTLog.turn_h()
        
        if let controller = UIApplication.topViewController(), controller.isKind(of: HTRootViewController.self) {
            controller.view.endEditing(true)
            HTLog.textpage()
        }
        
    }
    
    func loadLaunch() {
        HTLanuchView.dismiss()
        UIApplication.shared.keyWindow?.addSubview(self.loadingV)
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 2.2) {
                self.loadingV.progressWidth.constant = 180
                self.loadingV.layoutIfNeeded()
            } completion: { _ in
                self.loadingV.progressWidth.constant = 0
                HTLanuchView.dismiss()
            }
        }
        
    }
    
    /// 初始化根视图
    func cofigRootVC() {
        let rootVC = HTRootViewController()
        let rootnavc = UINavigationController(rootViewController: rootVC)
        rootVC.navigationController?.isNavigationBarHidden = true
        self.window?.rootViewController = rootnavc
        self.window?.makeKeyAndVisible()
    }

}

extension UIApplication {
    
    /// 当前controller
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
