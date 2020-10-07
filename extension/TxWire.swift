//
//  TxWire.swift
//  extension
//
//  Created by hyperorchid on 2020/3/5.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import SwiftSocket

public class TxWire:NSObject{
        
        var udpSocket:UDPClient?
        let lock = NSLock()
        var counter:Int = (HopConstants.RechargePieceSize / 2)
        let queue = DispatchQueue.init(label: "Transaction Wire Queue", qos: .default)
        var minerID:String
        var signKey:Data
        var curUserAcc:CDUserAccount
        var poolAddr:String
        
        public init?(poolAddr:String,
                     minerID:String,
                     signKey:Data,
                     ip:String){
                self.minerID = minerID
                self.signKey = signKey
                self.poolAddr = poolAddr
                self.udpSocket = UDPClient(address: ip, port: Int32(HopConstants.TxReceivePort))
                guard let cua = PacketAccountant.Inst.reloadUA(forPool: poolAddr) else{
                        NSLog("--------->can't find loacal user account data[pool:\(poolAddr)]")
                        return nil
                }
                self.curUserAcc = cua
                super.init()
                
                if cua.inRecharge > HopConstants.RechargePieceSize{
                        NSLog("--------->Need to recharge because of last failure:\(cua.inRecharge)")
                        self.recharge(amount: 0)
                }
        }
        
        private func recharge(amount:Int64) {
                self.queue.async { do {
                        guard let cua = PacketAccountant.Inst.reloadUA(forPool: self.poolAddr) else{
                                NSLog("--------->can't find loacal user account data[pool:\(self.poolAddr)]")
                                throw HopError.txWire("can't find loacal user account data[pool:\(self.poolAddr)]")
                        }
                        self.curUserAcc = cua
                        self.curUserAcc.inRecharge  += amount
                        
                        NSLog("--------->Transaction Wire need to recharge:[\(self.curUserAcc.inRecharge)]===>")
                        guard let tx_data = TransactionData(userData: cua, amount: Int64(self.curUserAcc.inRecharge), for:  self.minerID) else{
                                NSLog("--------->recharge transaction creation failed")
                                throw HopError.txWire("recharge transaction creation failed")
                        }
                        
                        guard let d = tx_data.createTxData(sigKey: self.signKey) else{
                                NSLog("--------->Create transaction data failed")
                                throw HopError.txWire("Create transaction data failed")
                        }
                        
                        let ret = self.udpSocket?.send(data: d)
                        guard ret?.isSuccess == true else{
                                //TODO::Notification
                                throw HopError.txWire("Transaction Wire send failed==\(ret?.error?.localizedDescription ?? "<-empty error->")==>")
                        }
                        cua.curTXHash = tx_data.hashV
                        cua.syncData()
                        }catch let err{
                                NSLog("--------->\(err.localizedDescription)")
                        }
                }                
        }
        
        public func increase(_ size:Int){
                
                if lock.try(){
                        defer {lock.unlock()}
                        self.counter += size
                        if self.counter < HopConstants.RechargePieceSize{
                                return
                        }
                        self.recharge(amount: Int64(self.counter))
                        self.counter = 0
                }
        }
}
