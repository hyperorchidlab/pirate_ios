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
import SwiftyJSON

class Wallet:NSObject{
        
        var Address:String?
        var SubAddress:String?
        var coreData:CDWallet?
        
        var tokenBalance:Double = 0
        var ethBalance:Double = 0
        var approve:Double = 0
        
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
        
        public func queryBalance(){
                
                guard let addr = self.Address, addr != "" else {
                        return
                }
                
                guard let bData = IosLibBalance(addr) else{
                        return
                }
                
                let jsonObj = JSON(bData)
                self.ethBalance = jsonObj["Eth"].double ?? 0
                self.tokenBalance = jsonObj["Hop"].double ?? 0
                self.approve = jsonObj["Approved"].double ?? 0
                
                self.coreData?.approve = self.approve
                self.coreData?.tokenBalance = self.tokenBalance
                self.coreData?.ethBalance = self.ethBalance
        }
        
        public func initByJson(_ jsonData:Data){
                let jsonObj = JSON(jsonData)
                self.Address = jsonObj["mainAddress"].string
                self.SubAddress = jsonObj["subAddress"].string
        }
        
        public static func NewInst(auth:String) -> Bool{
                guard let jsonData = IosLibNewWallet(auth) else{
                        return false
                }
                
                WInst.initByJson(jsonData)
                
                let context = DataShareManager.privateQueueContext()
                let w = NSPredicate(format:"mps == %@", HopConstants.DefaultPaymenstService)
                var core_data = NSManagedObject.findOneEntity(HopConstants.DBNAME_WALLET,
                                                              where: w,
                                                              context: context) as? CDWallet
                if core_data == nil{
                        core_data = CDWallet(context: context)
                        core_data!.mps = HopConstants.DefaultPaymenstService
                }
                
                core_data!.walletJSON = String(data: jsonData, encoding: .utf8)
                core_data!.address = WInst.Address
                core_data!.subAddress = WInst.SubAddress
                WInst.coreData = core_data
                
                DataShareManager.saveContext(context)
                
                return true
        }
}
