//
//  Miner.swift
//  Pirate
//
//  Created by hyperorchid on 2020/10/5.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib
import SwiftyJSON

class Miner : NSObject {
        var coreData:CDMiner?
        
        public static var CachedMiner:[String: CDMiner] = [:]
        
        public static func ArrayData() ->[CDMiner]{
                return Array(CachedMiner.values)
        }
        
        public static func LoadCache(){
                CachedMiner.removeAll()
                guard let pool = AppSetting.coreData?.poolAddrInUsed else{
                        return
                }
                
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND poolAddr == %@", HopConstants.DefaultPaymenstService, pool)
                guard let minerArr = NSManagedObject.findEntity(HopConstants.DBNAME_MINER,
                                                             where: w,
                                                             context: dbContext) as? [CDMiner] else{
                        return
                }
                
                if minerArr.count == 0{
                        SyncMinerUnder(pool: pool)
                        return
                }
        
                for cData in minerArr{
                        CachedMiner[cData.subAddr!.lowercased()] = cData
                }
                
                PostNoti(HopConstants.NOTI_MINER_CACHE_LOADED)
        }
        
        public static func SyncMinerUnder(pool:String){
                guard let data = IosLibMinerList(pool) else{
                        return
                }
                
                let json = JSON(data)
                CachedMiner.removeAll()
                guard let pool = AppSetting.coreData?.poolAddrInUsed else{
                        return
                }
                
                let dbContext = DataShareManager.privateQueueContext()
                
                for (_, subJson):(String, JSON) in json {
                        guard let subAddr = subJson["sub_addr"].string else{
                                continue
                        }
                        let w = NSPredicate(format: "mps == %@ AND subAddr == %@ AND poolAddr == %@",
                                            HopConstants.DefaultPaymenstService,
                                            subAddr,
                                            pool)
                        
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MINER)
                        request.predicate = w
                        guard let result = try? dbContext.fetch(request).last as? CDMiner else{
                                let cData = CDMiner.newMiner(json: subJson)
                                cData.poolAddr = pool
                                cData.subAddr = subAddr
                                CachedMiner[subAddr.lowercased()] = cData
                                continue
                        }
                        
                        result.zon = json["zone"].string!
                        result.ipAddr = json["ip_addr"].string!
                        CachedMiner[subAddr.lowercased()] = result
                }
                
                DataShareManager.saveContext(dbContext)
                PostNoti(HopConstants.NOTI_MINER_CACHE_LOADED)
                PostNoti(HopConstants.NOTI_MINER_SYNCED)
        }
        
        public static func minerInof(mid:String) throws ->(String, Int32) {
                
                if let m_data = Miner.CachedMiner[mid.lowercased()]{
                        return (m_data.ipAddr!, IosLibMinerPort(mid))
                }
                
                guard let data = IosLibMinerAddr(mid) else {
                        throw HopError.minerErr("Invalid miner infos".locStr)
                }
                
                let jsonData = JSON(data)
                guard let mip = jsonData["IP"].string,
                      let port = jsonData["Port"].int32 else{
                        throw HopError.minerErr("Invalid miner infos".locStr)
                }
                
                return (mip, port)
        }
}

extension CDMiner{
        public static func newMiner(json:JSON) -> CDMiner {
                
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMiner(context: dbContext)
                data.mps = HopConstants.DefaultPaymenstService
                data.zon = json["zone"].string!
                data.ping = -1
                data.ipAddr = json["ip_addr"].string!
                
                return data
        }
}
