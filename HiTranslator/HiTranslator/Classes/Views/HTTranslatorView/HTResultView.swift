//
//  HTRootView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

class HTResultView: UIView {
    
    var topEditingBlock: (() -> Void)?
    var bottomEditingBlock: (() -> Void)?
    var selectSourceBlock: (() -> Void)?
    var selectTargetBlock: (() -> Void)?

    @IBOutlet weak var centerBtn: UIButton! {
        didSet {
            centerBtn.setTitle("", for: .normal)
        }
    }
    @IBOutlet weak var topLab: UILabel! {
        didSet {
            topLab.isUserInteractionEnabled = true
            topLab.text = UserDefaults.standard.value(forKey: LaguageString.textTargetTitle) as? String
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectTargetLanguage))
            topLab.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var topImgV: UIImageView! {
        didSet {
            topImgV.isUserInteractionEnabled = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectTargetLanguage))
            topImgV.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var topDeleteBtn: UIButton! {
        didSet {
            topDeleteBtn.isHidden = true
            topDeleteBtn.setTitle("", for: .normal)
        }
    }
    @IBOutlet weak var topTextV: UITextView! {
        didSet {
            topTextV.text = ""
            topTextV.textColor = UIColor.ColorFromRGB(0x1e2c38)
            topTextV.font = UIFont.systemFont(ofSize: 18, weight: .regular)
            topTextV.textContainer.lineFragmentPadding = 0
            topTextV.textContainerInset = .zero
            topTextV.delegate = self
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(startEditingTop))
            topTextV.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var topPlaceHolderLab: UILabel!
    @IBOutlet weak var bottomLab: UILabel! {
        didSet {
            bottomLab.isUserInteractionEnabled = true
            bottomLab.text = UserDefaults.standard.value(forKey: LaguageString.textSourceTitle) as? String
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectSourceLanguage))
            bottomLab.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var bottomImgV: UIImageView! {
        didSet {
            bottomImgV.isUserInteractionEnabled = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectSourceLanguage))
            bottomImgV.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var bottomDeleteBtn: UIButton! {
        didSet {
            bottomDeleteBtn.isHidden = true
            bottomDeleteBtn.setTitle("", for: .normal)
        }
    }
    @IBOutlet weak var bottomTextV: UITextView! {
        didSet {
            bottomTextV.text = ""
            bottomTextV.textColor = UIColor.ColorFromRGB(0x1e2c38)
            bottomTextV.font = UIFont.systemFont(ofSize: 18, weight: .regular)
            bottomTextV.textContainer.lineFragmentPadding = 0
            bottomTextV.textContainerInset = .zero
            bottomTextV.delegate = self
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(startEditingBottom))
            bottomTextV.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var bottomPlaceHolderLab: UILabel!
    
    class func loadFromXib() -> HTResultView {
        let header = Bundle.main.loadNibNamed("HTResultView", owner: nil, options: nil)?.first as! HTResultView
        return header
    }

    @IBAction func topDeleteAction(_ sender: UIButton) {
        self.topTextV.text = ""
        sender.isHidden = true
        self.topPlaceHolderLab.isHidden = false
    }
    
    @IBAction func bottomDeleteAction(_ sender: UIButton) {
        self.bottomTextV.text = ""
        sender.isHidden = true
        self.bottomPlaceHolderLab.isHidden = false
    }
    
    @objc func startEditingTop() {
        if self.topEditingBlock != nil {
            self.topEditingBlock!()
        }
    }
    
    @objc func startEditingBottom() {
        if self.bottomEditingBlock != nil {
            self.bottomEditingBlock!()
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

extension HTResultView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.topTextV {
            self.topPlaceHolderLab.isHidden = textView.text.count > 0
            self.topDeleteBtn.isHidden = textView.text.count == 0
        } else {
            self.bottomPlaceHolderLab.isHidden = textView.text.count > 0
            self.bottomDeleteBtn.isHidden = textView.text.count == 0
        }
    }
}
