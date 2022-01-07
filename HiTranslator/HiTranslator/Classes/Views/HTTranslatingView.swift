//
//  HTTranslatingView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

class HTTranslatingView: UIView {

    @IBOutlet weak var loadingLab: UILabel!
    @IBOutlet weak var loadingImgV: UIImageView!
    class func loadFromXib() -> HTTranslatingView {
        let header = Bundle.main.loadNibNamed("HTTranslatingView", owner: nil, options: nil)?.first as! HTTranslatingView
        header.frame = CGRect(x: 0, y: 0, width: screen_width, height: screen_height)
        return header
    }
    
    @objc class func show() {
        guard let window = UIApplication.shared.keyWindow else { return }
        for view in window.subviews {
            if view.isKind(of: HTTranslatingView.self) {
                return
            }
        }
        let progressV = HTTranslatingView.loadFromXib()
        window.addSubview(progressV)
        HTTranslatingView.startAnimotion(view: progressV)
    }

    @objc class func dismiss() {
        
        if let subviews = UIApplication.shared.keyWindow?.subviews {
            for view in subviews {
                if view.isKind(of: HTTranslatingView.self) {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    @objc class func startAnimotion(view: HTTranslatingView) {
        
        let rotationAnimotion = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimotion.fromValue = 0
        rotationAnimotion.toValue = Double.pi * 2
        rotationAnimotion.repeatCount = MAXFLOAT
        rotationAnimotion.duration = 1
        rotationAnimotion.isRemovedOnCompletion = false
        
        view.loadingImgV.layer.add(rotationAnimotion, forKey: "centerLayer")
    }

}
