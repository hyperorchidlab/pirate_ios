//
//  PoolData.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/26.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt
import CoreData
import web3swift

public class PoolDetails:NSObject{
        
        public var ID:BigUInt = 0
        public var MainAddr = EthereumAddress(EthereumAddress.ZeroAddress)!
        public var PayerAddr = EthereumAddress(EthereumAddress.ZeroAddress)!
        public var GTN:BigUInt = 0
        public var ShortName:String?
        public var Email:String?
        public var Url:String?
        
        public override init() {
                super.init()
        }
        
        public init(_ dict:[String:Any]) {
                self.ID = dict["ID"] as! BigUInt
                self.MainAddr = dict["mainAddr"] as! EthereumAddress
                self.PayerAddr = dict["payerAddr"] as! EthereumAddress
                self.GTN = dict["GTN"] as! BigUInt
                
                if let d = dict["shortName"] as? Data{
                     self.ShortName = String.init(data: d, encoding: .utf8)
                }
                
                if let d = dict["email"] as? Data{
                     self.Email = String.init(data: d, encoding: .utf8)
                }
                
                if let d = dict["url"] as? Data{
                     self.Url = String.init(data: d, encoding: .utf8)
                }
        }
        
        public convenience init(coreData data:CDPoolData) {
                self.init()
                
                if let id = data.id {
                        self.ID = BigUInt.init(id)
                }
                
                if let gtn = data.gtn {
                        self.GTN = BigUInt.init(gtn)
                }
                if let addr = data.mainAddr{
                        self.MainAddr = EthereumAddress(addr)!
                }
                if let addr = data.payerAddr{
                        self.PayerAddr = EthereumAddress(addr)!
                }
                self.ShortName = data.shortName
                self.Email = data.email
                self.Url = data.url
        }
        
        public static func savePoolData(_ data:[String:PoolDetails],
                                        for mps:String,
                                        context :NSManagedObjectContext) throws{
                var err:Error? = nil
                context.performAndWait{ () -> Void in
                do {
                       let fetchRequest = CDPoolData.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
                       fetchRequest.predicate = NSPredicate(format: "contractAddress == %@", mps)
                       let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                       try context.execute(deleteRequest)
                       
                       for (_, pData) in data{
                               
                                let pool = CDPoolData(context: context)
                                pool.contractAddress = mps
                                pool.id = pData.ID.serialize()
                                pool.mainAddr = pData.MainAddr.address
                                pool.payerAddr = pData.PayerAddr.address
                                pool.gtn = pData.GTN.serialize()
                                pool.email = pData.Email
                                pool.shortName = pData.ShortName
                                pool.url = pData.Url
                                context.insert(pool)
                       }
                       
                       DataShareManager.saveContext(context)
                }catch let e{
                        err = e
                }
                }
                
                if err != nil{
                        throw err!
                }
        }
        
        public static func Load(for mps:String, context :NSManagedObjectContext) -> [String:PoolDetails]{
                 
                let w = NSPredicate(format: "contractAddress == %@", mps)
                var result: [String:PoolDetails] = [:]
                
                context.performAndWait {
                        
                        guard let arr = NSManagedObject.findEntity(HopConstants.DBNAME_POOL_DETAILS,
                                                                   where: w,
                                                                   context: context) as? [CDPoolData] else{
                                               return
                        }
                                       
                        for pData in arr{
                                let obj = PoolDetails.init(coreData:pData)
                                let pool_addr = pData.mainAddr!
                                result[pool_addr] = (obj)
                        }
                }
               
                return result
        }
        
        public func toString()->String{
                return "\n PoolDetails=>{\nID=\(ID) \n MainAddr=\(MainAddr) \n GTN=\(GTN) \n ShortName=\(ShortName ?? "---") \n Email=\(Email ?? "---") \n Url=\(Url ?? "---") \n}"
        }
}
