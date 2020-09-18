//
//  PacketTunnelProvider.swift
//  extension
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import NetworkExtension
import NEKit
import web3swift

extension Data {
    var hexString: String {
        return self.reduce("", { $0 + String(format: "%02x", $1) })
    }
}

class PacketTunnelProvider: NEPacketTunnelProvider {
        let httpQueue = DispatchQueue.global(qos: .userInteractive)
        var proxyServer: ProxyServer!
        let proxyServerPort :UInt16 = 41080
        let proxyServerAddress = "127.0.0.1";
        var hopInstance:Protocol?
        var enablePacketProcessing = false
        var interface: TUNInterface!
        
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
                NSLog("--------->Tunnel start ......")
                
                if proxyServer != nil {
                        proxyServer.stop()
                        proxyServer = nil
                }
                
                guard let ops = options else {
                        completionHandler(NSError.init(domain: "PTP", code: -1, userInfo: nil))
                        NSLog("--------->Options is empty ......")
                        return
                }
                do {
                        hopInstance = try Protocol.init(param: ops, delegate: self)

                        let settings = try initSetting(rules: ops["ROUTE_RULES"] as! [String : NSObject],
                                           minerID: ops["MINER_ADDR"] as! String)
                        
                        HOPRule.ISGlobalMode = (ops["GLOBAL_MODE"] as? Bool == true)
                
                        self.setTunnelNetworkSettings(settings, completionHandler: {
                                error in
                                guard error == nil else{
                                        completionHandler(error)
                                        NSLog("--------->setTunnelNetworkSettings err:\(error!.localizedDescription)")
                                        return
                                }
                                
                                
                                self.proxyServer = GCDHTTPProxyServer.init(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
                                
                                do {try self.proxyServer.start()}catch let err{
                                        completionHandler(err)
                                        NSLog("--------->Proxy start err:\(err.localizedDescription)")
                                        return
                                }
                                
                                NSLog("--------->Proxy server started......")
                                completionHandler(nil)
                                
                                if (self.enablePacketProcessing){
                                         self.interface = TUNInterface(packetFlow: self.packetFlow)
                                        
                                        let fakeIPPool = try! IPPool(range: IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!))
                                        
                                        
                                        let dnsServer = DNSServer(address: IPAddress(fromString: "198.18.0.1")!, port: NEKit.Port(port: 53), fakeIPPool: fakeIPPool)
                                        let resolver = UDPDNSResolver(address: IPAddress(fromString: "8.8.8.8")!, port: NEKit.Port(port: 53))
                                        dnsServer.registerResolver(resolver)
                                        self.interface.register(stack: dnsServer)
                                        
                                        DNSServer.currentServer = dnsServer
                                        
                                        let udpStack = UDPDirectStack()
                                        self.interface.register(stack: udpStack)
                                        
                                        let tcpStack = TCPStack.stack
                                        tcpStack.proxyServer = self.proxyServer
                                        self.interface.register(stack:tcpStack)
                                        self.interface.start()
                                }
                        })
                        
                }catch let err{
                       completionHandler(err)
                       NSLog("--------->ethereum fetcher init failed\(err.localizedDescription)\n")
               }
        }
        
        func initSetting(rules: [String : NSObject], minerID:String)throws -> NEPacketTunnelNetworkSettings {
                
                let networkSettings = NEPacketTunnelNetworkSettings.init(tunnelRemoteAddress: proxyServerAddress)
                let ipv4Settings = NEIPv4Settings.init(addresses: ["10.0.0.8"], subnetMasks: ["255.255.255.0"])
                
                if enablePacketProcessing {
                    ipv4Settings.includedRoutes = [NEIPv4Route.default()]
                    ipv4Settings.excludedRoutes = [
                        NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                        NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                        NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                        NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                        NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: HopConstants.DefaultBasIP, subnetMask: "255.255.255.255"),
                    ]
                }
                
                networkSettings.ipv4Settings = ipv4Settings;
                networkSettings.mtu = NSNumber.init(value: 1500)

                let proxySettings = NEProxySettings.init()
                proxySettings.httpEnabled = true;
                proxySettings.httpServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
                proxySettings.httpsEnabled = true;
                proxySettings.httpsServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
                proxySettings.excludeSimpleHostnames = false;
                proxySettings.matchDomains = [""]
                
                if enablePacketProcessing {
                        let DNSSettings = NEDNSSettings(servers: ["198.18.0.1"])
                        DNSSettings.matchDomains = [""]
                        DNSSettings.matchDomainsNoSearch = false
                        networkSettings.dnsSettings = DNSSettings
                }
                

                networkSettings.proxySettings = proxySettings;
                RawSocketFactory.TunnelProvider = self
                
                guard let hopAdapterFactory = HOPAdapterFactory(miner:minerID,
                                                                delegate: hopInstance!) else{
                        throw HopError.minerErr("--------->Initial miner data failed")
                }
                
                let hopRule = HOPRule(adapterFactory: hopAdapterFactory, urls: rules)
                
                var ipStrings:[String] = []
                ipStrings.append(contentsOf: HopConstants.TelegramIPRange)
//                ipStrings.append(contentsOf: HopConstants.NetflixIPRange)
                let ipRange = try IPRangeListRule(adapterFactory: hopAdapterFactory, ranges: ipStrings)
                
                RuleManager.currentManager = RuleManager(fromRules: [hopRule, ipRange], appendDirect: true)
                return networkSettings
        }

        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                NSLog("--------->Tunnel stopping......")
                completionHandler()
                self.exit()
        }

        override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
                NSLog("--------->Handle App Message......")
                guard let param = NSKeyedUnarchiver.unarchiveObject(with: messageData) as? [String:Any],
                        let handler = completionHandler else{
                        return
                }
                
                let is_global = param["Global"] as? Bool
                let gt_status = param["GetModel"] as? Bool
                if is_global != nil{
                        HOPRule.ISGlobalMode = is_global!
                        NSLog("--------->Global model changed...\(HOPRule.ISGlobalMode)...")
                        handler("Success".data(using: .utf8))
                }
                if gt_status != nil{
                        NSLog("--------->App is querying golbal model [\(HOPRule.ISGlobalMode)]")
                        let data = NSKeyedArchiver.archivedData(withRootObject: ["Global":HOPRule.ISGlobalMode])
                        handler(data)
                }
        }

        override func sleep(completionHandler: @escaping () -> Void) {
                NSLog("-------->sleep......")
                completionHandler()
        }

        override func wake() {
                NSLog("-------->wake......")
        }
}


extension PacketTunnelProvider: ProtocolDelegate{
        
        private func exit(){
                if enablePacketProcessing {
                    interface.stop()
                    interface = nil
                    DNSServer.currentServer = nil

                }
                RawSocketFactory.TunnelProvider = nil
                proxyServer.stop()
                proxyServer = nil
                Darwin.exit(EXIT_SUCCESS)
        }
        
        func VPNShouldDone() {
                self.exit()
        }
}
