//
//  HTInputView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit
import ZKProgressHUD

class HTInputView: UIView {
    
    var transBlock: ((_ text: String) -> Void)?
    var selectBlock: (() -> Void)?

    @IBOutlet weak var laguageLab: UILabel! {
        didSet {
            laguageLab.isUserInteractionEnabled = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectLanguage))
            laguageLab.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var laguageImgV: UIImageView! {
        didSet {
            laguageImgV.isUserInteractionEnabled = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectLanguage))
            laguageImgV.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var inputTextV: UITextView! {
        didSet {
            inputTextV.text = ""
            inputTextV.textColor = UIColor.ColorFromRGB(0x1e2c38)
            inputTextV.font = UIFont.systemFont(ofSize: 18, weight: .regular)
            inputTextV.textContainer.lineFragmentPadding = 0
            inputTextV.textContainerInset = .zero
            inputTextV.delegate = self
        }
    }
    @IBOutlet weak var placeHolderLab: UILabel! {
        didSet {
            placeHolderLab.isHidden = false
        }
    }
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var transBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton! {
        didSet {
            deleteBtn.isHidden = true
            deleteBtn.setTitle("", for: .normal)
        }
    }
    class func loadFromXib() -> HTInputView {
        let header = Bundle.main.loadNibNamed("HTInputView", owner: nil, options: nil)?.first as! HTInputView
        return header
    }

    @IBAction func cancelAction(_ sender: UIButton) {
        HTLog.back()
        self.inputTextV.resignFirstResponder()
    }
    @IBAction func transAction(_ sender: UIButton) {
        guard inputTextV.text.count > 0 else {
            ZKProgressHUD.showMessage("Please enter the text", autoDismissDelay: 1.7)
            return
        }
        if transBlock != nil {
            transBlock!(inputTextV.text)
        }
    }
    @IBAction func deleteAction(_ sender: UIButton) {
        self.inputTextV.text = ""
        sender.isHidden = true
        self.placeHolderLab.isHidden = false
    }
    
    @objc func selectLanguage() {
        if self.selectBlock != nil {
            self.selectBlock!()
        }
    }
}

extension HTInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.placeHolderLab.isHidden = textView.text.count > 0
        self.deleteBtn.isHidden = textView.text.count == 0
    }
}
