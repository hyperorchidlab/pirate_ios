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
                        AppSetting.workQueue.async {
                                SyncMinerFromETH()
                        }
                        return
                }
        
                for cData in minerArr{
                        CachedMiner[cData.subAddr!.lowercased()] = cData
                }
                
                PostNoti(HopConstants.NOTI_MINER_CACHE_LOADED)
                AppSetting.workQueue.async {
                        guard let data = IosLibMinerList(pool) else{
                                return
                        }
                        
                        let json = JSON(data)
                        var needSync = false
                        for (subAddr, _):(String, JSON) in json{
                                guard let _ = CachedMiner[subAddr.lowercased()] else {
                                        needSync = true
                                        break
                                }
                        }
                        if needSync{
                                SyncMinerFromETH()
                        }
                }
        }
        
        public static func SyncMinerFromETH(){
                CachedMiner.removeAll()
                guard let pool = AppSetting.coreData?.poolAddrInUsed else{
                        return
                }
                
                guard let data = IosLibMinerWithDetails(pool) else {
                        return
                }
                
                let json = JSON(data)
                let dbContext = DataShareManager.privateQueueContext()
                
                for (subAddr, subJson):(String, JSON) in json {
                        let w = NSPredicate(format: "mps == %@ AND subAddr == %@ AND poolAddr == %@",
                                            HopConstants.DefaultPaymenstService,
                                            subAddr,
                                            pool)
                        
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MINER)
                        request.predicate = w
                        guard let result = try? dbContext.fetch(request).last as? CDMiner else{
                                let cData = CDMiner.newMiner(json: subJson)
                                CachedMiner[subAddr.lowercased()] = cData
                                continue
                        }
                        
                        result.updateByETH(json: subJson)
                        CachedMiner[subAddr.lowercased()] = result
                }
                
                DataShareManager.saveContext(dbContext)
                PostNoti(HopConstants.NOTI_MINER_CACHE_LOADED)
                PostNoti(HopConstants.NOTI_MINER_SYNCED)
        }
}

extension CDMiner{
        public static func newMiner(json:JSON) -> CDMiner {
                
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMiner(context: dbContext)
                
                data.poolAddr = json["PoolAddr"].string!
                data.subAddr = json["SubAddr"].string!
                data.mps = HopConstants.DefaultPaymenstService
                data.zon = json["Zone"].string!
                data.ping = -1
                data.ipAddr = "0.0.0.0"
                
                return data
        }
        
        public func updateByETH(json:JSON){
                self.poolAddr = json["PoolAddr"].string!
                self.zon = json["Zone"].string!
        }
}
