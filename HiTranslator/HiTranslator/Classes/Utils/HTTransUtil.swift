//
//  HTTransUtil.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/6.
//

import UIKit
import MLKit
import ZKProgressHUD
import MLKitLanguageID
import WebKit
import Firebase

/// text or ocr
enum HTTransSource {
    case text, ocr
}
/// 翻译方法: local 离线  web 网页  same 识别语言与翻译语言相同
enum HTTransType {
    case offline, online, equally
}

class HTTransUtil: NSObject {

    static let shared = HTTransUtil()
    
    /// 翻译type
    var type: HTTransSource = .text
    
    /// 翻译器
    var translator: Translator!
    /// 本地信息
    let locale = Locale.current
    /// 语言列表
    lazy var languageList = TranslateLanguage.allLanguages().sorted {
        return locale.localizedString(forLanguageCode: $0.rawValue)!
        < locale.localizedString(forLanguageCode: $1.rawValue)!
    }
    
    /// 语言识别
    lazy var languageId = LanguageIdentification.languageIdentification()
    
    /// 自动识别语言
    var autoLanguage: TranslateLanguage? {
        didSet {
            if autoLanguage != nil {
                sourceLanguage = autoLanguage
            }
        }
    }
    /// 识别语言
    var sourceLanguage: TranslateLanguage? {
        didSet {
            if sourceLanguage != nil, targetLanguage != nil {
                let options = TranslatorOptions(sourceLanguage: sourceLanguage!, targetLanguage: targetLanguage!)
                self.translator = Translator.translator(options: options)
            }
        }
    }
    /// 翻译语言
    var targetLanguage: TranslateLanguage? {
        didSet {
            if sourceLanguage != nil, targetLanguage != nil {
                let options = TranslatorOptions(sourceLanguage: sourceLanguage!, targetLanguage: targetLanguage!)
                self.translator = Translator.translator(options: options)
            }
        }
    }
    
    /// 初始化
    func config() {
        
        preLoadOfflineLanguage()
        
        if UserDefaults.standard.value(forKey: LaguageString.textSourceTitle) == nil || (UserDefaults.standard.value(forKey: LaguageString.textSourceTitle) as? String)?.count == 0 {
            UserDefaults.standard.setValue("Auto", forKey: LaguageString.textSourceTitle)
        }
        
        if UserDefaults.standard.value(forKey: LaguageString.textTargetTitle) == nil || (UserDefaults.standard.value(forKey: LaguageString.textTargetTitle) as? String)?.count == 0 {
            UserDefaults.standard.setValue("English", forKey: LaguageString.textTargetTitle)
        }
        
        if UserDefaults.standard.value(forKey: LaguageString.textTargetIndex) == nil {
            let index = languageList.firstIndex(of: .english)
            UserDefaults.standard.setValue(index, forKey: LaguageString.textTargetIndex)
        }
        
        if UserDefaults.standard.value(forKey: LaguageString.textSourceIndex) == nil {
            UserDefaults.standard.setValue(-1, forKey: LaguageString.textSourceIndex)
        }
        
        if UserDefaults.standard.value(forKey: LaguageString.ocrSourceTitle) == nil || (UserDefaults.standard.value(forKey: LaguageString.ocrSourceTitle) as? String)?.count == 0 {
            UserDefaults.standard.setValue("Auto", forKey: LaguageString.ocrSourceTitle)
        }
        
        if UserDefaults.standard.value(forKey: LaguageString.ocrTargetTitle) == nil || (UserDefaults.standard.value(forKey: LaguageString.ocrTargetTitle) as? String)?.count == 0 {
            UserDefaults.standard.setValue("English", forKey: LaguageString.ocrTargetTitle)
        }
        
        if UserDefaults.standard.value(forKey: LaguageString.ocrTargetIndex) == nil {
            let index = languageList.firstIndex(of: .english)
            UserDefaults.standard.setValue(index, forKey: LaguageString.ocrTargetIndex)
        }
        
        if UserDefaults.standard.value(forKey: LaguageString.ocrSourceIndex) == nil {
            UserDefaults.standard.setValue(-1, forKey: LaguageString.ocrSourceIndex)
        }
        
        setLanguages(type: .text)
    }
    
    func setLanguages(type: HTTransSource) {
        
        if type == .text {
            if let sourceIndex = UserDefaults.standard.value(forKey: LaguageString.textSourceIndex) as? Int, sourceIndex != -1 {
                self.sourceLanguage = languageList[sourceIndex]
            } else {
                self.sourceLanguage = nil
            }
            
            if let targetIndex = UserDefaults.standard.value(forKey: LaguageString.textTargetIndex) as? Int, targetIndex != -1 {
                self.targetLanguage = languageList[targetIndex]
            } else {
                self.targetLanguage = nil
            }
        } else {
            if let sourceIndex = UserDefaults.standard.value(forKey: LaguageString.ocrSourceIndex) as? Int, sourceIndex != -1 {
                self.sourceLanguage = languageList[sourceIndex]
            } else {
                self.sourceLanguage = nil
            }
            
            if let targetIndex = UserDefaults.standard.value(forKey: LaguageString.ocrTargetIndex) as? Int, targetIndex != -1 {
                self.targetLanguage = languageList[targetIndex]
            } else {
                self.targetLanguage = nil
            }
        }
        
    }
    
    /// 预加载English及本机系统语言
    func preLoadOfflineLanguage() {
        if !self.isLanguageDownloaded(.english) || !self.isLanguageDownloaded(TranslateLanguage(rawValue: locale.languageCode!)) {
            self.preDownloadLanguage(source: TranslateLanguage(rawValue: self.locale.languageCode!), target: .english)
        }
    }
    
    /// 获取当前翻译使用方法
    func getTranslateType(text: String, complete: @escaping(HTTransType) -> Void) {
        /// 自动识别语言
        if targetLanguage == nil {
            complete(.equally)
        } else if sourceLanguage == nil {
            self.recognitionLanguage(text: text) { [weak self] result in
                if result {
                    if let strongSelf = self {
                        if strongSelf.sourceLanguage?.rawValue == strongSelf.targetLanguage?.rawValue {
                            complete(.equally)
                        }
                        if strongSelf.isLanguageDownloaded(strongSelf.sourceLanguage!), strongSelf.isLanguageDownloaded(strongSelf.targetLanguage!) {
                            complete(.offline)
                        } else {
                            complete(.online)
                        }
                    }
                }
            }
        } else {
            if sourceLanguage?.rawValue == targetLanguage?.rawValue {
                complete(.equally)
            }
            if isLanguageDownloaded(sourceLanguage!), isLanguageDownloaded(targetLanguage!) {
                complete(.offline)
            } else {
                complete(.online)
            }
        }
    }
    
    /// 翻译入口
    func translate(type: HTTransSource, text: String, complete: @escaping(Bool, HTTransType, String, String?) -> Void) {
        self.type = type
        /// 记录开始翻译时间
        let startTime = Date().timeIntervalSince1970
        if targetLanguage == nil {
            self.sameTranslate(text: text) { result, resultText in
                let endtime = Date().timeIntervalSince1970
                let time = String(Int(endtime - startTime) + 1)
                complete(result, .equally, time, resultText)
            }
        } else if sourceLanguage == nil {
            /// 自动识别语言
            self.recognitionLanguage(text: text) { [weak self] result in
                if result {
                    if let strongSelf = self {
                        strongSelf.turelyTranslate(text: text, complete: { result, type, resultText in
                            let endtime = Date().timeIntervalSince1970
                            let time = String(Int(endtime - startTime) + 1)
                            complete(result, type, time, resultText)
                        })
                    }
                }
            }
        } else {
            self.turelyTranslate(text: text, complete: { result, type, resultText in
                let endtime = Date().timeIntervalSince1970
                let time = String(Int(endtime - startTime) + 1)
                complete(result, type, time, resultText)
            })
        }
    }
    /// 翻译方法判断
    func turelyTranslate(text: String, complete: @escaping(Bool, HTTransType, String?) -> Void) {
        if sourceLanguage?.rawValue == targetLanguage?.rawValue {
            self.sameTranslate(text: text) { result, resultText in
                complete(result, .equally, resultText)
            }
            return
        }
        if isLanguageDownloaded(sourceLanguage!), isLanguageDownloaded(targetLanguage!) {
            self.localTranslate(text: text) { result, resultText in
                complete(result, .offline, resultText)
            }
        } else {
            self.preDownloadLanguage(source: sourceLanguage!, target: targetLanguage!)

            guard text.count <= 5000 else {
                ZKProgressHUD.showMessage("The word count has exceeded the limit", autoDismissDelay: 1.7)
                HTTranslatingView.dismiss()
                return
            }
            self.netTranslate(text: text, source: sourceLanguage!, target: targetLanguage!) { result, resultText in
                complete(result, .online, resultText)
            }
        }
    }
}
// MARK: - 离线翻译
extension HTTransUtil {
    /// 文本翻译
    func localTranslate(text: String, complete: @escaping(Bool, String?) -> Void) {
        
        var resultString: String?
        /// gcd group
        let transGroup = DispatchGroup()
        /// 最少加载2.4s
        DispatchQueue.global().async(group: transGroup, execute: DispatchWorkItem(block: {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.1) {
                semaphore.signal()
            }
            semaphore.wait()
        }))
        
        let translatorForDownloading = self.translator!
        
        /// 翻译
        DispatchQueue.global().async(group: transGroup, execute: DispatchWorkItem(block: {
            let semaphore = DispatchSemaphore(value: 0)
            // 监测语言包
            translatorForDownloading.downloadModelIfNeeded { error in
                guard error == nil else {
                    print("Failed to ensure model downloaded with error \(error!)")
                    semaphore.signal()
                    return
                }
                // 有语言包开始翻译
                if translatorForDownloading == self.translator {
                    translatorForDownloading.translate(text) { result, error in
                        guard error == nil else {
                            print("Failed with error \(error!)")
                            semaphore.signal()
                            return
                        }
                        // 翻译成功
                        if translatorForDownloading == self.translator {
                            print(result ?? "")
                            
                            resultString = result ?? ""
                        }
                        semaphore.signal()
                    }
                }
            }
            semaphore.wait()
        }))
        
        transGroup.notify(queue: DispatchQueue.main) {
            if resultString != nil {
                complete(true, resultString)
            } else {
                complete(false, resultString)
            }
        }
        
    }
    
    func model(forLanguage: TranslateLanguage) -> TranslateRemoteModel {
        return TranslateRemoteModel.translateRemoteModel(language: forLanguage)
    }
    /// 语言包是否下载
    func isLanguageDownloaded(_ language: TranslateLanguage) -> Bool {
        let model = self.model(forLanguage: language)
        let modelManager = ModelManager.modelManager()
        return modelManager.isModelDownloaded(model)
    }
    /// 此方法用来提前下载语言包
    func preDownloadLanguage(source: TranslateLanguage, target: TranslateLanguage) {
        
        let options = TranslatorOptions(sourceLanguage: source, targetLanguage: target)
        let translatorDownloading = Translator.translator(options: options)
        
        translatorDownloading.downloadModelIfNeeded { error in
            guard error == nil else {
                print("Failed to ensure model downloaded with error \(error!)")
                return
            }
            
            if translatorDownloading == self.translator {
                translatorDownloading.translate("hello") { result, error in
                    guard error == nil else {
                        print("Failed with error \(error!)")
                        return
                    }
                    if translatorDownloading == self.translator {
                        print(result ?? "")
                    }
                }
            }
        }
    }
}
// MARK: - 网页翻译
extension HTTransUtil {
    /// 该方法会加载一个隐藏的webview,通过执行js获取网页翻译结果
    func netTranslate(text: String, source: TranslateLanguage, target: TranslateLanguage, complete: @escaping(Bool, String?) -> Void) {
        let webview = HTWebview(frame: .zero, text: text, url: "https://translate.google.com/?sl=\(source.rawValue == "zh" ? "zh-CN" : source.rawValue)&tl=\(target.rawValue == "zh" ? "zh-CN" : target.rawValue)&text=\(text)&op=translate", complete: { result, isSuccess in
            
            guard isSuccess == true else {
                /// 注入js失败
                complete(false, nil)
                return
            }
            
            /// 翻译成功
            complete(true, result)
            
            print("result: \(result)")
        })
        webview.isHidden = true
        UIApplication.topViewController()?.view.addSubview(webview)
    }
}
// MARK: - 识别语言与翻译语言相同
extension HTTransUtil {
    /// 翻译语言与识别语言相同只需要延时返回结果
    func sameTranslate(text: String, complete: @escaping(Bool, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            complete(true, text)
        }
    }
}

// MARK: - 语言识别
extension HTTransUtil {
    ///
    func recognitionLanguage(text: String, complete: @escaping(Bool) -> Void) {
        languageId.identifyLanguage(for: text) { (languageTag, error) in
            if let _ = error {
                complete(false)
                return
            }
            print("languageTag: \(String(describing: languageTag))")
            self.autoLanguage = TranslateLanguage(rawValue: self.displayName(for: languageTag!))
            complete(true)
        }
    }
    /// 识别语言名称
    func displayName(for languageTag: String) -> String {
        if languageTag == IdentifiedLanguage.undetermined {
            return "Undetermined Language"
        }
        return languageTag
    }
}

