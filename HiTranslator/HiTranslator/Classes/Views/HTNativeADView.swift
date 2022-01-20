//
//  HTNativeADView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/20.
//

import UIKit
import GoogleMobileAds

class HTNativeADView: GADNativeAdView {

    @IBOutlet weak var iconImgV: UIImageView! {
        didSet {
            iconView = iconImgV
        }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            headlineView = titleLabel
        }
    }
    @IBOutlet weak var contentLabel: UILabel! {
        didSet {
            bodyView = contentLabel
        }
    }
    @IBOutlet weak var installLabel: UILabel! {
        didSet {
            callToActionView = installLabel
        }
    }
    @IBOutlet weak var titleWidth: NSLayoutConstraint!
    
    /// 原生广告赋值
    override var nativeAd: GADNativeAd? {
        didSet {
            guard let nativeAd = nativeAd else { return }
            (iconView as? UIImageView)?.image = nativeAd.icon?.image
            (headlineView as? UILabel)?.text = nativeAd.headline
            (bodyView as? UILabel)?.text = nativeAd.body
            (callToActionView as? UILabel)?.text = nativeAd.callToAction
            
            let width = titleLabel.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: 16)).width
            titleWidth.constant = width > screen_width - 166 ? screen_width - 166 : width
        }
    }
    
    @objc class func loadFromXib() -> HTNativeADView {
        let header = Bundle.main.loadNibNamed("HTNativeADView", owner: nil, options: nil)?.first as! HTNativeADView
        header.frame = CGRect(x: 0, y: 56 + status_height, width: screen_width, height: 60)
        return header
    }

}
