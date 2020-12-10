//
//  MemberShip.swift
//  Pirate
//
//  Created by wesley on 2020/9/29.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib
import SwiftyJSON

class MembershipUI:NSObject{
        public static var Cache:[String:CDMemberShip] = [:]
        
        var coreData:CDMemberShip?
        
        public static func MemberArray() ->[CDMemberShip]{
                return Array(Cache.values)
        }
        
        override init() {
                super.init()
        }
        
        public static func loadCache(){
                
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                
                Cache.removeAll()
                
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND available == true", HopConstants.DefaultPaymenstService, addr)
                let order = [NSSortDescriptor.init(key: "epoch", ascending: false)]
                guard let memberArr = NSManagedObject.findEntity(HopConstants.DBNAME_MEMBERSHIP,
                                                             where: w,
                                                             orderBy: order,
                                                             context: dbContext) as? [CDMemberShip] else{
                        return
                }
                
                if memberArr.count == 0{
                        AppSetting.workQueue.async {
                                syncAllMyMemberships()
                        }
                        return
                }
        
                for cData in memberArr{
                        let poolAddr = cData.poolAddr!.lowercased()
                        Cache[poolAddr] = cData
                        
                        if cData.needReload{
                                guard let data = IosLibMemberShipData(addr, poolAddr) else {
                                        continue
                                }
                                let json = JSON(data)
                                cData.updateByMemberDetail(json: json, addr: addr)
                        }
                        
                        if AppSetting.coreData?.poolAddrInUsed?.lowercased() == cData.poolAddr!.lowercased(){
                                let balance = cData.packetBalance - Double(cData.credit)
                                AppSetting.coreData?.tmpBalance = balance
                                PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
                        }
                }
        }
        
        
        public static func syncAllMyMemberships(){
                
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                let poolAddr = Array(Pool.CachedPool.keys)[0]
                guard let data = IosLibAvailablePools(addr, poolAddr) else{return}
                let poolJson = JSON(data)
                
                var idx = 0
                Cache.removeAll()
                let dbContext = DataShareManager.privateQueueContext()
                
                while (idx < poolJson.count){
                        let poolAddr = poolJson[idx].string!.lowercased()
                        idx += 1
                        
                        guard let data = IosLibMemberShipData(addr, poolAddr) else {
                                continue
                        }
                        let json = JSON(data)
                        
                        let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                            HopConstants.DefaultPaymenstService,
                                            addr,
                                            poolAddr)
                        
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MEMBERSHIP)
                        request.predicate = w
                        guard let result = try? dbContext.fetch(request).last as? CDMemberShip else{
                                let cData = CDMemberShip.newMembership(json: json, pool:poolAddr, user:addr)
                                Cache[poolAddr] = cData
                                continue
                        }
                        
                        result.updateByMemberDetail(json: json, addr: addr)
                        Cache[poolAddr] = result
                        if AppSetting.coreData?.poolAddrInUsed?.lowercased() == poolAddr{
                                let balance = result.packetBalance - Double(result.credit)
                                AppSetting.coreData?.tmpBalance = balance
                                PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
                        }
                }
                
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
                PostNoti(HopConstants.NOTI_MEMBERSHIP_SYNCED)
        }
}

extension CDMemberShip{
        
        public static func newMembership(json:JSON, pool:String, user:String) -> CDMemberShip {
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMemberShip(context: dbContext)
                data.poolAddr = pool
                data.userAddr = user
                data.mps = HopConstants.DefaultPaymenstService
                data.tokenBalance = json["token_balance"].double ?? 0
                data.packetBalance = json["traffic_balance"].double ?? 0
                data.expire = json["Expire"].string ?? ""
                data.epoch = json["Epoch"].int64 ?? 0
                data.microNonce = json["ClaimedMicNonce"].int64 ?? 0
                data.credit = 0
                data.curTXHash = nil
                data.inRecharge = 0
                data.available = true
                return data
        }
        
        func updateByMemberDetail(json:JSON, addr:String){
                
                self.available = true
                guard let nonce = json["Nonce"].int64 else{
                        return
                }
                if self.nonce >= nonce{
                        NSLog("======>[updateByETH]:nothing to update for pool[\(self.poolAddr ?? "")]")
                        return
                }
                
                let epoch = json["Epoch"].int64 ?? 0
                if self.epoch > epoch{
                        NSLog("======>[updateByETH]: [self opech =\(self.epoch)]invalid epoch[\(epoch)] info for pool[\(self.poolAddr ?? "")]")
                        return
                }
                
                guard let tokenBalance = json["TokenBalance"].double,
                      let packetBalance = json["RemindPacket"].double,
                      let expire = json["Expire"].string else{
                        NSLog("======>[updateByETH]: invalid josn[\(json)]")
                        return
                }
                
                if self.epoch == epoch{
                        self.nonce = nonce
                        self.tokenBalance = tokenBalance
                        self.packetBalance = packetBalance
                        self.expire = expire
                        
                        NSLog("======>[updateByETH]: update sucess nonce=[\(nonce)] epoch=[\(epoch)]")
                        return
                }
                
                guard let microNonce = json["ClaimedMicNonce"].int64,
                      let claimedAmount = json["ClaimedAmount"].int64 else{
                        NSLog("======>[updateByETH]: invalid josn[\(json)]")
                        return
                }
                
                if self.microNonce < microNonce{
                        NSLog("======>[updateByETH]: invalid microNonce=[\(microNonce)]")
                        return
                }
                
                self.nonce = nonce
                self.tokenBalance = tokenBalance
                self.packetBalance = packetBalance
                self.expire = expire
                self.microNonce = microNonce
                self.epoch = epoch
                
                let reminder = self.credit + self.inRecharge - claimedAmount
                if reminder < 0{
                        self.credit = 0
                        self.inRecharge = 0
                        NSLog("======>[updateByETH]:Something wrong [credit=\(self.credit)] [claimedAmount=\(claimedAmount)]")
                } else {
                        self.credit = reminder
                        self.inRecharge = 0
                        self.curTXHash = nil
                }
        }
}
