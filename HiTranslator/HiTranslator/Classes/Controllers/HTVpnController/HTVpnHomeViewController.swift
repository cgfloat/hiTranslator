//
//  HTvHomeViewController.swift
//  HiTranslator
//
//  Created by sunhuaiwu on 2022/2/8.
//

import Foundation
import UIKit
import SnapKit

var hasEnterBackGround = false
class HTvHomeViewController: UIViewController {
    lazy var topV: HTTopView = {
        let v = HTTopView.loadFromXib()
        v.titleLab.text = "Hi Translator"
        v.rightBtn.isHidden = true
        v.leftActionBlock = { [weak self] in
            if self?.vpnConnectView.vpnState == .connecting || self?.vpnConnectView.vpnState == .disConnecting || self?.vpnConnectView.vpnState == .reConnecting {
                return
            }
            HTAdverUtil.shared.showInterstitialAd(type: .backRoot, complete: { result, ad in
                if result, let ad = ad {
                    ad.present(fromRootViewController: self!)
                }
            })
            HTLog.root_1page_ba()
            self?.navigationController?.popViewController(animated: true)
        }
        return v
    }()
    
    lazy var nativeV: HTNativeADView = {
        let view = HTNativeADView.loadFromXib()
        view.isHidden = true
        return view
    }()
    
    lazy var vpnConnectView: HTVpnConnectionView = {
        let vpnView = HTVpnConnectionView.loadFromXib()
        vpnView.showConnectADBlock = { [weak self] ad in
            ad.present(fromRootViewController: self!)
        }
        return vpnView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ColorFromRGB(0xF5F7FC)
        NotificationCenter.default.addObserver(self, selector: #selector(showvHomeAD), name: Notification.Name.AD.vHomeNative, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setSelfWillGoBack), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        view.addSubview(topV)
        view.addSubview(nativeV)
        view.addSubview(vpnConnectView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        HTAdverUtil.shared.loadInterstitialAd(type: .backRoot)
        showvHomeAD()
        HTLog.vpn_vpage()
    }
    
    @objc func showvHomeAD(){
        HTAdverUtil.shared.showNativeAd(type: .vHome, complete: { [weak self] result, ad in
            if result == true { /// cache 有则加载
                self?.nativeV.isHidden = false
                self?.nativeV.nativeAd = ad
                HTAdverUtil.shared.addShowCount()
                HTAdverUtil.shared.removeCachefirst(type: .vHome)
                HTAdverUtil.shared.loadNativeAd(type: .vHome)
            }
        })
    }
    
    @objc func setSelfWillGoBack(){
        hasEnterBackGround = true
    }
}


