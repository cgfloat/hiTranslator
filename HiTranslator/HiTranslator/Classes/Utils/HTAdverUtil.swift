//
//  HTAdverUtil.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/17.
//

import UIKit
import GoogleMobileAds

enum HTAdvertiseType: String, Codable {
    case loading = "loading"
    case transInter = "transInter"
    case transNative = "transNative"
    case photoInter = "photoInter"
    case languageNative = "languageNative"
    case backRoot = "backRoot"
    case vpn = "vpn"
}

struct HTAdvertiseItem: Codable {
    var adId: String!
    var adSort: Int!
    var adType: String!
}

/// 广告列表
struct HTAdvertiseModel: Codable {
    var loading: [HTAdvertiseItem]!
    var transInter: [HTAdvertiseItem]!
    var transNative: [HTAdvertiseItem]!
    var photoInter: [HTAdvertiseItem]!
    var languageNative: [HTAdvertiseItem]!
    var backRoot: [HTAdvertiseItem]!
    var totalShowCount: Int!
    var totalClickCount: Int!
}

/// 缓存广告
class HTAdvertiseCache: NSObject {
    var adId: String!
    var adSort: Int!
    var adType: HTAdvertiseType!
    var advertise: NSObject?
}

class HTAdverUtil: NSObject {
    
    static let shared = HTAdverUtil()
    
    /// 缓存定时器
    var cacheTimer: DispatchSourceTimer?
    
    /// 广告type
    var type: HTAdvertiseType?
    
    var rootViewController: UIViewController!
    /// 显示和点击次数
    var adCounts: HTAdvertiseCounts?
    
    /// 广告数据
    var adInfo = HTAdvertiseModel() {
        didSet {
            removeAllCache()
            
            loadingAdItems = adInfo.loading.sorted(by: { $0.adSort < $1.adSort })
            transInterItems = adInfo.transInter.sorted(by: { $0.adSort < $1.adSort })
            transNativeItems = adInfo.transNative.sorted(by: { $0.adSort < $1.adSort })
            photoInterItems = adInfo.photoInter.sorted(by: { $0.adSort < $1.adSort })
            languageNativeItems = adInfo.languageNative.sorted(by: { $0.adSort < $1.adSort })
            backRootItems = adInfo.backRoot.sorted(by: { $0.adSort < $1.adSort })
            //            vpnItems = adInfo.vpn.sorted(by: { $0.advertiseSort < $1.advertiseSort })
            
            preAllLoadAD()
        }
    }
    // 冷热加载
    var loadingAdItems = [HTAdvertiseItem]()
    var loadingCache = [[TimeInterval: HTAdvertiseCache]]()
    var loadingAdIsLoding = false
    var loadingIndex = 0
    var loadingSuccessComplete: ((_ ad: GADInterstitialAd?) -> Void)?
    // 文本翻译
    var transInterItems = [HTAdvertiseItem]()
    var transInterCache = [[TimeInterval: HTAdvertiseCache]]()
    var transInterIsLoding = false
    var transInterIndex = 0
    // 拍照翻译
    var photoInterItems = [HTAdvertiseItem]()
    var photoInterCache = [[TimeInterval: HTAdvertiseCache]]()
    var photoInterIsLoding = false
    var photoInterIndex = 0
    // 返回主页
    var backRootItems = [HTAdvertiseItem]()
    var backRootCache = [[TimeInterval: HTAdvertiseCache]]()
    var backRootIsLoding = false
    var backRootIndex = 0
    // vpn
    var vpnItems = [HTAdvertiseItem]()
    var vpnCache = [[TimeInterval: HTAdvertiseCache]]()
    var vpnIsLoding = false
    var vpnIndex = 0
    
    /// 翻译原生
    var transNativeItems = [HTAdvertiseItem]()
    var transNativeLoader: GADAdLoader?
    var transNativeCache = [[TimeInterval: HTAdvertiseCache]]()
    var transNativeIndex = 0
    var transNativeSuccessComplete: ((_ ad: GADNativeAd?) -> Void)?
    //    var transNativeTimer: Timer?
    var transNativeCanShow = true
    
    // 选择语言原生
    var languageNativeItems = [HTAdvertiseItem]()
    var languageNativeLoader: GADAdLoader?
    var languageNativeCache = [[TimeInterval: HTAdvertiseCache]]()
    var languageNativeIndex = 0
    //    var languageNativeTimer: Timer?
    var languageNativeCanShow = true
    
    private override init() {
        super.init()
        
        if UserDefaults.standard.value(forKey: RemoteString.config) == nil || UserDefaults.standard.value(forKey: RemoteString.config) as! String == "" {
#if DEBUG
            let filePath = Bundle.main.path(forResource: "hiTranslator-admob", ofType: "json")!
            let fileData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
            adInfo = try! JSONDecoder().decode(HTAdvertiseModel.self, from: fileData)
#else
            let filePath = Bundle.main.path(forResource: "hiTranslator-admob-release", ofType: "json")!
            let fileData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
            adInfo = try! JSONDecoder().decode(HTAdvertiseModel.self, from: fileData)
#endif
        } else {
            let jsonString = UserDefaults.standard.value(forKey: RemoteString.config) as! String
            let jsonData = Data(base64Encoded: jsonString) ?? Data()
            adInfo = try! JSONDecoder().decode(HTAdvertiseModel.self, from: jsonData)
        }
        
        HTRootUtil.admodel = adInfo
        HTLog.log("adInfo: \(adInfo)")
        
        // init datas
        loadingAdItems = adInfo.loading.sorted(by: { $0.adSort < $1.adSort })
        transInterItems = adInfo.transInter.sorted(by: { $0.adSort < $1.adSort })
        transNativeItems = adInfo.transNative.sorted(by: { $0.adSort < $1.adSort })
        photoInterItems = adInfo.photoInter.sorted(by: { $0.adSort < $1.adSort })
        languageNativeItems = adInfo.languageNative.sorted(by: { $0.adSort < $1.adSort })
        backRootItems = adInfo.backRoot.sorted(by: { $0.adSort < $1.adSort })
        //        vpnItems = adInfo.vpn.sorted(by: { $0.advertiseSort < $1.advertiseSort })
        
        // setup counts
        setupAdmobCounts()
        
        // refresh caches
        cacheTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        cacheTimer?.setEventHandler(handler: { [weak self] in
            self?.refreshTotalAdCache()
        })
        cacheTimer?.schedule(deadline: .now(), repeating: 60)
        cacheTimer?.resume()
    }
    /// 预加载
    func preAllLoadAD() {
        self.loadInterstitialAd(type: .transInter)
        self.loadInterstitialAd(type: .photoInter)
        
        self.loadNativeAd(type: .transNative)
        self.loadNativeAd(type: .languageNative)
    }
}

extension HTAdverUtil {
    /// 插屏广告加载
    func loadInterstitialAd(type: HTAdvertiseType, index: Int = 0) {
        // 是否可显示
        if canShowAd() == false {
            if type == .loading {
                /// 无成功loading广告,直接
                if let app = UIApplication.shared.delegate as? AppDelegate {
                    UIView.animate(withDuration: 1.0) {
                        app.loadingV.progressWidth.constant = 180
                        app.loadingV.layoutIfNeeded()
                    } completion: { _ in
                        HTAdverUtil.shared.loadingSuccessComplete = nil
                        app.loadingV.progressWidth.constant = 0
                        app.getTrackAuth()
                        HTLanuchView.dismiss()
                    }
                }
                
            }
            return
        }
        // 是否在加载中 及 检查数组是否越界
        var items = [HTAdvertiseItem]()
        switch type {
        case .loading:
            if loadingCache.count > 0 {
                return
            }
            if loadingAdIsLoding {
                HTLog.log("[AD] 广告正在加载 type: \(type.rawValue)")
                return
            }
            if index > loadingAdItems.count - 1 {
                HTLog.log("[AD] 广告加载超过列表个数 type: \(type.rawValue)")
                /// 无成功loading广告,直接
                if let app = UIApplication.shared.delegate as? AppDelegate {
                    UIView.animate(withDuration: 1.0) {
                        app.loadingV.progressWidth.constant = 180
                        app.loadingV.layoutIfNeeded()
                    } completion: { _ in
                        HTAdverUtil.shared.loadingSuccessComplete = nil
                        app.loadingV.progressWidth.constant = 0
                        app.getTrackAuth()
                        HTLanuchView.dismiss()
                    }
                }
                return
            }
            loadingIndex = index
            loadingAdIsLoding = true
            items = loadingAdItems
        case .transInter:
            if transInterCache.count > 0 {
                return
            }
            if transInterIsLoding {
                HTLog.log("[AD] 广告正在加载 type: \(type.rawValue)")
                return
            }
            if index > transInterItems.count - 1 {
                HTLog.log("[AD] 广告加载超过列表个数 type: \(type.rawValue)")
                return
            }
            transInterIndex = index
            transInterIsLoding = true
            items = transInterItems
        case .photoInter:
            if photoInterCache.count > 0 {
                return
            }
            if photoInterIsLoding {
                HTLog.log("[AD] 广告正在加载 type: \(type.rawValue)")
                return
            }
            if index > photoInterItems.count - 1 {
                HTLog.log("[AD] 广告加载超过列表个数 type: \(type.rawValue)")
                return
            }
            photoInterIndex = index
            photoInterIsLoding = true
            items = photoInterItems
        case .vpn:
            if vpnCache.count > 0 {
                return
            }
            if vpnIsLoding {
                HTLog.log("[AD] 广告正在加载 type: \(type.rawValue)")
                return
            }
            if index > vpnItems.count - 1 {
                HTLog.log("[AD] 广告加载超过列表个数 type: \(type.rawValue)")
                return
            }
            vpnIndex = index
            vpnIsLoding = true
            items = vpnItems
        case .backRoot:
            if backRootCache.count > 0 {
                return
            }
            if backRootIsLoding {
                HTLog.log("[AD] 广告正在加载 type: \(type.rawValue)")
                return
            }
            if index > backRootItems.count - 1 {
                HTLog.log("[AD] 广告加载超过列表个数 type: \(type.rawValue)")
                return
            }
            backRootIndex = index
            backRootIsLoding = true
            items = backRootItems
        default:
            return
        }
        
        // 加载
        let unitID = items[index].adId!
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: unitID, request: request) { ad, error in
            
            switch type {
            case .loading:
                self.loadingAdIsLoding = false
            case .transInter:
                self.transInterIsLoding = false
            case .photoInter:
                self.photoInterIsLoding = false
            case .backRoot:
                self.backRootIsLoding = false
            case .vpn:
                self.vpnIsLoding = false
            default:
                return
            }
            guard error == nil else {
                HTLog.log("[AD] 广告加载失败 type: \(type.rawValue) 优先级: \(index + 1), unitID: \(unitID)")
                self.loadInterstitialAd(type: type, index: index + 1)
                return
            }
            
            if let ad = ad {
                let item = items[index]
                let cache = HTAdvertiseCache()
                cache.adId = item.adId
                cache.adSort = item.adSort
                cache.adType = type
                cache.advertise = ad
                
                /// 加入缓存
                self.addCacheByType(type: type, model: cache)
                HTLog.log("[AD] 广告加载成功 type: \(type.rawValue) 优先级: \(index + 1), unitID: \(unitID)")
                if type == .loading, self.loadingSuccessComplete != nil {
                    self.loadingSuccessComplete!(ad)
                }
                
            } else {
                HTLog.log("[AD] 广告加载失败 type: \(type.rawValue) 优先级: \(index + 1), unitID: \(unitID)")
                self.loadInterstitialAd(type: type, index: index + 1)
            }
        }
    }
    
    /// 插屏广告显示
    func showInterstitialAd(type: HTAdvertiseType, complete: @escaping(Bool, GADInterstitialAd?) -> Void) {
        // 是否可显示
        if canShowAd() == false {
            complete(false, nil)
            return
        }
        // 是否有缓存
        if self.getCacheByType(type: type)!.count > 0 {
            self.type = type
            if let ad = self.getCacheByType(type: type)!.first!.first?.value.advertise as? GADInterstitialAd {
                ad.fullScreenContentDelegate = self
                complete(true, ad)
            } else {
                removeCachefirst(type: type)
                if type != .backRoot {
                    self.loadInterstitialAd(type: type)
                }
                self.type = nil
                complete(false, nil)
            }
        } else {
            if type != .backRoot {
                self.loadInterstitialAd(type: type)
            }
            self.type = nil
            complete(false, nil)
            HTLog.log("没有缓存")
        }
    }
    
    /// 原生广告加载
    func loadNativeAd(type: HTAdvertiseType, index: Int = 0) {
        // 是否可显示
        if canShowAd() == false {
            return
        }
        switch type {
        case .transNative:
            //            if transNativeCanShow == false {
            //                HTLog.log("[AD] 广告刷新间隔未到 type: \(type.rawValue)")
            //                return
            //            }
            if transNativeCache.count > 0 {
                return
            }
            // 是否在加载中 及 检查数组是否越界
            if transNativeLoader?.isLoading == true {
                HTLog.log("[AD] 广告加载中 type: \(type.rawValue)")
                return
            }
            if index > transNativeItems.count - 1 {
                HTLog.log("[AD] 广告加载超过列表个数 type: \(type.rawValue)")
                return
            }
            // 加载
            transNativeIndex = index
            transNativeLoader = GADAdLoader(adUnitID: transNativeItems[index].adId, rootViewController: rootViewController, adTypes: [.native], options: nil)
            transNativeLoader?.delegate = self
            transNativeLoader?.load(GADRequest())
        case .languageNative:
            //            if languageNativeCanShow == false {
            //                HTLog.log("[AD] 广告刷新间隔未到 type: \(type.rawValue)")
            //                return
            //            }
            if languageNativeCache.count > 0 {
                return
            }
            // 是否在加载中 及 检查数组是否越界
            if languageNativeLoader?.isLoading == true {
                HTLog.log("[AD] 广告加载中 type: \(type.rawValue)")
                return
            }
            if index > languageNativeItems.count - 1 {
                HTLog.log("[AD] 广告加载超过列表个数 type: \(type.rawValue)")
                return
            }
            // 加载
            languageNativeIndex = index
            languageNativeLoader = GADAdLoader(adUnitID: languageNativeItems[index].adId, rootViewController: rootViewController, adTypes: [.native], options: nil)
            languageNativeLoader?.delegate = self
            languageNativeLoader?.load(GADRequest())
        default:
            return
        }
        
    }
    
    /// 原生广告显示
    func showNativeAd(type: HTAdvertiseType, complete: @escaping(Bool, GADNativeAd?) -> Void) {
        
        // 是否可显示
        if canShowAd() == false {
            return
        }
        switch type {
        case .transNative:
            if transNativeCanShow == false {
                HTLog.log("[AD] 广告刷新间隔未到 type: \(type.rawValue)")
                complete(false, nil)
                return
            }
        case .languageNative:
            if languageNativeCanShow == false {
                HTLog.log("[AD] 广告刷新间隔未到 type: \(type.rawValue)")
                complete(false, nil)
                return
            }
        default:
            complete(false, nil)
            return
        }
        // 是否有缓存
        if self.getCacheByType(type: type)!.count > 0 {
            let ad = self.getCacheByType(type: type)!.first!.first?.value.advertise as? GADNativeAd
            ad?.delegate = self
            complete(true, ad)
            self.startNativeTimer(type: type)
            //            self.removeCachefirst(type: type)
        } else {
            self.loadNativeAd(type: type)
            complete(false, nil)
            HTLog.log("没有缓存")
        }
    }
}

// MARK: - GADNativeAdDelegate 原生广告显示代理
extension HTAdverUtil: GADNativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        self.addClickCount()
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        //        self.addShowCount()
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        //        self.addShowCount()
    }
}
// MARK: - GADAdLoaderDelegate GADNativeAdLoaderDelegate 原生广告加载代理
extension HTAdverUtil: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        if adLoader == transNativeLoader {
            HTLog.log("[AD] 广告加载成功 type: transNative 优先级: \(self.transNativeIndex + 1), unitID: \(self.transNativeItems[self.transNativeIndex].adId ?? "")")
            
            let item = self.transNativeItems.filter({ $0.adId == adLoader.adUnitID }).first!
            let cache = HTAdvertiseCache()
            cache.adId = item.adId
            cache.adSort = item.adSort
            cache.adType = .transNative
            cache.advertise = nativeAd
            /// 加入缓存
            self.addCacheByType(type: .transNative, model: cache)
            
            /// 通知ocr加载
            if self.transNativeSuccessComplete != nil {
                self.transNativeSuccessComplete!(nativeAd)
            }
        } else if adLoader == languageNativeLoader {
            HTLog.log("[AD]  广告加载成功 type: languageNative 优先级: \(self.languageNativeIndex + 1), unitID: \(self.languageNativeItems[self.languageNativeIndex].adId ?? "")")
            
            let item = self.languageNativeItems.filter({ $0.adId == adLoader.adUnitID }).first!
            let cache = HTAdvertiseCache()
            cache.adId = item.adId
            cache.adSort = item.adSort
            cache.adType = .languageNative
            cache.advertise = nativeAd
            
            /// 加入缓存
            self.addCacheByType(type: .languageNative, model: cache)
            
        }
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        if adLoader == transNativeLoader {
            HTLog.log("[AD] 广告加载失败 type: transNative \(error.localizedDescription) 优先级: \(self.transNativeIndex + 1), unitID: \(self.transNativeItems[self.transNativeIndex].adId ?? "")")
            self.loadNativeAd(type: .transNative, index: transNativeIndex + 1)
        } else if adLoader == languageNativeLoader {
            HTLog.log("[AD] 广告加载失败 type: languageNative \(error.localizedDescription) 优先级: \(self.languageNativeIndex + 1), unitID: \(self.languageNativeItems[self.languageNativeIndex].adId ?? "")")
            self.loadNativeAd(type: .languageNative, index: languageNativeIndex + 1)
        }
    }
}
// MARK: - GADFullScreenContentDelegate 插屏广告代理
extension HTAdverUtil: GADFullScreenContentDelegate {
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        //        print("Ad did fail to present full screen content.")
        if let type = self.type, type != .backRoot {
            self.removeCachefirst(type: type)
            self.loadInterstitialAd(type: type)
        }
        
    }
    
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        //        print("Ad did present full screen content.")
        self.addShowCount()
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        //        print("Ad did dismiss full screen content.")
        if let type = self.type, type != .backRoot {
            self.removeCachefirst(type: type)
            self.loadInterstitialAd(type: type)
            if type == .loading, let app = UIApplication.shared.delegate as? AppDelegate {
                app.getTrackAuth()
            }
        }
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        UserDefaults.standard.set(Int(Date().timeIntervalSince1970), forKey: RemoteString.overdue)
        self.addClickCount()
    }
}

// MARK: - 原生广告定时器相关
extension HTAdverUtil {
    func startNativeTimer(type: HTAdvertiseType) {
        stopNativeTimer(type: type)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) {
            self.changeNativeShowtype(type: type)
        }
    }
    
    func changeNativeShowtype(type: HTAdvertiseType) {
        switch type {
        case .transNative:
            transNativeCanShow = true
        case .languageNative:
            languageNativeCanShow = true
        default:
            break
        }
        
        //        removeCachefirst(type: type)
    }
    
    func stopNativeTimer(type: HTAdvertiseType) {
        switch type {
        case .transNative:
            transNativeCanShow = false
        case .languageNative:
            languageNativeCanShow = false
        default:
            break
        }
    }
}

// MARK: - 缓存相关
extension HTAdverUtil {
    /// 更新缓存 缓存时长3000s
    func refreshTotalAdCache() {
        let now = Date().timeIntervalSince1970
        loadingCache = loadingCache.filter({
            now - TimeInterval($0.first!.key) < 3000
        })
        transInterCache = transInterCache.filter({
            now - TimeInterval($0.first!.key) < 3000
        })
        transNativeCache = transNativeCache.filter({
            now - TimeInterval($0.first!.key) < 3000
        })
        photoInterCache = photoInterCache.filter({
            now - TimeInterval($0.first!.key) < 3000
        })
        languageNativeCache = languageNativeCache.filter({
            now - TimeInterval($0.first!.key) < 3000
        })
        backRootCache = backRootCache.filter({
            now - TimeInterval($0.first!.key) < 3000
        })
        vpnCache = vpnCache.filter({
            now - TimeInterval($0.first!.key) < 3000
        })
    }
    /// 获取缓存数组
    func getCacheByType(type: HTAdvertiseType) -> [[TimeInterval: HTAdvertiseCache]]? {
        switch type {
        case .loading:
            return loadingCache
        case .transInter:
            return transInterCache
        case .transNative:
            return transNativeCache
        case .photoInter:
            return photoInterCache
        case .languageNative:
            return languageNativeCache
        case .backRoot:
            return backRootCache
        case .vpn:
            return vpnCache
        }
    }
    /// 加入缓存
    func addCacheByType(type: HTAdvertiseType, model: HTAdvertiseCache) {
        switch type {
        case .loading:
            loadingCache.append([Date().timeIntervalSince1970: model])
            loadingCache.sort(by: {
                $0.first!.value.adSort > $1.first!.value.adSort
            })
        case .transInter:
            transInterCache.append([Date().timeIntervalSince1970: model])
            transInterCache.sort(by: {
                $0.first!.value.adSort > $1.first!.value.adSort
            })
        case .transNative:
            transNativeCache.append([Date().timeIntervalSince1970: model])
            transNativeCache.sort(by: {
                $0.first!.value.adSort > $1.first!.value.adSort
            })
        case .photoInter:
            photoInterCache.append([Date().timeIntervalSince1970: model])
            photoInterCache.sort(by: {
                $0.first!.value.adSort > $1.first!.value.adSort
            })
        case .languageNative:
            languageNativeCache.append([Date().timeIntervalSince1970: model])
            languageNativeCache.sort(by: {
                $0.first!.value.adSort > $1.first!.value.adSort
            })
        case .backRoot:
            backRootCache.append([Date().timeIntervalSince1970: model])
            backRootCache.sort(by: {
                $0.first!.value.adSort > $1.first!.value.adSort
            })
        case .vpn:
            vpnCache.append([Date().timeIntervalSince1970: model])
            vpnCache.sort(by: {
                $0.first!.value.adSort > $1.first!.value.adSort
            })
        }
    }
    /// 清除单个缓存
    func removeCachefirst(type: HTAdvertiseType) {
        switch type {
        case .loading:
            loadingCache.removeAll()
        case .transInter:
            transInterCache.removeAll()
        case .transNative:
            transNativeCache.removeAll()
        case .photoInter:
            photoInterCache.removeAll()
        case .languageNative:
            languageNativeCache.removeAll()
        case .backRoot:
            backRootCache.removeAll()
        case .vpn:
            vpnCache.removeAll()
        }
    }
    /// 清除全部缓存
    func removeAllCache() {
        loadingCache.removeAll()
        transInterCache.removeAll()
        transNativeCache.removeAll()
        photoInterCache.removeAll()
        languageNativeCache.removeAll()
        backRootCache.removeAll()
        vpnCache.removeAll()
        
        /// 加载状态及加载下标重置
        loadingAdIsLoding = false
        loadingIndex = 0
        
        transInterIsLoding = false
        transInterIndex = 0
        
        transNativeIndex = 0
        
        photoInterIsLoding = false
        photoInterIndex = 0
        
        backRootIsLoding = false
        backRootIndex = 0
        
        vpnIsLoding = false
        vpnIndex = 0
        
        languageNativeIndex = 0
    }
    
}
// MARK: - 展示及点击次数相关
extension HTAdverUtil {
    /// 是否可显示广告
    func canShowAd() -> Bool {
        guard HTRootUtil.admodel != nil else {
            HTLog.log("[AD] 无广告配置文件")
            return false
        }
        if adCounts!.showCount >= adInfo.totalShowCount {
            HTLog.log("[AD] total 展示次数上限")
        }
        if adCounts!.clickCount >= adInfo.totalClickCount {
            HTLog.log("[AD] total 点击次数上限")
        }
        
        return adCounts!.showCount < adInfo.totalShowCount && adCounts!.clickCount < adInfo.totalClickCount
    }
    /// 显示次数增加
    func addShowCount() {
        setupAdmobCounts()
        guard var counts = adCounts else { return }
        counts.showCount += 1
        adCounts = counts
        do {
            let data = try JSONEncoder().encode(counts)
            UserDefaults.standard.setValue(data, forKey: String(describing: HTAdvertiseCounts.self))
            HTLog.log("[AD] 广告展示 \(counts.showCount) 次")
        } catch let e {
            HTLog.log("[AD] 广告统计失败 \(e.localizedDescription)")
        }
    }
    /// 点击次数增加
    func addClickCount() {
        setupAdmobCounts()
        guard var counts = adCounts else { return }
        counts.clickCount += 1
        adCounts = counts
        do {
            let data = try JSONEncoder().encode(counts)
            UserDefaults.standard.setValue(data, forKey: String(describing: HTAdvertiseCounts.self))
            HTLog.log("[AD] 广告点击 \(counts.clickCount) 次")
        } catch let e {
            HTLog.log("[AD] 广告统计失败 \(e.localizedDescription)")
        }
    }
    /// 次数更新
    func setupAdmobCounts() {
        if adCounts != nil {
            if Date().timeIntervalSince1970 - adCounts!.time > 24 * 60 * 60 {
                UserDefaults.standard.removeObject(forKey: String(describing: HTAdvertiseCounts.self))
                adCounts = nil
                setupAdmobCounts()
            }
            return
        }
        if let countData = UserDefaults.standard.value(forKey: String(describing: HTAdvertiseCounts.self)) as? Data,
           let counts = try? JSONDecoder().decode(HTAdvertiseCounts.self, from: countData) {
            if Date().timeIntervalSince1970 - counts.time > 24 * 60 * 60 {
                UserDefaults.standard.removeObject(forKey: String(describing: HTAdvertiseCounts.self))
                setupAdmobCounts()
                return
            }
            adCounts = counts
        } else {
            let adCount = HTAdvertiseCounts()
            do {
                let data = try JSONEncoder().encode(adCount)
                UserDefaults.standard.setValue(data, forKey: String(describing: HTAdvertiseCounts.self))
                adCounts = adCount
            } catch let e {
                HTLog.log("[AD] 加载广告统计失败 \(e.localizedDescription)")
            }
        }
    }
}

struct HTAdvertiseCounts: Codable {
    var time = Date().timeIntervalSince1970
    var showCount: Int = 0
    var clickCount: Int = 0
}


