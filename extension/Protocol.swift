//
//  Protocol.swift
//  extension
//
//  Created by hyperorchid on 2020/3/3.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import Curve25519
import CoreData
import SwiftSocket

@objc public protocol ProtocolDelegate: NSObjectProtocol{
        func VPNShouldDone()
}

public class Protocol:NSObject{ 
        public static var pInst = Protocol()
        public var userAddress:String!
        public var userSubAddress:String!
        public var poolAddress:String!
        public var minerAddress:String!
        public var poolIP:String!
        private var priKey:HopKey!
        private var aesKey:Data!
        var vpnDelegate:ProtocolDelegate!
        var isDebug:Bool = true
        
        
        var rcpSocket:UDPClient!
        var rcpTimer:Timer?
        var rcpKAData:Data!
        public static let RCPKAQueue = DispatchQueue(label: "Receipt KA Queue", qos: .default)
        public static let RCPQueue = DispatchQueue(label: "Receipt Wire Queue", qos: .default)
        
        var txSocket:UDPClient?
        let txLock = NSLock()
        var counter:Int = (HopConstants.RechargePieceSize / 2)
        let TXQueue = DispatchQueue.init(label: "Transaction Wire Queue", qos: .default)
        
        
        public override init() {
                super.init()
        }
        
        public func setup(param:[String : NSObject], delegate:ProtocolDelegate) throws{
                
                let main_pri    = param["MAIN_PRI"] as! Data
                let sub_pri     = param["SUB_PRI"] as! Data
                let poolAddrStr = (param["POOL_ADDR"] as! String)
                let minerID     = param["MINER_ADDR"] as! String
                let userAddr    = (param["USER_ADDR"] as! String)
                
                self.isDebug = param["IS_TEST"] as? Bool ?? true
                self.priKey = HopKey(main: main_pri, sub: sub_pri)
                self.userAddress = userAddr
                self.poolAddress = poolAddrStr
                self.minerAddress = minerID
                self.userSubAddress = (param["USER_SUB_ADDR"] as! String)
                self.aesKey = try self.priKey.genAesKey(forMiner:minerID, subPriKey: sub_pri)
                
                guard let pool_ip = BasUtil.Query(addr: poolAddrStr) else{
                        throw HopError.hopProtocol("Can't not find pool[\(poolAddrStr) ip address]")
                }
                self.poolIP = pool_ip
                guard MembershipEX.Membership(user: userAddr, pool: poolAddrStr) else {
                        throw HopError.txWire("Init membership failed")
                }
                
                guard initRcp() else{
                        throw HopError.txWire("Init receipt wire failed")
                }
                
                initTX()
                
                self.rcpStart()
        }
}
//MARK: - Receipt functions
extension Protocol{
        
        func initRcp() -> Bool{
                self.rcpSocket = UDPClient(address: self.poolIP, port: Int32(HopConstants.ReceiptSyncPort))
                self.rcpKAData = HopMessage.rcpKAMsg(from: userAddress!)
                DispatchQueue.main.async {
                        self.rcpTimer = Timer.scheduledTimer(timeInterval: HopConstants.RCPKeepAlive,
                                                     target: self,
                                                     selector: #selector(self.rcpTimerAction),
                                                     userInfo: nil,
                                                     repeats: true)
                }
                guard let data = HopMessage.rcpSynMsg(from: self.userAddress!,
                                                    pool: self.poolAddress!,
                                                    sigKey: self.priKey.mainPriKey!) else {
                        NSLog("--------->rcp wire[\(self.userAddress!)->\(self.poolAddress!)]hand shake data error:")
                        return false
                }
                
                let ret = self.rcpSocket.send(data: data)
                return ret.isSuccess
        }

        @objc func rcpTimerAction(){
                Protocol.RCPKAQueue.async {
                        NSLog("--------->rcp wire[\(self.userAddress!)->\(self.poolAddress!)] keep alive start[\(self.rcpSocket.fd ?? 0)]")
                        let ret = self.rcpSocket.send(data: self.rcpKAData)
                        if ret.isFailure{
                                let try_hand = self.initRcp()
                                NSLog("--------->rcp wire[\(self.userAddress!)->\(self.poolAddress!)] try again hand shake[\(try_hand)]")
                        }
                }
        }
        public func rcpStart(){
                Protocol.RCPQueue.async {
                        while true{
                                
                                NSLog("--------->Ready to read receipt from pool[\(self.poolAddress!)] by fd:\(self.rcpSocket.fd ?? -1)")
                                do{
                                        let (data, pool_ip, _) = self.rcpSocket.recv(HopConstants.UDPBufferSize)
                                        guard let d = data else{
                                                NSLog("--------->Read receipt data failed")
                                                return
                                        }
                                        NSLog("--------->Got receipt info from pool[\(pool_ip)]:=>\n\(String(bytes: d, encoding: .utf8) ?? "---")")
                                        
                                        try MembershipEX.membership.updateByReceipt(data:Data(d))
                        
                                } catch let err{
                                        self.rcpSocket.close()
                                        self.rcpTimer?.invalidate()
                                        //TODO::process this situation error and exit
                                        NSLog("--------->rcp receive wire[\(self.poolAddress!)] err:\(err.localizedDescription)")
                                }
                        }
                }
        }
}
//MARK: - TX functions
extension Protocol{
        
        public func AesKey()->[UInt8]{
                return self.aesKey.bytes
        }
        public func signKey()->Data{
                return self.priKey.mainPriKey!
        }
        
        func initTX(){
                self.txSocket = UDPClient(address: self.poolIP, port: Int32(HopConstants.TxReceivePort))
                if MembershipEX.membership.inRecharge > HopConstants.RechargePieceSize{
                        NSLog("--------->Need to recharge because of last failure:\(MembershipEX.membership.inRecharge)")
                        self.recharge(amount: 0)
                }
        }
        
        private func recharge(amount:Int64){
                
                let curMem = MembershipEX.membership!
                self.TXQueue.async { do {
                        curMem.inRecharge  += amount
                        
                        NSLog("--------->Transaction Wire need to recharge:[\(curMem.inRecharge)]===>")
                        let tx_data = TransactionData(userData: curMem,
                                                            amount: Int64(curMem.inRecharge),
                                                            for:  self.minerAddress)
                        
                        guard let d = tx_data.createTxData(sigKey: self.priKey.mainPriKey!) else{
                                NSLog("--------->Create transaction data failed")
                                throw HopError.txWire("Create transaction data failed")
                        }
                        
                        let ret = self.txSocket?.send(data: d)
                        guard ret?.isSuccess == true else{
                                //TODO::Notification
                                throw HopError.txWire("Transaction Wire send failed==\(ret?.error?.localizedDescription ?? "<-empty error->")==>")
                        }
                        curMem.curTXHash = tx_data.hashV
                        curMem.syncData()
                        }catch let err{
                                NSLog("--------->\(err.localizedDescription)")
                        }
                }
        }
        
        public func CounterWork(size:Int){
                
                if txLock.try(){
                        defer {txLock.unlock()}
                        self.counter += size
                        if self.counter < HopConstants.RechargePieceSize{
                                return
                        }
                        self.recharge(amount: Int64(self.counter))
                        self.counter = 0
                }
        }
}
