//
//  EthSyncer.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/27.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt

public final class DataSyncer:NSObject{
        
        public static let dataQueue = DispatchQueue(label: "Data Syncer Queue", qos: .default)
        public static var sharedInstance = DataSyncer()
        public static var isGlobalModel:Bool = false
        
        public let currentMPS:String = HopConstants.DefaultPaymenstService
       
        public var poolData:[String:PoolDetails] = [:]
        let dbContext = DataShareManager.privateQueueContext()
        var ethSetting:SysSetting?
        
        private override init() {
                
                self.ethSetting = SysSetting.Load(for: currentMPS, context: dbContext)
                NSLog("=======>Local ethereum system setting:=>\(self.ethSetting?.toString() ?? "empty")")
                
                self.poolData = PoolDetails.Load(for: currentMPS, context: dbContext)
                NSLog("=======>Pools in market size[\(self.poolData.count)]")
                
                super.init()
        }
}
