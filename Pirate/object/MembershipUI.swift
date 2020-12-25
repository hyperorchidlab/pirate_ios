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
                        
                        NSLog("=======>Membership addr=\(addr) pool=\(cData.poolAddr ?? "<->")")
                        
                        if cData.needReload{
                                guard let data = IosLibMemberShipData(addr, poolAddr) else {
                                        continue
                                }
                                let json = JSON(data)
                                cData.updateByMemberDetail(json: json, addr: addr)
                        }
                        
                        if AppSetting.coreData?.poolAddrInUsed?.lowercased() == cData.poolAddr!.lowercased(){
                                let balance = cData.packetBalance
                                AppSetting.coreData?.tmpBalance = balance
                                PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
                        }
                }
        }
        
        
        public static func syncAllMyMemberships(){
                
                guard let addr = Wallet.WInst.Address, Pool.CachedPool.count > 0 else{
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
                        
                        NSLog("=======>Membership addr=\(addr) poolAddr=\(poolAddr)")
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
                                let balance = result.packetBalance
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
                data.tokenBalance = json["left_token_balance"].double ?? 0
                data.packetBalance = json["left_traffic_balance"].double ?? 0
                data.usedTraffic = json["used_traffic"].int64 ?? 0
                data.available = true
                return data
        }
        
        //TODO::Make sure how to change local receipt
        func updateByMemberDetail(json:JSON, addr:String){
                self.available = true
                
                self.tokenBalance = json["left_token_balance"].double ?? 0
                self.packetBalance = json["left_traffic_balance"].double ?? 0
                let credit = json["used_traffic"].int64 ?? 0
                self.usedTraffic = credit
        }
}

//TODO::
extension CDMinerCredit{
                
        public static func newEntity(user:String, mid:String) -> CDMinerCredit{
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMinerCredit(context: dbContext)
                data.credit = 0
                data.inCharge = 0
                data.minerID = mid
                data.mps = HopConstants.DefaultPaymenstService
                data.userAddr = user
                return data
        }
        
        public func update(json:JSON){
                let credit = json["miner_credit"].int64 ?? 0
                if self.credit >= credit{
                        return
                }
                
                self.credit = credit
                PostNoti(HopConstants.NOTI_MINER_CREDIT_CHANGED)
        }
}
