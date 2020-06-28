//
//  MPSVersion.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/26.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt
import CoreData

public class MPSVersion:NSObject{
        
        public var vPool:BigUInt = 0
        public var vMiner:BigUInt = 0
        public var vUser:BigUInt = 0
        public var vSetting:BigUInt = 0
        
        public override init(){
                super.init()
        }
        
        public convenience init(_ vm:CDVersionManager){
                self.init()
                
                if let v_p = vm.poolVersion {
                        self.vPool = BigUInt.init(v_p)
                }
                if let v_m = vm.minerVersion {
                        self.vMiner = BigUInt.init(v_m)
                }
                if let v_u = vm.userVersion {
                        self.vUser = BigUInt.init(v_u)
                }
                if let v_s = vm.settingVersion {
                        self.vSetting = BigUInt.init(v_s)
                }
        }
        
        public convenience init(_ ethData:[String:Any]){
                self.init()
                
                guard let p_v = ethData["versionOfPoolData"] as? BigUInt,
                        let m_v = ethData["versionOfMinerData"] as? BigUInt,
                        let u_v = ethData["versionOfUserData"] as? BigUInt,
                        let s_v = ethData["versionOfSysSetting"] as? BigUInt else{
                                return
                }
                
                vPool = p_v
                vMiner = m_v
                vUser = u_v
                vSetting = s_v
        }
        
        public func toString()->String{
                return "\nMPSVersion=>{\n Pool:[\(String(describing: vPool))] Miner:[\(String(describing: vMiner))] User:[\(String(describing: vUser))] Setting:[\(String(describing: vSetting))]\n}"
        }
        
        public static func Load(for mps:String, context :NSManagedObjectContext) -> MPSVersion{
                
                var version:MPSVersion? = nil
                
                context.performAndWait{ () -> Void in
                        
                        let w = NSPredicate(format:"contractAddress == %@", mps)
                        guard let ver = NSManagedObject.findOneEntity(HopConstants.DBNAME_VERSION,
                                                                      where: w,
                                context: context) as? CDVersionManager else{
                                        version = MPSVersion()
                                        return
                        }
                        
                        version = MPSVersion.init(ver)
                }
                
                return version!
        }
        
        public func update(mps:String, context :NSManagedObjectContext){
                
                context.performAndWait{ () -> Void in
                        
                        let w = NSPredicate(format:"contractAddress == %@", mps)
                        
                        var ver = NSManagedObject.findOneEntity(HopConstants.DBNAME_VERSION,
                                                                where: w,
                                                                context: context) as? CDVersionManager
                        if ver == nil{
                                ver = CDVersionManager(context:context)
                                ver!.contractAddress = mps
                        }
                        
                        ver!.poolVersion = self.vPool.serialize()
                        ver!.minerVersion = self.vMiner.serialize()
                        ver!.userVersion = self.vUser.serialize()
                        ver!.settingVersion = self.vSetting.serialize()
                        
                        DataShareManager.saveContext(context)
                }
        }
        
        public func equal(_ obj: MPSVersion?) -> Bool{
                guard let o = obj else{
                        return false
                }
                
                return self.vPool == o.vPool
                        && self.vMiner == o.vMiner
                        && self.vUser == o.vUser
                        && self.vSetting == o.vSetting
        }
}
