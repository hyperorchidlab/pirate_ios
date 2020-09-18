//
//  Protocol.swift
//  extension
//
//  Created by hyperorchid on 2020/3/3.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import Curve25519

@objc public protocol ProtocolDelegate: NSObjectProtocol{
        func VPNShouldDone()
}

@objc public protocol MicroPayDelegate: NSObjectProtocol{
        func getSetupMsg(salt:Data) -> Data?
        func AesKey()->[UInt8]
        func CounterWork(size:Int)
}

public class Protocol:NSObject{ 
       
        public static var EthSyncTime = TimeInterval(30)
        var priKey:HopPriKey
        var aesKey:Data
        var mainAddr:EthereumAddress
        var subAddr:String
        var transactionWire:TxWire?
        
        public init(param:[String : NSObject], delegate:ProtocolDelegate)throws{
                
                let mpc         = (param["MPC_ADDR"] as! String)
                let main_pri    = param["MAIN_PRI"] as! Data
                let sub_pri     = param["SUB_PRI"] as! Data
                priKey          = HopPriKey(main: main_pri, sub: sub_pri)
                
                let poolAddrStr = (param["POOL_ADDR"] as! String)
                let poolAddr    = EthereumAddress(poolAddrStr)!
                let minerID     = param["MINER_ADDR"] as! String
                let userAddr    = (param["USER_ADDR"] as! String)
                mainAddr        = EthereumAddress(userAddr)!
                subAddr         = param["USER_SUB_ADDR"] as! String
                
                if param["IS_TEST"] as? Bool == false{
                        Protocol.EthSyncTime = TimeInterval(300)
                }
                
                self.aesKey = try priKey.genAesKey(forMiner:minerID, subPriKey: sub_pri)
                guard let pool_ip = BasUtil.Query(addr: poolAddrStr) else{
                        throw HopError.hopProtocol("Can't not find pool[\(poolAddrStr) ip address]")
                }
                PacketAccountant.Inst.setEnv(MPSA: mpc, user: userAddr)
                
                super.init()
                
                try EthUtil.sharedInstance.initEth()
                
                let micChain = MicroChain(paymentAddr: mpc,
                                          pool: poolAddr,
                                          userAddr: userAddr)
                micChain.start()
                
                let receiptWire = RcpWire(poolAddr: poolAddrStr,
                                      userAddr: userAddr,
                                      priKey: main_pri,
                                      ip: pool_ip)
                
                guard receiptWire.handshake() == true else{
                        throw HopError.rcpWire("Can't create receipt wire!å")
                }
                receiptWire.start(monitor:self)
                 
                guard let tx_wire = TxWire(poolAddr:poolAddrStr,
                                         minerID:minerID,
                                         signKey: main_pri,
                                         ip: pool_ip) else{
                        throw HopError.txWire("Init tx wire failed")
                }
                transactionWire = tx_wire
        }
        
        private func openPaymenWire(){
                
        }
}


extension Protocol: MicroPayDelegate{
        
        public func CounterWork(size: Int) {
                transactionWire?.increase(size)
        }
        
        public func getSetupMsg(salt:Data) -> Data?{ do{
                return try HopMessage.SetupMsg(iv:salt,
                                               mainAddr: self.mainAddr,
                                               subAddr: self.subAddr,
                                               sigKey: self.priKey.mainPriKey!)
        }catch let err{
                NSLog("--------->Setup msg to miner failed:=>\(err.localizedDescription)")
                return nil
        } }
        
        public func  AesKey()->[UInt8]{
                return self.aesKey.bytes
        }
}


extension Protocol:ThreadMonitor{
        
        public func RcpWireExit(){
                
        }
}
