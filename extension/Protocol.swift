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
import web3swift

@objc public protocol ProtocolDelegate: NSObjectProtocol{
        func VPNShouldDone()
}

public class Protocol:NSObject{ 
        public static var pInst = Protocol()
        public var userAddress:String!
        public var userSubAddress:String!
        public var poolAddress:String!
        public var minerAddress:String!
        public var minerIP:String!
        public var minerPort:Int32!
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
                let poolAddrStr = param["POOL_ADDR"] as! String
                let minerID     = param["MINER_ADDR"] as! String
                let userAddr    = param["USER_ADDR"] as! String
                
                self.isDebug            = param["IS_TEST"] as? Bool ?? true
                self.priKey             = HopKey(main: main_pri, sub: sub_pri)
                self.userAddress        = userAddr
                self.poolAddress        = poolAddrStr
                self.minerAddress       = minerID
                self.userSubAddress     = (param["USER_SUB_ADDR"] as! String)
                self.minerIP            = (param["MINER_IP"] as! String)
                self.minerPort            = (param["MINER_PORT"] as! Int32)
                
                self.aesKey             = try self.priKey.genAesKey(forMiner:minerID, subPriKey: sub_pri)
                
                guard MembershipEX.Membership(user: userAddr, pool: poolAddrStr) else {
                        throw HopError.txWire("Init membership failed[\(userAddr)---->\(poolAddrStr)]")
                }
                
                self.txSocket = UDPClient(address: self.minerIP, port: self.minerPort)
                if MembershipEX.membership.inRecharge > HopConstants.RechargePieceSize{
                        NSLog("--------->Need to recharge because of last failure:\(MembershipEX.membership.inRecharge)")
                        self.recharge(amount: 0)
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
        private func recharge(amount:Int64){
                
                let curMem = MembershipEX.membership!
                self.TXQueue.async { do {
                        curMem.inRecharge += amount
                        
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
