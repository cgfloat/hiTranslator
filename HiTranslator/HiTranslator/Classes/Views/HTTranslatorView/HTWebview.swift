//
//  HTWebview.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/6.
//

import UIKit
import WebKit
import SnapKit

class HTWebview: UIView, HTNetworkProtocal {
    
    var text: String = ""
    var url: String = "" {
        didSet {
            HTLog.log("url: \(url)")
        }
    }
    /// 返回翻译结果
    var complete: ((_ result: String, _ success: Bool) -> Void)?
    
    var timer: Timer?
    var isSuccess: Bool = false
    
    lazy var webView: WKWebView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.navigationDelegate = self
        if #available(iOS 11.0, *) {
            $0.scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        return $0
    }(WKWebView(frame: .zero, configuration: {
        $0.allowsInlineMediaPlayback = true
        return $0
    }(WKWebViewConfiguration())))
    
    init(frame: CGRect, text: String, url: String, complete: @escaping(String, Bool) -> Void) {
        self.text = text
        self.complete = complete
        super.init(frame: frame)
        
        self.addSubview(self.webView)
        self.webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        print("url: \(url)")
        /// 中文转义
        let urlS = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        /// 特殊字符转义
        let uurl = URL(string: CFURLCreateStringByAddingPercentEscapes(nil, urlS as CFString, "!*'();:@&=+$,/?%#[]" as CFString, nil, CFStringBuiltInEncodings.UTF8.rawValue) as String)!
        print("uurl: \(uurl)")
        self.webView.load(URLRequest(url: uurl))
        
        /// 17s未返回结果主动结束
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.5) {
            if self.timer != nil {
                self.timer?.invalidate()
                self.timer = nil
                self.complete!("", false)
                self.removeFromSuperview()
            } else if self.isSuccess == false {
                self.complete!("", false)
                self.removeFromSuperview()
            } else {
                self.removeFromSuperview()
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 注入js
    @objc func requestJS() {
        let js = "document.getElementsByClassName('zkZ4Kc dHeVVb')[0].dataset.text"
//        let js = "document.getElementsByClassName('DNFg3e')[0].parentNode.children[0].firstChild.data"
//        let js = "document.getElementById('tta_output_ta').value"
        self.webView.evaluateJavaScript(js) { result, error in
            print("result: \(String(describing: result))\n error: \(String(describing: error))")
            guard error == nil else {
                if self.timer != nil {
                    self.timer?.invalidate()
                    self.timer = nil
                }
                self.complete!("", false)
                self.removeFromSuperview()
                return
            }
            
            if let resultStr = result as? String {
                if resultStr != "" {
                    if self.timer != nil {
                        self.timer?.invalidate()
                        self.timer = nil
                    }
                    self.isSuccess = true
                    self.complete!(resultStr, true)
                    self.removeFromSuperview()
                }
            }
        }
    }
}

extension HTWebview: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("加载开始")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("加载完成")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.requestJS), userInfo: nil, repeats: true)
                RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
                self.timer?.fire()
            }
        }
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.complete!("", false)
        self.removeFromSuperview()
    }
}

