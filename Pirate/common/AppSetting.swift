//
//  AppSetting.swift
//  Pirate
//
//  Created by wesley on 2020/9/21.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib

class AppSetting:NSObject{
        
        public static let workQueue = DispatchQueue.init(label: "APP Work Queue")
        public static var curPoolAddr:String?
        public static var curMinerAddr:String?
        public static var dnsIP:String?
        static var coreData:CDAppSetting?
        
        public static func initSystem(){
                
                IosLibInitSystem(HopConstants.DefaultDnsIP,
                                 HopConstants.DefaultTokenAddr,
                                 HopConstants.DefaultPaymenstService,
                                 HopConstants.DefaultInfruaToken)
                
                let context = DataShareManager.privateQueueContext()
                
                let w = NSPredicate(format:"mps == %@", HopConstants.DefaultPaymenstService)
                
                var setting = NSManagedObject.findOneEntity(HopConstants.DBNAME_APPSETTING,
                                                              where: w,
                                                              context: context) as? CDAppSetting
                if setting == nil{
                        setting = CDAppSetting(context: context)
                        setting!.mps = HopConstants.DefaultPaymenstService
                        setting!.dnsIP = HopConstants.DefaultDnsIP
                        setting!.minerAddrInUsed = nil
                        setting!.poolAddrInUsed = nil
                        
                        AppSetting.coreData = setting
                        AppSetting.dnsIP = setting?.dnsIP
                        
                        DataShareManager.saveContext(context)
                        return 
                }
                
                AppSetting.coreData = setting
                AppSetting.curPoolAddr = setting!.poolAddrInUsed
                AppSetting.curMinerAddr = setting!.minerAddrInUsed
                AppSetting.dnsIP = setting?.dnsIP ??  HopConstants.DefaultDnsIP
        }
        
        public static func changeDNS(_ dns:String){
                coreData?.dnsIP = dns
                AppSetting.dnsIP = dns
                let context = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(context)
                PostNoti(HopConstants.NOTI_DNS_CHANGED)
        }
}

