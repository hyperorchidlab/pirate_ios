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
        public var wallet:HopWallet?
        public var poolData:[String:PoolDetails] = [:]
        let dbContext = DataShareManager.privateQueueContext()
        let fileCoordinator = NSFileCoordinator()
        var ethSetting:SysSetting?
        var localSetting:CDCurSettings?
        var localVersion:MPSVersion
        
        private override init() {

                self.localVersion = MPSVersion.Load(for:currentMPS, context: dbContext)
                NSLog("=======>Local verion:=>\(self.localVersion.toString())")
                
                self.ethSetting = SysSetting.Load(for: currentMPS, context: dbContext)
                NSLog("=======>Local ethereum system setting:=>\(self.ethSetting?.toString() ?? "empty")")
                
                self.poolData = PoolDetails.Load(for: currentMPS, context: dbContext)
                NSLog("=======>Pools in market size[\(self.poolData.count)]")
                
                super.init()
                
                loadWallet()
                
                localSetting = SysSetting.loadLocalSetting(for: currentMPS, curWallet: self.wallet?.mainAddress?.address, context: dbContext)
                NSLog("=======>Local setting:=>\(localSetting?.toString() ?? "<->")")
                
                NotificationCenter.default.addObserver(self, selector: #selector(WalletChanged(_:)), name: HopConstants.NOTI_NEW_WALLET, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(WalletChanged(_:)), name: HopConstants.NOTI_IMPORT_WALLET, object: nil)
                
        }
        
        @objc func WalletChanged(_ notification: Notification?) {
                let w = notification?.userInfo?["mainAddress"] as? String
                localSetting = SysSetting.loadLocalSetting(for: currentMPS, curWallet: w, context: dbContext)
                NotificationCenter.default.post(name: HopConstants.NOTI_LOCAL_SETTING_CHANGED, object: nil, userInfo: nil)
        }
        
        public func loadWallet(){
                
                let w_url = HopConstants.WalletPath()
                fileCoordinator.coordinate(readingItemAt: w_url, options: [], error: nil, byAccessor: { (new_url:URL) in
                        guard let w = HopWallet.from(url: new_url) else{
                                NSLog("=======>Load wallet from[\(new_url.path)] failed")
                                return
                        }
                        self.wallet = w
                        PacketAccountant.Inst.setEnv(MPSA: currentMPS, user: w.mainAddress!.address)
                })
//                NSLog("=======>Load wallet \(self.wallet?.toJson() ?? "invalid wallet") ")
        }
        
        public static func EthVersionCheck(){
                dataQueue.async {
                        NSLog("=======>EthVersionCheck start--->")
                        do{
                                try sharedInstance.timerCheck()
                        }catch let err{
                                NSLog("=======>EthVersionCheck err:\(err.localizedDescription)--->")
                        }
                }
        }
        
        func timerCheck() throws{
                
                let vm = try EthUtil.sharedInstance.lastVersion()
                
                NSLog("=======>Ethereum verion:=>\(vm.toString())")
                if vm.equal(self.localVersion){
                        NSLog("=======>Versin manager equals")
                        return
                }
                                
                var hasErr = false
                self.syncSysSetting(ethVer:vm.vSetting, &hasErr)
                self.syncPoolData(ethVer:vm.vPool, &hasErr)
                self.syncUserData(ethVer:vm.vUser, &hasErr)
                if hasErr{
                        NSLog("=======>Failed to update local version!")
                        return
                }
                self.localVersion.update(mps: currentMPS, context: self.dbContext)
                DataShareManager.syncAllContext(self.dbContext)
        }
        
        func syncPoolData(ethVer:BigUInt, _ hasErr:inout Bool){
                
                if ethVer == self.localVersion.vPool{
                        NSLog("=======>Pool data no need to sync......")
                        return
                }
                
                do{
                        let pools = EthUtil.sharedInstance.AllPoosInMarket()
                        try PoolDetails.savePoolData(pools, for: currentMPS, context: dbContext)
                        self.poolData = pools
                        self.localVersion.vPool = ethVer
                        //TODO::Notification
                }catch let err{
                        NSLog(err.localizedDescription)
                        hasErr = true
                }
        }
        
        func syncSysSetting(ethVer:BigUInt, _ hasErr:inout Bool){
                
                if ethVer == self.localVersion.vSetting && self.ethSetting != nil{
                        NSLog("=======>System setting no need to sync......")
                        return
                }
                do{
                        let settings = try EthUtil.sharedInstance.syncSys()
                        SysSetting.saveSysSetting(settings, for: currentMPS, context: dbContext)
                        self.ethSetting = settings
                        self.localVersion.vSetting = ethVer
                        NSLog("=======>New system setting:=>\(settings.toString())")
                        //TODO::Notification
                }catch let err{
                        NSLog(err.localizedDescription)
                        hasErr = true
                }
        }
        
        func syncUserData(ethVer:BigUInt, _ hasErr:inout Bool){
              
                guard let wallet_addr = self.wallet?.mainAddress else{
                        NSLog("=======>Empty account no need to sync user data......")
                        return
                }
                
                if ethVer == self.localVersion.vUser{
                        NSLog("=======>Current user data no need to sync......")
                        return
                }
                
                NSLog("=======>User data need to sync......")
                let user_datas = EthUtil.sharedInstance.AllMyUserData(userAddr:wallet_addr)
                for (pool, u_d) in user_datas{
                       PacketAccountant.Inst.updateByEthData(userData: u_d, forPool:pool)
                }
                self.localVersion.vUser = ethVer
        }
        
        public func updateLocalSetting(minerArr:[MinerData]){
                self.localSetting?.updateMinerList(minerArr:minerArr, context:dbContext)
        }
}
