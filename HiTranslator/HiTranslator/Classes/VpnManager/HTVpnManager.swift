//
//  FPVpnManager.swift
//  FastIOS
//
//  Created by Gamma-iOS on 2022/1/19.
//

import Foundation
import NetworkExtension
import Reachability

let connectTimeOut = 15.0               //VPN最长链接时长
var isVPNSetting = false                //vpn设置，不加载loading
var isEnterBackground = false           //至后台中断vpn链接

//Vpn状态
enum HTVpnState {
    case waitConnect
    case connecting
    case connected
    case disConnecting
    case disConnected
    case reConnecting
    case error
    case noNetwork
}

class HTVpnManager: NSObject {

    static let shared = HTVpnManager()
    
    var providerManager: NETunnelProviderManager?
    var alreadyHasObserver = false
    var vpnStatusChangedHandle: ((_ vpnStatus: HTVpnState) -> Void)?
    var vpnSpeedTextChangedHandle: ((_ bytesIn: Int, _ bytesOut: Int) -> Void)?
    
    var timeoutTimer: DispatchSourceTimer?
    var reconnectTimer: DispatchSourceTimer?

//    var timer: DispatchSourceTimer?
//    var lastBytesIn: Int = 0
//    var lastBytesOut: Int = 0
        
    var serverList: [HTServerModel]?
    var isHaveVPNConfig = false
    
    let sempha: DispatchSemaphore = DispatchSemaphore.init(value: 1)
    let squeue: DispatchQueue = DispatchQueue(label: "com.ht.group",attributes: .concurrent)
    
    func loadConfigFromPreferences(vpnStateCallBack: ((_ vpnStatus: NEVPNStatus) -> Void)?) {
        NETunnelProviderManager.loadAllFromPreferences { manager, error in
            guard error == nil else {
                HTLog.log("\(error?.localizedDescription ?? "")")
                self.isHaveVPNConfig = false
                return
            }
            if let first = manager?.first {
                vpnStateCallBack?(first.connection.status)
                self.providerManager = first
                self.isHaveVPNConfig = true
            } else {
                self.isHaveVPNConfig = false
                self.providerManager = NETunnelProviderManager()
            }
            self.addNotification()
        }
    }
    
    private func addNotification() {
        if alreadyHasObserver { return }
        alreadyHasObserver = true
        NotificationCenter.default.addObserver(self, selector: #selector(VPNStatusChangedNotification(noti:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    private func removeNotification() {
        if alreadyHasObserver {
            NotificationCenter.default.removeObserver(self)
            alreadyHasObserver = false
        }
    }
    
    @objc private func VPNStatusChangedNotification(noti: Notification) {
        if let session = noti.object as? NETunnelProviderSession {
            if session != providerManager?.connection { return }
        }
        guard providerManager != nil  else {
            return
        }
        if providerManager!.connection.status == .connecting {
            VPNStatusChanged(status: providerManager!.connection.status, connectTimeOut)
        }
        else{
            VPNStatusChanged(status: providerManager!.connection.status)
        }
    }
    
    func VPNStatusChanged(status: NEVPNStatus, _ connectTime:TimeInterval = connectTimeOut) {
        switch status {
            case .invalid:
                HTLog.log("[VPN] VPN invalid")
                vpnStatusChangedHandle?(.error)
                removeConnectTimeoutTimer()
            case .disconnected:
                HTLog.log("[VPN] VPN disconnected")
                vpnStatusChangedHandle?(.disConnected)
//                removeSpeedTimer()
                removeConnectTimeoutTimer()
            case .connecting:
                HTLog.log("[VPN] VPN connecting")
                vpnStatusChangedHandle?(.connecting)
                addConnectTimeoutTimer(connectTime)
            case .connected:
                HTLog.log("[VPN] VPN connected")
//                addSpeedTimer()
                removeConnectTimeoutTimer()
                vpnStatusChangedHandle?(.connected)
            case .disconnecting:
                HTLog.log("[VPN] VPN disconnecting")
                vpnStatusChangedHandle?(.disConnecting)
                removeConnectTimeoutTimer()
            case .reasserting:
                HTLog.log("[VPN] VPN reconnecting")
                vpnStatusChangedHandle!(.reConnecting)
            default:
                HTLog.log("[VPN] VPN status unkonwn")
        }
    }
    
    func setupProvider(completion: (() -> Void)?) {
        providerManager?.loadFromPreferences(completionHandler: { error in
            guard error == nil else {
                HTLog.log("[VPN] ERROR \(error?.localizedDescription ?? "")")
                self.isHaveVPNConfig = false
                return
            }
            if self.isHaveVPNConfig == false{
                HTLog.vpn_vpermis()
            }
            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.serverAddress = "HiTranslator"
            tunnelProtocol.providerBundleIdentifier = "com.cgfloattest.HiTranslator.HiTranslatorProxy"
            let rule = NEOnDemandRuleConnect()
            rule.interfaceTypeMatch = .any
            self.providerManager?.isEnabled = true
            self.providerManager?.protocolConfiguration = tunnelProtocol
            self.providerManager?.onDemandRules = [rule]
            isVPNSetting = true
            self.providerManager?.saveToPreferences { error in
                guard error == nil else {
                    self.isHaveVPNConfig = false
                    HTLog.log("[VPN] SavePreferences error: \(error?.localizedDescription ?? "")")
                    isVPNSetting = false
                    self.vpnStatusChangedHandle?(.waitConnect)
                    return
                }
                self.isHaveVPNConfig = true
                if !UserDefaults.standard.bool(forKey: keyVpnPermis1){
                    HTLog.vpn_vpermis1()
                }
                UserDefaults.standard.set(true, forKey: keyVpnPermis1)
                
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    isVPNSetting = false
                    completion?()
                }
            }
        })
    }
    
    func VPNConnect(server:HTServerModel, _ isfast:Bool = true) {
        let reachability = try! Reachability()
        if reachability.connection == .unavailable {
            HTLog.log("[VPN] Network is not reachable")
            vpnStatusChangedHandle?(.noNetwork)
            return
        }
//        FireBaseLog.log(event: .fast_c, ["fast": isfast ? "fast" : server.countryIcon])
        self.addNotification()
        self.providerManager?.loadFromPreferences { error in
            guard error == nil else {
                HTLog.log("[VPN] load error: \(error?.localizedDescription ?? "")")
                return
            }
            do {
                try self.providerManager?.connection.startVPNTunnel(options: ["host":NSString(string:   server.host),"port":"2344","method":"chacha20-ietf-poly1305","password":"Dvb>A!M15FHR"])
                HTLog.log("[VPN] host : \(server.host)")
            } catch let e {
                HTLog.log("[VPN] connect error: \(e.localizedDescription)")
            }
        }
        isVPNSetting = false
    }
    
    func VPNDisConnect() {
        self.providerManager?.connection.stopVPNTunnel()
    }

    // 链接超时
    func addConnectTimeoutTimer(_ timeout:TimeInterval = connectTimeOut) {
        timeoutTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        timeoutTimer?.setEventHandler(handler: {
            DispatchQueue.main.async {
                self.removeNotification()
                self.VPNDisConnect()
                HTLog.log("[VPN] timeout invalid")
                self.VPNStatusChanged(status: .invalid)
            }
        })
        timeoutTimer?.schedule(deadline: .now() + timeout)
        timeoutTimer?.resume()
    }
    
    
    func removeConnectTimeoutTimer() {
        timeoutTimer?.cancel()
        timeoutTimer = nil
    }
    
//    func addSpeedTimer() {
//        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
//        timer?.setEventHandler(handler: {
//            self.getVPNSpeedBytes()
//        })
//        timer?.schedule(deadline: .now(), repeating: 1)
//        timer?.resume()
//    }
//
//    func removeSpeedTimer() {
//        timer?.cancel()
//        timer = nil
//        self.vpnSpeedTextChangedHandle?(0, 0)
//    }
//
//    func getVPNSpeedBytes() {
//        if let sessin = providerManager?.connection as? NETunnelProviderSession {
//            do {
//                let message = "SuperMasterVPN_statistics_key"
//                try sessin.sendProviderMessage(message.data(using: .utf8)!, responseHandler: { data in
//                    if let data = data {
//                        do {
//                            let dic = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as! [String : String]
//                            let bytesIn = Int(dic["bytesIn"] ?? "0") ?? 0
//                            let bytesOut = Int(dic["bytesOut"] ?? "0") ?? 0
//
//                            let deltaBytesIn = bytesIn - self.lastBytesIn
//                            let deltaBytesOut = bytesOut - self.lastBytesOut
//                            self.vpnSpeedTextChangedHandle?(deltaBytesIn, deltaBytesOut)
//                            self.lastBytesIn = bytesIn
//                            self.lastBytesOut = bytesOut
//                        } catch {
//                            fatalError("archivedData failed with error: \(error)")
//                        }
//                    }
//                })
//            } catch {
//                HTLog.log("[VPN] getVPNSpeedBytes error")
//            }
//        }
//    }
}

extension HTVpnManager {
    func pingServer(list: [HTServerModel], completion: (([HTServerModel]) -> Void)?) {
        var pingResult = [Int : [Double]]()
        for (index, _) in list.enumerated() {
            pingResult[index] = [Double]()
        }
        var pingUtilDict = [Int : SMPing?]()

        let group = DispatchGroup()
        let queue = DispatchQueue.main
        for (index, server) in list.enumerated() {
            group.enter()
            SMPing.shared().queueCount += 1
            queue.async {
                pingUtilDict[index] = SMPing.start(withHost: server.host, count: 4, pingCallback: { pingItem in
                    switch pingItem.status {
                        case start:
                            break
                        case failToSendPacket:
                            group.leave()
                            SMPing.shared().queueCount -= 1
                            break
                        case receivePacket:
                        pingResult[index]?.append(pingItem.singleTime)
                            group.leave()
                            SMPing.shared().queueCount -= 1
                        case receiveUnpectedPacket:
                            break
                        case timeout:
                            pingResult[index]?.append(9999)
                            group.leave()
                            SMPing.shared().queueCount -= 1
                        case error:
                            pingResult[index]?.append(9999)
                            group.leave()
                            SMPing.shared().queueCount -= 1
                        case finished:
                            pingUtilDict[index] = nil
                            group.leave()
                            SMPing.shared().queueCount -= 1
                    default: break
                    }
                })
            }
        }
        group.notify(queue: queue) { [self] in
            var pingAvgResult = [Int : Double]()

            for ping in pingResult {
                var sum = 0.0
                for pingTime in ping.value {
                    sum += pingTime
                }
                if ping.value.count > 0 {
                    let avg = sum / Double(ping.value.count)
                    pingAvgResult[ping.key] = avg
                }
            }
            if pingAvgResult.count == 0 {
                HTLog.log("[VPN] Error ping avg resut count == 0")
                completion?([HTServerModel(countryName: "United States - New York", countryIcon: "icon_america", host: "5.188.0.7")])
                return
            }
            let needPingServers = list
            for pingAvg in pingAvgResult {
                needPingServers[pingAvg.key].delay = pingAvg.value
            }
            let sortedVPNServers = needPingServers.sorted(by: { return $0.delay < $1.delay })
            self.serverList = sortedVPNServers
            HTLog.log("[IP] Ping result:")
            for (index, sortedServer) in sortedVPNServers.enumerated() {
                HTLog.log("[IP] \(index):\(sortedServer.countryName) - \(sortedServer.host) - \(String(format: "%.2f", sortedServer.delay))ms")
            }
            completion?(sortedVPNServers)
        }
    }
}
