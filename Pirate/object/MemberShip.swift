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

class MemberShip:NSObject{
        public static var Cache:[String:MemberShip] = [:]
        
        var coreData:CDMemberShip?
        var poolAddr:String!
        var Nonce:Int64 = 0
        var TokenBalance:Double = 0
        var RemindPacket:Double = 0
        var Expire:Int64 = 0
        var Epoch:Int64 = 0
        var ClaimedAmount:Double = 0
        var ClaimedMicNonce:Int64 = 0
        
        
        public static func MemberArray() ->[MemberShip]{
                return Array(Cache.values)
        }
        
        override init() {
                super.init()
        }
        
        init(coredata:CDMemberShip){
                super.init()
                coreData = coredata
                poolAddr = coredata.poolAddr
        }
        
        init(json:JSON){
                
                self.Nonce = json["Nonce"].int64 ?? 0
                self.TokenBalance = json["TokenBalance"].double ?? 0
                self.RemindPacket = json["RemindPacket"].double ?? 0
                self.Expire = json["Expire"].int64 ?? 0
                self.Epoch = json["Epoch"].int64 ?? 0
                self.ClaimedAmount = json["ClaimedAmount"].double ?? 0
                self.ClaimedMicNonce = json["ClaimedMicNonce"].int64 ?? 0
        }
        
        public static func reLoad(){
                
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                
                Cache.removeAll()
                
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND userAddr == %@", HopConstants.DefaultPaymenstService, addr)
                let order = [NSSortDescriptor.init(key: "epoch", ascending: false)]
                guard let memberArr = NSManagedObject.findEntity(HopConstants.DBNAME_MEMBERSHIP,
                                                             where: w,
                                                             orderBy: order,
                                                             context: dbContext) as? [CDMemberShip] else{
                        return
                }
        
                for cData in memberArr{
                        let obj = MemberShip(coredata:cData)
                        Cache[obj.poolAddr] = obj
                }
        }
        
        public func syncMemberDetailFromETH(){
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                
                guard let data = IosLibUserDataOnBlockChain(coreData?.userAddr, self.poolAddr) else{
                        return
                }
                
                let json = JSON(data)
                let obj = MemberShip(json: json)
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                    HopConstants.DefaultPaymenstService,
                                    addr,
                                    obj.poolAddr)
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MEMBERSHIP)
                request.predicate = w
                guard let result = try? dbContext.fetch(request).last as? CDMemberShip else{
                        let cData = CDMemberShip(context: dbContext)
                        cData.populate(obj: obj, addr: addr)
                        obj.coreData = cData
                        MemberShip.Cache[obj.poolAddr] = obj
                        return
                }
                result.updateByObj(obj: obj, addr: addr)
                
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
        }
        
        //TODO:: test this carefully
        public static func syncAllMyMemberships(){
                
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                
                guard let data = IosLibMemberShipData(addr) else {
                        return
                }
                
                let json = JSON(data)
                Cache.removeAll()
                let dbContext = DataShareManager.privateQueueContext()
                
                for (poolAddr, subJson):(String, JSON) in json {
                        
                        let obj = MemberShip(json:subJson)
                        obj.poolAddr = poolAddr
                        let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                            HopConstants.DefaultPaymenstService,
                                            addr,
                                            obj.poolAddr)
                        
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MEMBERSHIP)
                        request.predicate = w
                        guard let result = try? dbContext.fetch(request).last as? CDMemberShip else{
                                
                                let cData = CDMemberShip(context: dbContext)
                                cData.populate(obj: obj, addr: addr)
                                obj.coreData = cData
                                
                                Cache[obj.poolAddr] = obj
                                continue
                        }
                        
                        result.updateByObj(obj: obj, addr: addr)
                        obj.coreData = result
                        Cache[obj.poolAddr] = obj
                }
                
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
        }
}

extension CDMemberShip{
        func populate(obj:MemberShip, addr:String)  {
                self.poolAddr = obj.poolAddr
                self.userAddr = addr
                self.mps = HopConstants.DefaultPaymenstService
        }
        
        func updateByObj(obj:MemberShip, addr:String){
                
        }
}
