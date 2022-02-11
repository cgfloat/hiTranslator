//
//  PacketTunnelProvider.swift
//  HiTranslatorProxy
//
//  Created by sunhuaiwu on 2022/2/8.
//

import NetworkExtension
import Shadowsocks_iOS
import PacketProcessor_iOS
import Reachability

enum GammaConnectError : Error {
    case NEVPNRrrorConfigerationDisabled
    case SSLocalStartError
    case tun2SockesStartError
}
class PacketTunnelProvider: NEPacketTunnelProvider {
    var shadowsocks: Shadowsocks? = nil
    var reachability = try? Reachability()
    var startCompletionHandler: ((Error?) -> Void)? = nil
    
    var connectedAt: TimeInterval = 0
    var connected: Bool = false {
        didSet {
            if connected {
                connectedAt = Date().timeIntervalSince1970
            }
        }
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        self.startCompletionHandler = completionHandler
        try? reachability?.startNotifier()
        if let optionDic = options {
            self.shadowsocks = Shadowsocks((optionDic as [AnyHashable : Any]))
            self.startConnectToShadowsocks()
        }else{
            completionHandler(GammaConnectError.NEVPNRrrorConfigerationDisabled)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        shadowsocks?.stop(nil)
        TunnelInterface.stop()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            completionHandler()
            exit(0)
        }
    }
}

extension PacketTunnelProvider {
    
    func startConnectToShadowsocks() {
         shadowsocks?.start(withConnectivityChecks: false, completion: { (errorCode) in
             if errorCode == .noError {
                 self.startTunnelInterface()
             } else {
                 self.shadowsocks?.stop(nil)
                self.startCompletionHandler?(GammaConnectError.SSLocalStartError)
             }
         })
    }
    
    func startTunnelInterface() {
        setTunnelSettings { (setttingError) in
            if let _ = TunnelInterface.setup(with: self.packetFlow) {
                self.shadowsocks?.stop(nil)
                self.startCompletionHandler?(GammaConnectError.tun2SockesStartError)
                return
            } else {
                self.connected = true
            }
            
            TunnelInterface.setIsUdpForwardingEnabled(true)
            TunnelInterface.startTun2Socks(kShadowsocksLocalPort)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                TunnelInterface.processPackets()
                self.startCompletionHandler?(nil)
            }
        }
    }
    
    func setTunnelSettings(completion: ((Error?) -> Void)?) {
        
        let excludes = [NEIPv4Route]()
        let ipv6Excludes = [NEIPv6Route]()
        
        let ipv4 = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [.default()]
        ipv4.excludedRoutes = excludes
        
        let ipv6 = NEIPv6Settings(addresses: ["fd66:f83a:c650::1"], networkPrefixLengths: [120])
        ipv6.includedRoutes = [.default()]
        ipv6.excludedRoutes = ipv6Excludes
        
        let dns = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1"])
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.168.20.1")
        settings.ipv4Settings = ipv4
        settings.ipv6Settings = ipv6
        settings.dnsSettings = dns
        
        setTunnelNetworkSettings(settings) { error in
            completion?(error)
        }
    }
}
