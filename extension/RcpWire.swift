//
//  RcpWire.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/4.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import SwiftSocket
import SwiftyJSON

public class RcpWire:NSObject{
        
        var udpSocket:UDPClient
        public static let RCPQueue = DispatchQueue(label: "RCPSyn", qos: .background)
        public static let RCPKAQueue = DispatchQueue(label: "RCPKA", qos: .background)
        var userAddr:String
        var poolAddr:String
        var timer:Timer?
        var poolIPAddr:String
        var priKey:Data
        public init(poolAddr:String,
                    userAddr ua:String,
                    priKey:Data,
                    ip:String) {
                self.poolAddr = poolAddr
                self.userAddr = ua
                self.priKey = priKey
                self.poolIPAddr = ip
                
                udpSocket = UDPClient(address: self.poolIPAddr, port: Int32(HopConstants.ReceiptSyncPort))
                
                super.init()
                let data = HopMessage.rcpKAMsg(from: self.userAddr)
                DispatchQueue.main.async {
                        self.timer = Timer.scheduledTimer(withTimeInterval:
                                        HopConstants.RCPKeepAlive, repeats: true) {//
                                (time) in
                                
                                RcpWire.RCPKAQueue.async {
                                        NSLog("--------->rcp wire[\(ua)->\(poolAddr)] keep alive start[\(self.udpSocket.fd ?? 0)]")
                                        let ret = self.udpSocket.send(data: data)
                                        if ret.isFailure{
                                                NSLog("--------->rcp wire[\(ua)->\(poolAddr)] keep alive err[\(ret.error ?? "<->" as! Error)]")
                                                self.udpSocket = UDPClient(address: self.poolIPAddr, port: Int32(HopConstants.ReceiptSyncPort))
                                                let try_hand = self.handshake()
                                                NSLog("--------->rcp wire[\(ua)->\(poolAddr)] try again hand shake[\(try_hand)]")
                                        }
                                }
                }}
        }
        
        public func handshake() -> Bool{
                guard let data = HopMessage.rcpSynMsg(from: self.userAddr,
                                                    pool: self.poolAddr,
                                                    sigKey: self.priKey) else {
                        NSLog("--------->rcp wire[\(userAddr)->\(poolAddr)] hand shake data error:")
                        return false
                }
                
                let ret = self.udpSocket.send(data: data)
                return ret.isSuccess
        }
        
        public func start(monitor:ThreadMonitor){
                
                RcpWire.RCPQueue.async {
                        while true{
                                
                                NSLog("--------->Ready to read receipt from pool[\(self.poolAddr)] by fd:\(self.udpSocket.fd ?? -1)")
                                do{
                                        let (data, pool_ip, _) = self.udpSocket.recv(HopConstants.UDPBufferSize)
                                        guard let d = data else{
                                                NSLog("--------->Read receipt data failed")
                                                return
                                        }
                                        MembershipEX.updateByReceipt(data:Data(d))
                                        
//                                        NSLog("--------->Got receipt info from pool[\(pool_ip)]:=>\n\(String(bytes: d, encoding: .utf8) ?? "---")")
//
//                                        guard let obj = try JSONSerialization.jsonObject(with: Data(d), options: []) as? [String:Any] else{
//                                                throw HopError.rcpWire("Parse receipt data to json object failed")
//                                        }
//                                        guard let rcp_obj = ReceiptData(json: obj) else{
//                                                NSLog("--------->Parese json object to swift object faileds")
//                                                throw HopError.rcpWire("Parese json object to swift object faileds")
//                                        }
//
//                                        try PacketAccountant.Inst.updateByReceipt(rcpData:rcp_obj)
                        
                                } catch let err{
                                        self.udpSocket.close()
                                        self.timer?.invalidate()
                                        monitor.RcpWireExit()//TODO::process this situation
                                        NSLog("--------->rcp receive wire[\(self.poolAddr)] err:\(err.localizedDescription)")
                                }
                        }
                }
        }
}
