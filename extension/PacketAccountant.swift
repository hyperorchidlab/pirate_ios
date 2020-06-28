//
//  UserAccount.swift
//  extension
//
//  Created by hyperorchid on 2020/3/7.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import CoreData

public protocol ThreadMonitor: NSObjectProtocol{
        func RcpWireExit()
}

public class PacketAccountant: NSObject{
        
        public static let Inst = PacketAccountant()
        var paymentAddr:String?
        var userAddr:String?
        let dbContext = DataShareManager.privateQueueContext()
        var locker = NSLock()
        private var dataCache:[String: CDUserAccount] = [:]
        
        private override init() {
                super.init()
        }
        public func setEnv(MPSA:String, user:String) {
                
                self.paymentAddr = MPSA
                self.userAddr = user
                dbContext.performAndWait {
                        let w = NSPredicate(format: "contractAddress == %@ AND userAddr == %@ ", MPSA, user)
                        guard let array = NSManagedObject.findEntity(HopConstants.DBNAME_UserAccount,
                                                   where: w,
                                                   context: dbContext) as? [CDUserAccount] else{return}
                        for data in array{
                                dataCache[data.poolAddr!] = data
                        }
                }
                NSLog("---------> PacketAccountant start:\n \(dbContext)")
        }
        
        func newUserAccount(userData ud:UserData, forPool:String) -> CDUserAccount{
                
                let new_obj = CDUserAccount(context: dbContext)
                new_obj.resetToUserData(ethData: ud)
                new_obj.contractAddress = self.paymentAddr!
                new_obj.userAddr = self.userAddr!
                new_obj.poolAddr = forPool
                new_obj.credit = 0
                new_obj.inRecharge = 0
                new_obj.curTXHash = nil
                dbContext.insert(new_obj)
                DataShareManager.saveContext(dbContext)
                self.dataCache[forPool] = new_obj
                NSLog("---------> New user accountant data:\n \(new_obj.toString())")
                return new_obj
        }
        
        public func reloadUA(forPool p:String) -> CDUserAccount?{
                
                var ret:CDUserAccount?
                dbContext.performAndWait {
                        let w = NSPredicate(format: "contractAddress == %@ AND userAddr == %@ AND poolAddr == %@",
                                            self.paymentAddr!,
                                            self.userAddr!,
                                            p)
                        guard let obj = NSManagedObject.findOneEntity(HopConstants.DBNAME_UserAccount,
                                                   where: w,
                                                   context: dbContext) as? CDUserAccount else{return}
                        ret = obj
                }
                return ret
        }
        
        public func updateByEthData(userData ud:UserData, forPool pool:EthereumAddress){
                NSLog("---------> Got user data from ethereum :=>")
                NSLog(ud.toString())
                locker.lock()
                defer {
                        locker.unlock()
                }
                dbContext.performAndWait {
                        let pool_str = pool.address
                        guard let core_ud = reloadUA(forPool: pool_str) else{
                                let _ = newUserAccount(userData: ud, forPool: pool_str)
                                return
                        }
                        
                        let ud_nonce = ud.Nonce.IntV32()
                        if core_ud.nonce == ud_nonce{
                                NSLog("--------->No need to update :=>(updateByEthData)")
                                return
                        }

                        NSLog("--------->Before update :=>\n \(core_ud.toString())")
                        defer{
                                DataShareManager.saveContext(dbContext)
                                self.dataCache[pool_str] = core_ud
                                NSLog("---------> After update :=>\n \(core_ud.toString())")
                        }
                        
                        let ud_epoch = ud.Epoch.IntV32()
                        if core_ud.epoch == ud_epoch{
                                core_ud.nonce = ud.Nonce.IntV32()
                                core_ud.tokenBalance = ud.TokenBalance.DoubleV()
                                core_ud.packetBalance = ud.RemindPacket.DoubleV()
                                core_ud.expire = ud.Expire.IntV32()
                                return
                        }
                        
                        if core_ud.nonce > ud_nonce || core_ud.epoch > ud_epoch {
                                core_ud.resetToUserData(ethData: ud)
                                core_ud.credit = 0
                                return
                        }
                        
                        
                        if core_ud.microNonce >= ud.ClaimedMicNonce.IntV64() {
                                core_ud.resetToUserData(ethData: ud)
                                let reminder = core_ud.credit + core_ud.inRecharge - ud.ClaimedAmount.IntV64()
                                if reminder < 0{
                                        core_ud.credit = 0
                                        core_ud.inRecharge = 0
                                        NSLog("--------->Something wrong with this situation:=>\n \(core_ud.toString()) \n \(ud.toString())")
                                } else {
                                        core_ud.credit = reminder
                                        core_ud.inRecharge = 0
                                        core_ud.curTXHash = nil
                                }
                        } else {
                                core_ud.resetToUserData(ethData: ud)
                                core_ud.credit = 0
                                core_ud.inRecharge = 0
                        }
                }
        }
        
        public func updateByReceipt(rcpData:ReceiptData) throws{
                
                locker.lock()
                defer {
                        locker.unlock()
                }
                NSLog("--------->Update user account by receipt data :=>\n\(rcpData.toString())")
                
                guard let tx = rcpData.tx else{
                        throw HopError.rcpWire("Empty transaction data in receipt object")
                }
                
                guard tx.verifyTx() == true else{
                        throw HopError.rcpWire("Signature verify failed for receipt")
                }
                
                guard tx.author?.verify(HopConstants.DefaultTokenAddr, HopConstants.DefaultPaymenstService) == true else{
                        throw HopError.rcpWire("Token or Payment address is not same with current setting")
                }
                
                guard let cua = PacketAccountant.Inst.reloadUA(forPool: rcpData.tx!.to!) else{
                        NSLog("--------->no loacal user account data")
                        throw HopError.rcpWire("can't find local user account when update by receipt")
                }
                
                guard cua.userAddr != nil, cua.userAddr == tx.from else{
                        throw HopError.rcpWire("This receipt is not for me")
                }
                
                NSLog("--------->********>User account before update\n\(cua.toString())")
                defer {
                        NSLog("--------->++++++++>User account after update\n\(cua.toString())")
                }
                
                if cua.epoch != tx.epoch{
                        NSLog("---------> epochs are not same")
                        return
                }
                
                if cua.microNonce + 1 > tx.nonce!{
                        NSLog("--------->Receipt's nonce[\(tx.nonce!)] is too low[\(cua.microNonce)]")
                        return
                }
                
                let next_credit = tx.credit! + tx.amount!
                let cur_credit = cua.credit + cua.inRecharge
                if cur_credit > next_credit{
                        NSLog("--------->Lower packet receipt cur=[\(cur_credit)] next=[\(next_credit)]")
                        return
                }
                
                cua.credit = next_credit
                cua.microNonce = tx.nonce!
                cua.curTXHash = nil
                cua.inRecharge = 0
                cua.syncData()
        }
        
        public func allAccountants() -> [CDUserAccount]{
                return Array(dataCache.values)
        }
        
        public func accountant(ofPool pAddr:String) -> CDUserAccount?{
                guard let core_ud = reloadUA(forPool: pAddr) else{
                        return nil
                }
                
                dataCache[pAddr] = core_ud
                return core_ud
        }
}

extension CDUserAccount{
        
        func resetToUserData(ethData ud:UserData){
                self.nonce = ud.Nonce.IntV32()
                self.epoch = ud.Epoch.IntV32()
                self.tokenBalance = ud.TokenBalance.DoubleV()
                self.packetBalance = ud.RemindPacket.DoubleV()
                self.expire = ud.Expire.IntV32()
                self.microNonce = ud.ClaimedMicNonce.IntV64()
        }
        
        func toString() -> String{
                
                return "\nUserAccount =>{\nUserAddr=\(self.userAddr!)\n PoolAddr=\(self.poolAddr!)\n Nonce=\(self.nonce)\n Epoch=\(self.epoch) \n TokenBalance=\(self.tokenBalance)\n RemindPacket=\(self.packetBalance)\n Expire=\(self.expire)\n Credit=\(self.credit) \n MicroNonce=\(self.microNonce)\n InRecharge=\(self.inRecharge)\n CurTXHash=\(self.curTXHash ?? "---")\n } "
        }
        
        func syncData() {
                //TODO::NOTIFY
                DataShareManager.saveContext(PacketAccountant.Inst.dbContext)
                DataShareManager.syncAllContext(PacketAccountant.Inst.dbContext)
        }
}
