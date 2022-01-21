//
//  AppDelegate.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleMobileAds
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var isloadAD = false
    let loadingV = HTLanuchView.loadFromXib()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        /// Google初始化
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        /// FB初始化
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        Settings.shared.isAdvertiserTrackingEnabled = true
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        Settings.shared.isCodelessDebugLogEnabled = true
        
        HTTransUtil.shared.config()
        HTRemoteUtil.shared.defaultConfig()
        
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
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        UserDefaults.standard.set(Int(Date().timeIntervalSince1970), forKey: RemoteString.overdue)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        loadLaunch()
        HTLog.turn_h()
        
        /// 超过200ms关闭广告
        if UserDefaults.standard.value(forKey: RemoteString.overdue) != nil {
            guard let clickTime = UserDefaults.standard.value(forKey: RemoteString.overdue) as? Int else {
                return
            }
            let now = Int(Date().timeIntervalSince1970)
            if (now * 1000) - (clickTime * 1000) > 200 {
                
                NotificationCenter.default.post(name: NSNotification.Name.Remote.config, object: nil)
                
            }
        }
        
        if let controller = UIApplication.topViewController(), controller.isKind(of: HTRootViewController.self) {
            controller.view.endEditing(true)
            HTLog.textpage()
        }
        
    }
    
    func loadLaunch() {
        
        /// 热启动回来先移除当前显示的缓存
        if let type = HTAdverUtil.shared.type, type != .backRoot, type != .transNative, type != .languageNative, type != .loading {
            HTAdverUtil.shared.removeCachefirst(type: type)
        }
        /// 预加载
        HTAdverUtil.shared.preAllLoadAD()
        
        HTLanuchView.dismiss()
        UIApplication.shared.keyWindow?.addSubview(self.loadingV)
        
        // 定时器10秒无广告放弃加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.5) {
            UIView.animate(withDuration: 1) {
                self.loadingV.progressWidth.constant = 180
                self.loadingV.layoutIfNeeded()
            } completion: { _ in
                HTAdverUtil.shared.loadingSuccessComplete = nil
                self.loadingV.progressWidth.constant = 0
                HTLanuchView.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if self.isloadAD == false {
                        self.getTrackAuth()
                    }
                }
            }
            
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 2.2) {
                self.loadingV.progressWidth.constant = 180 * 0.65
                self.loadingV.layoutIfNeeded()
            } completion: { _ in
                
            }
        }
        
        // 先展示loading1.5秒,监测有广告则0.5秒走完进度条然后展示loading广告
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            
            /// 无成功loading广告,直接
            if HTAdverUtil.shared.canShowAd() == false {
                UIView.animate(withDuration: 1.0) {
                    self.loadingV.progressWidth.constant = 180
                    self.loadingV.layoutIfNeeded()
                } completion: { _ in
                    HTAdverUtil.shared.loadingSuccessComplete = nil
                    self.loadingV.progressWidth.constant = 0
                    HTLanuchView.dismiss()
                    self.getTrackAuth()
                    return
                }
            }
            
            HTAdverUtil.shared.showInterstitialAd(type: .loading) { result, ad in
                if result, let ad = ad {
                    UIView.animate(withDuration: 1.0) {
                        self.loadingV.progressWidth.constant = 180
                        self.loadingV.layoutIfNeeded()
                    } completion: { _ in
                        ad.present(fromRootViewController: UIApplication.topViewController()!)
                        HTAdverUtil.shared.loadingSuccessComplete = nil
                        self.loadingV.progressWidth.constant = 0
                        self.isloadAD = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            HTLanuchView.dismiss()
                        }
                    }
                } else {
                    HTAdverUtil.shared.loadingSuccessComplete = { [weak self] ad in
                        UIView.animate(withDuration: 1.0) {
                            self?.loadingV.progressWidth.constant = 180
                            self?.loadingV.layoutIfNeeded()
                        } completion: { _ in
                            ad?.fullScreenContentDelegate = HTAdverUtil.shared
                            HTAdverUtil.shared.type = .loading
                            ad?.present(fromRootViewController: UIApplication.topViewController()!)
                            HTAdverUtil.shared.loadingSuccessComplete = nil
                            self?.loadingV.progressWidth.constant = 0
                            self?.isloadAD = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                HTLanuchView.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// att权限
    func getTrackAuth() {
        
        NotificationCenter.default.post(name: NSNotification.Name.AD.transNative, object: nil)
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { Status in
                
            }
        } else {
            
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
