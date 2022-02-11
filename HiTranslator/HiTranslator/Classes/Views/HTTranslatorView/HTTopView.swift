//
//  HTTopView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

class HTTopView: UIView {
    
    var leftActionBlock: (() -> Void)?
    var rightActionBlock: (() -> Void)?

    @IBOutlet weak var titleLab: UILabel!
    @IBOutlet weak var leftBtn: UIButton! {
        didSet {
            leftBtn.setTitle("", for: .normal)
        }
    }
    @IBOutlet weak var rightBtn: UIButton! {
        didSet {
            rightBtn.setTitle("", for: .normal)
        }
    }
    
    class func loadFromXib() -> HTTopView {
        let header = Bundle.main.loadNibNamed("HTTopView", owner: nil, options: nil)?.first as! HTTopView
        header.frame = CGRect(x: 0, y: 0, width: screen_width, height: 56 + status_height)
        return header
    }
    
    @IBAction func leftAction(_ sender: UIButton) {
        self.leftActionBlock?()
    }
    
    @IBAction func rightAction(_ sender: UIButton) {
        self.rightActionBlock?()
    }
}
