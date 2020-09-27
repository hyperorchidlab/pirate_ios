//
//  PoolEntity.swift
//  Pirate
//
//  Created by wesley on 2020/9/27.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib
import SwiftyJSON

class Pool : NSObject {
        
        var Name:String?
        var Address:String!
        var Url:String?
        var Email:String?
        var coreData:CDPool?
        
        public static var CachedPool:[String: Pool] = [:]
        
        override init() {
                super.init()
        }
        
        public static func reloadCachedPool()  {
                
                
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@", HopConstants.DefaultPaymenstService)
                let order = [NSSortDescriptor.init(key: "address", ascending: false)]
                
                guard let poolArr = NSManagedObject.findEntity(HopConstants.DBNAME_POOL,
                                                             where: w,
                                                             orderBy: order,
                                                             context: dbContext) as? [CDPool] else{
                        fetchPool()
                        return
                }
                
                CachedPool.removeAll()
                for cData in poolArr{
                        let obj = Pool(coredata:cData)
                        CachedPool[obj.Address] = obj
                }
        }
        
        public init(coredata:CDPool){
                
                self.Address = coredata.address
                self.Name = coredata.name
                self.Url = coredata.url
                self.Email = coredata.email
                self.coreData = coredata
        }
        
        public init(json:JSON){
                
                self.Address = json["MainAddr"].string
                self.Name = json["Name"].string
                self.Email = json["Email"].string
                self.Url = json["Url"].string
        }
        
        public static func fetchPool(){
                
                guard let data = IosLibPoolInMarket() else {
                        return
                }
                
                let json = JSON(data)
                CachedPool.removeAll()
                let dbContext = DataShareManager.privateQueueContext()
                
                let w = NSPredicate(format: "mps == %@", HopConstants.DefaultPaymenstService)
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_POOL)
                request.predicate = w
                if let result = try? dbContext.fetch(request){
                        for oldData in result{
                                dbContext.delete(oldData as! NSManagedObject)
                        }
                }
                
                for (_, subJson):(String, JSON) in json {
                        
                        let obj = Pool(json: subJson)
                        let cData = CDPool(context: dbContext)
                        cData.populate(obj)
                        obj.coreData = cData
                        
                        CachedPool[obj.Address] = obj
                }
                
                DataShareManager.saveContext(dbContext)
        }
}

extension CDPool{
        
        func populate(_ obj: Pool){
                self.address = obj.Address
                self.name = obj.Name
                self.email = obj.Email
                self.url = obj.Url
                self.mps = HopConstants.DefaultPaymenstService
        }
}
