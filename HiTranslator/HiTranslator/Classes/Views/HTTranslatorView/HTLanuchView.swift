//
//  HTLanuchView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

class HTLanuchView: UIView {

    @IBOutlet weak var progressWidth: NSLayoutConstraint!
    class func loadFromXib() -> HTLanuchView {
        let header = Bundle.main.loadNibNamed("HTLanuchView", owner: nil, options: nil)?.first as! HTLanuchView
        header.frame = CGRect(x: 0, y: 0, width: screen_width, height: screen_height)
        return header
    }

    @objc class func dismiss() {
        
        if let subviews = UIApplication.shared.keyWindow?.subviews {
            for view in subviews {
                if view.isKind(of: HTLanuchView.self) {
                    view.removeFromSuperview()
                }
            }
        }
    }
}
