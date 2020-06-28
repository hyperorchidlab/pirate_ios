//
//  MicroChain.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import CoreData
import BigInt


public class MicroChain :NSObject{
        
        var localVersion: MPSVersion
        var currentMPS:String
        let dbContext = DataShareManager.privateQueueContext()
        let blockchainQueue = DispatchQueue(label: "Ethereum Sync Queue", qos: .default)
        var userAddr:EthereumAddress
        var poolAddr:EthereumAddress
        
        public init(paymentAddr:String,
                    pool:EthereumAddress,
                    userAddr ua:String) {
                
                self.currentMPS = paymentAddr
                userAddr = EthereumAddress(ua)!
                poolAddr = pool
                self.localVersion = MPSVersion.Load(for: self.currentMPS, context: self.dbContext)
                NSLog("--------->local version:\(self.localVersion.toString())")
                super.init()
        }
        
        public func start(){
               DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: Protocol.EthSyncTime,
                                                          repeats: true) { (time) in
                        self.monitor()
                }}
        }
        
        private func monitor(){ blockchainQueue.async { do{
                
                NSLog("---------> Ethereum runloop fired")
                let vm = try EthUtil.sharedInstance.lastVersion()
                NSLog("---------> ethereum verion:=>\(vm.toString())+++++++++")
                if vm.vUser == self.localVersion.vUser{
                        NSLog("---------> no user data to sync+++++++++>")
                        return
                }
                
                guard let user_data = EthUtil.sharedInstance.UserDataDetails(userAddr:self.userAddr,
                                                                             poolAddr:self.poolAddr) else{
                        NSLog("---------> user data of ethereum parse failed +++++++++>")
                        return
                }
                
                PacketAccountant.Inst.updateByEthData(userData:user_data, forPool: self.poolAddr)
                
                self.localVersion.vUser = vm.vUser
                self.localVersion.update(mps: self.currentMPS, context: self.dbContext)
                DataShareManager.syncAllContext(self.dbContext)
                
        }catch let err {
                NSLog("---------> Ethereum Block Chain Syncing Thread :\(err.localizedDescription)")
        }}}
}
