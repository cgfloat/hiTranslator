//
//  HTPhotoTopView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

class HTPhotoTopView: UIView {
    
    var leftActionBlock: (() -> Void)?
    var selectSourceBlock: (() -> Void)?
    var selectTargetBlock: (() -> Void)?

    @IBOutlet weak var sourceLab: UILabel! {
        didSet {
            sourceLab.isUserInteractionEnabled = true
            sourceLab.text = UserDefaults.standard.value(forKey: LaguageString.ocrSourceTitle) as? String
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectSourceLanguage))
            sourceLab.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var sourceImgV: UIImageView! {
        didSet {
            sourceImgV.isUserInteractionEnabled = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectSourceLanguage))
            sourceImgV.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var targetLab: UILabel! {
        didSet {
            targetLab.isUserInteractionEnabled = true
            targetLab.text = UserDefaults.standard.value(forKey: LaguageString.ocrTargetTitle) as? String
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectTargetLanguage))
            targetLab.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var targetImgV: UIImageView! {
        didSet {
            targetImgV.isUserInteractionEnabled = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectTargetLanguage))
            targetImgV.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var leftBtn: UIButton! {
        didSet {
            leftBtn.setTitle("", for: .normal)
        }
    }
    class func loadFromXib() -> HTPhotoTopView {
        let header = Bundle.main.loadNibNamed("HTPhotoTopView", owner: nil, options: nil)?.first as! HTPhotoTopView
        header.frame = CGRect(x: 0, y: 0, width: screen_width, height: 56 + status_height)
        return header
    }

    @IBAction func backAction(_ sender: UIButton) {
        if leftActionBlock != nil {
            leftActionBlock!()
        }
    }
    
    @objc func selectSourceLanguage() {
        if self.selectSourceBlock != nil {
            self.selectSourceBlock!()
        }
    }
    
    @objc func selectTargetLanguage() {
        if self.selectTargetBlock != nil {
            self.selectTargetBlock!()
        }
    }
}
