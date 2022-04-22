//
//  HTRootViewController.swift
//  HiTranslator
//
//  Created by sunhuaiwu on 2022/2/8.
//

import Foundation
import SnapKit
import UIKit

class HTRootViewController:UIViewController{
    
    lazy var nativeV: HTNativeADView = {
        let view = HTNativeADView.loadFromXib()
        view.isHidden = true
        return view
    }()
    
    lazy var placeHolderV: HTNativePlaceHolderView = {
        let view = HTNativePlaceHolderView.loadFromXib()
        view.isHidden = false
        return view
    }()
    
    lazy var titleLab: UILabel = {
        let lab = UILabel()
        lab.text = "Hi Translator"
        lab.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        lab.textColor = UIColor.white
        return lab
    }()
    
    //翻译按钮
    lazy var translateBtn: UIButton  = {
        let btn = UIButton.init(type: .custom)
        btn.setBackgroundImage(UIImage(named: "root_translate"), for: .normal)
        btn.addTarget(self, action: #selector(translateBtnClick), for: .touchUpInside)
        return btn
    }()
    
    //VPN按钮
//    lazy var vpnBtn: UIButton  = {
//        let btn = UIButton.init(type: .custom)
//        btn.setBackgroundImage(UIImage(named: "root_vpn"), for: .normal)
//        btn.addTarget(self, action: #selector(vpnBtnClick), for: .touchUpInside)
//        return btn
//    }()
    
    //背图
    lazy var azImgv: UIImageView = {
        let imgv = UIImageView.init(image: UIImage(named: "root_az_img"))
        return imgv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ColorFromRGB(0x1bc8d2)
        NotificationCenter.default.addObserver(self, selector: #selector(showRootHomeAD), name: Notification.Name.AD.rootHomeNative, object: nil)
        
        view.addSubview(azImgv)
        azImgv.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(50 * screen_height / 680)
            make.width.height.equalTo(290)
        }
        
        view.addSubview(translateBtn)
        translateBtn.snp.makeConstraints { make in
            make.width.equalTo(248)
            make.height.equalTo(128)
            make.centerY.equalTo(azImgv.snp.centerY)
            make.centerX.equalTo(azImgv)
        }
        
//        view.addSubview(vpnBtn)
//        vpnBtn.snp.makeConstraints { make in
//            make.width.equalTo(248)
//            make.height.equalTo(128)
//            make.top.equalTo(translateBtn.snp.bottom).offset(61)
//            make.centerX.equalTo(translateBtn)
//        }
        
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.centerX.equalTo(azImgv)
            make.bottom.equalTo(azImgv.snp.top).offset(-45 * screen_height / 680)
        }
        
        view.addSubview(placeHolderV)
        
        view.addSubview(nativeV)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        HTLog.root_1page()
        showRootHomeAD()
    }
    
    @objc func showRootHomeAD(){
        HTAdverUtil.shared.showNativeAd(type: .rootHome, complete: { [weak self] result, ad in
            if result == true { /// cache 有则加载
                self?.nativeV.isHidden = false
                self?.nativeV.nativeAd = ad
                HTAdverUtil.shared.addShowCount()
                HTAdverUtil.shared.removeCachefirst(type: .rootHome)
                HTAdverUtil.shared.loadNativeAd(type: .rootHome)
            }
        })
    }
    
    @objc func translateBtnClick(){
        let transVC = HTTranslatorViewController()
        self.navigationController?.pushViewController(transVC, animated: true)
        HTLog.root_1page_1()
    }
    
//    @objc func vpnBtnClick(){
//        let vpnVC = HTvHomeViewController()
//        self.navigationController?.pushViewController(vpnVC, animated: true)
//        HTLog.root_1page_2()
//    }
}
