//
//  HTRootViewController.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit
import SnapKit
import ZKProgressHUD
import MLKit

class HTRootViewController: UIViewController, HTNetworkProtocal {
    
    var isTopTrans: Bool = true
    
    lazy var topV: HTTopView = {
        let v = HTTopView.loadFromXib()
        v.titleLab.text = "Translate"
        v.leftActionBlock = { [weak self] in
            let vc = HTSetViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        return v
    }()
    
    lazy var resultV: HTResultView = {
        let v = HTResultView.loadFromXib()
        v.topEditingBlock = { [weak self] in
            self?.isTopTrans = true
            self?.startInput()
        }
        v.bottomEditingBlock = { [weak self] in
            self?.isTopTrans = false
            self?.startInput()
        }
        v.selectSourceBlock = { [weak self] in
            let vc = HTLanguageViewController()
            vc.isSource = true
            vc.isFromText = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        v.selectTargetBlock = { [weak self] in
            let vc = HTLanguageViewController()
            vc.isSource = false
            vc.isFromText = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        return v
    }()
    
    lazy var inputV: HTInputView = {
        let v = HTInputView.loadFromXib()
        v.isHidden = true
        v.alpha = 0
        v.transBlock = { [weak self] text in
            self?.startTranslate(text)
        }
        v.selectBlock = { [weak self] in
            let vc = HTLanguageViewController()
            vc.isSource = !self!.isTopTrans
            vc.isFromText = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        return v
    }()
    
    lazy var bottomBackV: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ColorFromRGB(0x19bbc6)
        view.addSubview(v)
        v.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(48 + safeBottom_height)
        }
        return v
    }()
    
    lazy var photoBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ColorFromRGB(0x19bbc6)
        button.setImage(UIImage(named: "camera"), for: .normal)
        button.setTitle("  OCR", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(48 + safeBottom_height)
        }
        button.addTarget(self, action: #selector(ocrAction), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.ColorFromRGB(0xf5f7fc)
        
        view.addSubview(topV)
        view.addSubview(resultV)
        resultV.snp.makeConstraints { make in
            make.top.equalTo(topV.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(photoBtn.snp.top).offset(-80)
        }
        
        view.addSubview(inputV)
        inputV.snp.makeConstraints { make in
            make.top.equalTo(topV.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(photoBtn.snp.top)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShowNotification(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHideNotification(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.Language.refreshText, object: nil, queue: nil) { _ in
            HTTransUtil.shared.setLanguages(type: .text)
            self.resultV.topLab.text = UserDefaults.standard.value(forKey: LaguageString.textTargetTitle) as? String
            self.resultV.bottomLab.text = UserDefaults.standard.value(forKey: LaguageString.textSourceTitle) as? String
            self.inputV.laguageLab.text = self.isTopTrans ? UserDefaults.standard.value(forKey: LaguageString.textTargetTitle) as? String : UserDefaults.standard.value(forKey: LaguageString.textSourceTitle) as? String
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        HTLog.textpage()
        HTTransUtil.shared.setLanguages(type: .text)
    }
    
    /// 键盘监听
    @objc func handleKeyboardWillShowNotification(_ notification: Notification) {
        if let rect = notification.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect {
            self.inputV.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(-rect.size.height)
                make.top.equalTo(topV.snp.bottom)
            }
            self.inputV.alpha = 1
            if let duration = notification.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? Double {
                UIView.animate(withDuration: duration, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func handleKeyboardWillHideNotification(_ notification: Notification) {
        if let _ = notification.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] {
            self.inputV.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(photoBtn.snp.top)
                make.top.equalTo(topV.snp.bottom)
            }
            self.inputV.alpha = 0
            if let duration = notification.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? Double {
                UIView.animate(withDuration: duration, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func ocrAction() {
        HTLog.textpage_o()
        let vc = HTRecognitionViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func startInput() {
        self.inputV.isHidden = false
        self.inputV.laguageLab.text = isTopTrans ? self.resultV.topLab.text : self.resultV.bottomLab.text
        self.inputV.inputTextV.text = isTopTrans ? self.resultV.topTextV.text : self.resultV.bottomTextV.text
        self.inputV.placeHolderLab.isHidden = self.inputV.inputTextV.text.count > 0
        self.inputV.deleteBtn.isHidden = self.inputV.inputTextV.text.count == 0
        self.inputV.inputTextV.becomeFirstResponder()
        
        if self.isConected() {
            HTLog.textpage_t1()
        }
    }
    
    func dismissInput() {
        self.inputV.inputTextV.resignFirstResponder()
    }
    
    func startTranslate(_ text: String) {
        guard text.count > 0 else {
            return
        }
        
            HTLog.all_use(type: "t")
        
        guard self.isConected() == true else {
            ZKProgressHUD.showMessage("Please turn on your network or wifi", autoDismissDelay: 1.6)
            return
        }
        
            HTLog.textpage_t2()
        HTLog.all_0()
        
            HTTranslatingView.show()
        if isTopTrans {
            let temp = HTTransUtil.shared.sourceLanguage
            HTTransUtil.shared.sourceLanguage = HTTransUtil.shared.targetLanguage
            HTTransUtil.shared.targetLanguage = temp
        }
        
        HTTransUtil.shared.translate(type: .text, text: text) { result, type, time, resultText in

            if self.isTopTrans {
                let temp = HTTransUtil.shared.sourceLanguage
                HTTransUtil.shared.sourceLanguage = HTTransUtil.shared.targetLanguage
                HTTransUtil.shared.targetLanguage = temp
            }
            
            if result, resultText != nil, resultText!.count > 0 {
                HTTranslatingView.dismiss()
                DispatchQueue.main.async() {
                    
                    self.inputV.inputTextV.text = ""
                    self.inputV.placeHolderLab.isHidden = false
                    
                    if self.isTopTrans {
                        self.resultV.topTextV.text = text
                        self.resultV.bottomTextV.text = resultText
                    } else {
                        self.resultV.topTextV.text = resultText
                        self.resultV.bottomTextV.text = text
                    }
                    
                    self.resultV.topDeleteBtn.isHidden = false
                    self.resultV.topPlaceHolderLab.isHidden = true
                    self.resultV.bottomDeleteBtn.isHidden = false
                    self.resultV.bottomPlaceHolderLab.isHidden = true
                    
                    self.inputV.inputTextV.resignFirstResponder()
                    
                        switch type {
                        case .offline:
                            HTLog.textpage_success(type: "off")
                            HTLog.all_1_off(value: time)
                        case .online:
                            HTLog.textpage_success(type: "bi")
                            HTLog.all_1_bi(value: time)
                        case .equally:
                            HTLog.textpage_success(type: "sa")
                            HTLog.all_1_sa()
                        }
                    
                }
            } else {
                HTTranslatingView.dismiss()
//                self.inputV.inputTextV.resignFirstResponder()
                ZKProgressHUD.showMessage("Error, please try it again", autoDismissDelay: 1.7)
            }
            
        }
    }

}
