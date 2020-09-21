//
//  Wallet.swift
//  Pirate
//
//  Created by wesley on 2020/9/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib

class Wallet:NSObject{
        
        var Address:String?
        var SubAddress:String?
        var tokenBalance:Double = 0
        var ethBalance:Double = 0
        var approve:Double = 0
        var coreData:CDWallet?
        
        public static var WInst = Wallet()
        
        override init() {
                
                let w = NSPredicate(format:"mps == %@", HopConstants.DefaultPaymenstService)
                guard let core_data = NSManagedObject.findOneEntity(HopConstants.DBNAME_WALLET,
                                                              where: w,
                                                              context: DataShareManager.privateQueueContext()) as? CDWallet else{
                                return
                }
                
                guard let jsonStr = core_data.walletJSON, jsonStr != "" else {
                        return
                }
                
                guard IosLibLoadWallet(jsonStr) else {
                        NSLog("=======>[Wallet init] parse json failed[\(jsonStr)]")
                        return
                }

                self.Address = core_data.address
                self.SubAddress = core_data.subAddress
                self.tokenBalance = core_data.tokenBalance
                self.ethBalance = core_data.ethBalance
                self.approve = core_data.approve
                coreData = core_data
        }
}
