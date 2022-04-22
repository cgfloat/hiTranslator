//
//  HTRemoteUtil.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/17.
//

import UIKit
import Firebase

class HTRemoteUtil: NSObject {
    
    static let shared = HTRemoteUtil()
    
    var config = RemoteConfig.remoteConfig()
    
    func defaultConfig() {
        
        var str = ""
        if UserDefaults.standard.value(forKey: RemoteString.config) == nil || UserDefaults.standard.value(forKey: RemoteString.config) as! String == "" {
#if DEBUG
            let filePath = Bundle.main.path(forResource: "hiTranslator-admob", ofType: "json")!
            let fileData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
            str = fileData.base64EncodedString()
#else
            let filePath = Bundle.main.path(forResource: "hiTranslator-admob-release", ofType: "json")!
            let fileData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
            str = fileData.base64EncodedString()
#endif
            
        } else {
            str = UserDefaults.standard.value(forKey: RemoteString.config) as! String
        }
        
        HTLog.log("str: \(str)")
        config.setDefaults(["config": str as NSObject])
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        config.configSettings = settings
        
        self.fetchConfig()
    }
    
    func fetchConfig() {
        
        config.fetch { status, error in
            guard error == nil else {
                HTLog.log("Remote config error: \(error?.localizedDescription ?? "No error available.")")
                return
            }
            HTLog.log("Remote config successfully fetched")
            self.activateConfig()
            
        }
    }
    
    private func activateConfig() {
        config.activate { success, error in
            guard error == nil else {
                HTLog.log("Remote activated error: \(error?.localizedDescription ?? "No error available.")")
                return
            }
            HTLog.log("Remote config successfully activated!")
            DispatchQueue.main.async {
                if let jsonString = self.config["config"].stringValue {
                    if jsonString != UserDefaults.standard.value(forKey: RemoteString.config) as? String {
                        UserDefaults.standard.set(jsonString, forKey: RemoteString.config)
                        let jsonData = Data(base64Encoded: jsonString) ?? Data()
                        HTAdverUtil.shared.adInfo = try! JSONDecoder().decode(HTAdvertiseModel.self, from: jsonData)
                    }
                }
            }
        }
    }
    
}

