//
//  SysSetting.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/27.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt
import CoreData
import web3swift

public class SysSetting:NSObject{
        
        public var MBytesPerToken:BigUInt = 0
        public var RefundDuration:BigUInt = 0
        public var PoolGTN:BigUInt = 0
        public var MinerGTN:BigUInt = 0
        
        public override init() {
                super.init()
        }
        
        //TODO::
        public func initSys(){
                
//                HopWallet.loadWallet()
//                guard let w = HopWallet.WInst else{
//                        return
//                }
//                PacketAccountant.Inst.setEnv(MPSA: HopConstants.DefaultPaymenstService, user: w.mainAddress!.address)
        }
        
        public convenience init(_ sys:CDSystemSettings){
                self.init()
                
                if let price = sys.price {
                        MBytesPerToken = BigUInt.init(price)
                }
                if let refund = sys.refund {
                        RefundDuration = BigUInt.init(refund)
                }
                if let poolGTN = sys.poolGTN {
                        PoolGTN = BigUInt.init(poolGTN)
                }
                if let minerGTN = sys.minerGTN {
                        MinerGTN = BigUInt.init(minerGTN)
                }
        }
        
        public convenience init(_ ethData:[String:Any]){
                self.init()
                
                guard let price = ethData["MBytesPerToken"] as? BigUInt,
                        let duration = ethData["Duration"] as? BigUInt,
                        let pGTN = ethData["MinPoolGuarantee"] as? BigUInt,
                        let mGTN = ethData["MinMinerGuarantee"] as? BigUInt else{
                                return
                }
                
                MBytesPerToken = price
                RefundDuration = duration
                PoolGTN = pGTN
                MinerGTN = mGTN
        }
        
        public static func Load(for mps:String, context :NSManagedObjectContext) -> SysSetting?{
                
                var setting : SysSetting? = nil
                context.performAndWait{ () -> Void in
                        
                       let w = NSPredicate(format:"contractAddress == %@", mps) 
                       guard let sysSet = NSManagedObject.findOneEntity(HopConstants.DBNAME_SETTING,
                                                                     where: w,
                               context: context) as? CDSystemSettings else{
                                        return
                        }
                        setting = SysSetting(sysSet)
                }
               
                return setting
        }
        
        func toString() -> String {
                return "[SysSetting\n MBytesPerToken:\(MBytesPerToken),\t RefundDuration:\(RefundDuration)\tPoolGTN:\(PoolGTN)\tMinerGTN:\(MinerGTN)]"
        }
        
        static func saveSysSetting(_ sys:SysSetting,
                                   for mps:String,
                                   context :NSManagedObjectContext){
                
                context.performAndWait {
                
                        let w = NSPredicate(format:"contractAddress == %@", mps)
                        var sysSet = NSManagedObject.findOneEntity(HopConstants.DBNAME_SETTING,
                                                                   where: w, context: context) as? CDSystemSettings
                
                        if sysSet ==  nil{
                                sysSet = CDSystemSettings(context:context)
                                sysSet!.contractAddress = mps
                        }
                
                        sysSet!.price = sys.MBytesPerToken.serialize()
                        sysSet!.refund = sys.RefundDuration.serialize()
                        sysSet!.poolGTN = sys.PoolGTN.serialize()
                        sysSet!.minerGTN = sys.MinerGTN.serialize()

                        DataShareManager.saveContext(context)
                }
        }
        
        public static func loadLocalSetting(for mps:String, curWallet:String?, context :NSManagedObjectContext) -> CDCurSettings?{
                guard let user = curWallet else{
                        return nil
                }
                var setting:CDCurSettings?
                context.performAndWait{
                        
                        () -> Void in
                        let w = NSPredicate(format:"contractAddress == %@ And curMainAddr == %@", mps, user)
                        guard let s = NSManagedObject.findOneEntity(HopConstants.DBNAME_LocalSetting,
                                                                          where: w,context: context) as? CDCurSettings else{
                                let new_obj = CDCurSettings(context: context)
                                new_obj.contractAddress = mps
                                new_obj.basIPInUse = HopConstants.DefaultBasIP
                                new_obj.curMainAddr = user
                                context.insert(new_obj)
                                DataShareManager.saveContext(context)
                                setting = new_obj
                                return
                        }
                        
                        setting = s
                        MinerData.fullFill(data: s.minerListInUse)
                }
                
                return setting
        }
}

extension CDCurSettings{
        
        public func toString() -> String{
                return "\nCDCurSettings=>{\n basIP=\(self.basIPInUse ?? "<->")\n minerInUse=\(self.minerInUse ?? "<->")\n tokenAddr=\(self.tokenAddrInUse ?? "<->")\n poolAddr=\(self.poolInUse ?? "<->")\n}"
        }
        
        public func updateMinerList(minerArr:[MinerData], context:NSManagedObjectContext){
                MinerData.MinerDetailsDic.removeAll()
                
                for md in minerArr{
                        MinerData.MinerDetailsDic[md.Address] = md
                }
                let data = MinerData.serialize(miners: minerArr)
                self.minerListInUse = data
                DataShareManager.saveContext(context)
        }
}
