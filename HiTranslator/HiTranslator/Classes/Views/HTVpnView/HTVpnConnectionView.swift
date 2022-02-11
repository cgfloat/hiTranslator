//
//  HTVpnConnectionView.swift
//  HiTranslator
//
//  Created by sunhuaiwu on 2022/2/8.
//

import Foundation
import UIKit
import Alamofire
import ZKProgressHUD
import GoogleMobileAds
import Reachability

class HTVpnConnectionView:UIView{
    //展示连接ad
    var showConnectADBlock: ((GADInterstitialAd) -> Void)?
    
    //vpn 状态变化
    var vpnState:HTVpnState!{
        didSet{
            switch vpnState {
            case .connecting:
                showConnectingAni()
            case .disConnecting:
                showDisConnectingAni()
            case .connected:
                showConnectedSate()
            default:
                showDisConnectedSate()
            }
        }
    }
    private var selectServer:HTServerModel?             //当前真实选择的服务器
    
    class func loadFromXib() -> HTVpnConnectionView {
        let xib = Bundle.main.loadNibNamed("HTVpnConnectionView", owner: nil, options: nil)?.first as! HTVpnConnectionView
        let height = screen_width * 431 / 360 + 105
        xib.frame = CGRect(x: 0, y: screen_height - height, width: screen_width, height: height)
        xib.checkVPNstate()
        xib.setVpnStateHandle()
        return xib
    }
    
    @IBOutlet weak var connectBtn: UIButton! {
        didSet {
            connectBtn.setTitle("", for: .normal)
        }
    }
    @IBOutlet weak var connectBtnImg: UIImageView!
    @IBOutlet weak var connectStateView: UIView! {
        didSet{
            connectStateView.layer.cornerRadius = 4.5
            connectStateView.layer.borderColor = UIColor.ColorFromRGB(0xff9898).cgColor
            connectStateView.layer.borderWidth = 1.5
        }
    }
    @IBOutlet weak var connectStateLab: UILabel!
    @IBOutlet weak var serverImg: UIImageView!
    @IBOutlet weak var serverLab: UILabel!
    
    @IBAction func connectBtnClick(_ sender: UIButton) {
        if vpnState == .connecting || vpnState == .disConnecting || vpnState == .reConnecting {
            return
        }
        else if vpnState == .connected{
            self.vpnState = .disConnecting
            self.disconnectVPN()
        }
        else{
            self.connectVPN()
        }
    }

    //connecting 动态层
    @IBOutlet weak var centerAniView: UIView!
    lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.lineWidth = 16
        layer.strokeColor = UIColor.ColorFromRGB(0x19bbc6).cgColor
        layer.fillColor = UIColor.clear.cgColor
        let path = UIBezierPath(arcCenter: CGPoint(x: connectBtn.bounds.width/2.0, y: connectBtn.bounds.height/2.0), radius: connectBtn.bounds.width/2.0 - 8, startAngle: -CGFloat.pi/2.0, endAngle: CGFloat.pi/2.0, clockwise: true)
        layer.path = path.cgPath
        return layer
    }()
}

//VPN 连接相关
extension HTVpnConnectionView {
    
    private func checkVPNstate(){
        HTVpnManager.shared.loadConfigFromPreferences { state in
            if state == .connected{
                let name = UserDefaults.standard.object(forKey: "connectServerName") as! String
                let icon = UserDefaults.standard.object(forKey: "connectServerIcon") as! String
                self.selectServer = HTServerModel(countryName: name, countryIcon: icon, host: "")
                self.vpnState = .connected
            }
            else{
                self.vpnState = .disConnected
            }
        }
    }
    
    private func setVpnStateHandle() {
        HTVpnManager.shared.vpnStatusChangedHandle = { [self] vpnS in
            switch vpnS {
            case .connected:
                self.vpnState = .connected
                HTAdverUtil.shared.loadInterstitialAd(type: .vConnect)
            case .disConnected:
                self.vpnState = .disConnected
            case .error:
                self.vpnState = .disConnected
                ZKProgressHUD.showMessage("Failed connection", autoDismissDelay: 2.5)
            case .noNetwork:
                self.vpnState = .disConnected
                ZKProgressHUD.showMessage("Find some wrong", autoDismissDelay: 2.5)
            default:
                break
            }
        }
    }
    
    private func connectVPN(){
        HTVpnManager.shared.setupProvider() {
            self.vpnState = .connecting
            let reachability = try! Reachability()
            if reachability.connection != .unavailable {
                HTLog.vpn_vuse1()
            }
            else{
                self.vpnState = .disConnected
                ZKProgressHUD.showMessage("Find some wrong", autoDismissDelay: 2.5)
                return
            }
            HTVpnManager.shared.pingServer(list: HTServerList) {[weak self] sortedList in
                HTLog.vpn_vuse2()
                self?.selectServer = sortedList.first!
                HTAdverUtil.shared.showVpnConnectAdInTime { result, ad in
                    if isEnterBackground {
                        self?.vpnState = .disConnected
                    }else{
                        if result, let ad = ad {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self?.showConnectADBlock?(ad)
                            }
                        }
                        if self!.selectServer!.delay > 9998{
                            self?.vpnState = .disConnected
                            ZKProgressHUD.showMessage("Failed connection", autoDismissDelay: 2.5)
                        }
                        else{
                            HTVpnManager.shared.VPNConnect(server: self!.selectServer!)
                            HTLog.vpn_vuse3(country:  self!.selectServer!.countryIcon)
                            UserDefaults.standard.set(self!.selectServer!.countryName, forKey: "connectServerName")
                            UserDefaults.standard.set(self!.selectServer!.countryIcon, forKey: "connectServerIcon")
                        }
                    }
                }
            }
        }
    }
    
    private func disconnectVPN(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            HTVpnManager.shared.VPNDisConnect()
            HTLog.vpn_vdisuse()
            if !isEnterBackground {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    HTAdverUtil.shared.showInterstitialAd(type: .vConnect) {[weak self] result, ad in
                        if result, let ad = ad {
                            self?.showConnectADBlock?(ad)
                        }
                    }
                }
            }
        }
    }
}
    
//VPN 连接状态动画
extension HTVpnConnectionView {
    
    //连接动画
    private func showConnectingAni(){
        connectStateView.layer.borderColor = UIColor.ColorFromRGB(0x19bbc6).cgColor
        connectStateLab.text = "VPN is connecting..."
        connectBtn.setImage(UIImage(named: "vpn_disconnected_btn"), for: .normal)
        connectBtnImg.image = UIImage(named: "vpn_connecting")
        
        shapeLayer.removeAllAnimations()
        centerAniView.layer.removeAllAnimations()
        centerAniView.layer.addSublayer(shapeLayer)
        
        let aniL = CABasicAnimation(keyPath: "strokeEnd")
        aniL.fromValue = 0.2
        aniL.toValue = 1.2
        aniL.duration = 2.5
        aniL.repeatCount = Float.infinity
        aniL.timingFunction = CAMediaTimingFunction(name: .linear)
        aniL.isRemovedOnCompletion = false
        aniL.autoreverses = true
        shapeLayer.add(aniL, forKey: "connecting_strokeLayer")
        
        let ani = CABasicAnimation(keyPath: "transform.rotation")
        ani.fromValue = 0
        ani.toValue = CGFloat.pi * 2
        ani.duration = 1.5
        ani.repeatCount = Float.infinity
        ani.timingFunction = CAMediaTimingFunction(name: .linear)
        ani.isRemovedOnCompletion = false
        centerAniView.layer.add(ani, forKey: "connecting_rotation")
        connectBtnImg.layer.add(ani, forKey: "btn_rotation")
    }
    
    //断开动画
    private func showDisConnectingAni(){
        connectStateView.layer.borderColor = UIColor.ColorFromRGB(0x19bbc6).cgColor
        connectStateLab.text = "VPN is disconnecting..."
        connectBtn.setImage(UIImage(named: "vpn_disconnected_btn"), for: .normal)
        connectBtnImg.image = UIImage(named: "vpn_connected")
        shapeLayer.removeAllAnimations()
        centerAniView.layer.removeAllAnimations()
        connectBtnImg.layer.removeAllAnimations()
        centerAniView.layer.addSublayer(shapeLayer)
        
        let aniL = CABasicAnimation(keyPath: "strokeEnd")
        aniL.fromValue = 1.2
        aniL.toValue = 0.2
        aniL.duration = 2.5
        aniL.repeatCount = Float.infinity
        aniL.timingFunction = CAMediaTimingFunction(name: .linear)
        aniL.isRemovedOnCompletion = false
        aniL.autoreverses = true
        shapeLayer.add(aniL, forKey: "disconnecting_strokeLayer")
        
        let ani = CABasicAnimation(keyPath: "transform.rotation")
        ani.fromValue = CGFloat.pi * 2
        ani.toValue = 0
        ani.duration = 1.5
        ani.repeatCount = Float.infinity
        ani.timingFunction = CAMediaTimingFunction(name: .linear)
        ani.isRemovedOnCompletion = false
        centerAniView.layer.add(ani, forKey: "disconnecting_rotation")
    }
    
    private func showConnectedSate(){
        connectStateView.layer.borderColor = UIColor.ColorFromRGB(0x19bbc6).cgColor
        connectStateLab.text = "VPN is connected"
        serverImg.image = UIImage(named: self.selectServer!.countryIcon)
        serverLab.text = self.selectServer!.countryName
        
        shapeLayer.removeAllAnimations()
        centerAniView.layer.removeAllAnimations()
        connectBtnImg.layer.removeAllAnimations()
        shapeLayer.removeFromSuperlayer()
        connectBtn.setImage(UIImage(named: "vpn_connected_btn"), for: .normal)
        connectBtnImg.image = UIImage(named: "vpn_connected")
    }
    
    private func showDisConnectedSate(){
        connectStateView.layer.borderColor = UIColor.ColorFromRGB(0xff9898).cgColor
        connectStateLab.text = "VPN is disconnected"
        serverImg.image = UIImage(named: "countrySmart")
        serverLab.text = "Smart Server"
        
        shapeLayer.removeAllAnimations()
        centerAniView.layer.removeAllAnimations()
        connectBtnImg.layer.removeAllAnimations()
        shapeLayer.removeFromSuperlayer()
        connectBtn.setImage(UIImage(named: "vpn_disconnected_btn"), for: .normal)
        connectBtnImg.image = UIImage(named: "vpn_disconnected")
    }
}

