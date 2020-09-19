//
//  EthUtil.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import BigInt

public final class EthUtil :NSObject{
        var HopToken:ERC20?
        var PaymentService:PacketMarket?
        var web3:web3?
        public static var sharedInstance = EthUtil()
        let queue = DispatchQueue.init(label: "ETH_BACK_GROUND", qos: .default)
        private override init() {
                super.init()
        }
        
        public func initEth(testNet:Bool? = true) throws{
                
                if testNet == nil || testNet! == true{
                        self.web3 = Web3.InfuraRopstenWeb3(accessToken: HopConstants.DefaultInfruaToken)
                }else{
                        self.web3 = Web3.InfuraMainnetWeb3(accessToken: HopConstants.DefaultInfruaToken)
                }
                
                
                guard let token = EthereumAddress(HopConstants.DefaultTokenAddr), let payService = EthereumAddress(HopConstants.DefaultPaymenstService) else{
                        throw HopError.eth("Invalid ethereum config".locStr)
                }
                
                self.HopToken = ERC20.init(web3: self.web3!, address:token)
                self.PaymentService = try PacketMarket.init(web3: self.web3!, address: payService)
        }
        
        public func lastVersion()throws -> MPSVersion{
                return try self.PaymentService!.vm()
        }
        
        public func syncSys()throws -> SysSetting{
                return try self.PaymentService!.setting()
        }
        
        public func AllPoosInMarket() -> [String:PoolDetails]{
                guard let server = self.PaymentService else{
                        return [:]
                }
                
                let pool_addrs = server.Pools()
                
                guard pool_addrs.count > 0 else{
                        NSLog("=======>Pools in market should not be empty......")
                        return [:]
                }
                NSLog("=======>Pools in [\(pool_addrs.count)] size......")
                var result:[String:PoolDetails] = [:]
                
                for pAddr in pool_addrs{
                        
                        if !pAddr.isValid2(){
                                NSLog("=======>Invalid pool address=>[\(pAddr.address)]")
                                continue
                        }
                        
                        guard let pool_data = server.PoolDetail(for: pAddr) else{
                                NSLog("=======>Pool details failed=>[\(pAddr.address)]")
                                continue
                        }
                        NSLog("=======>New pool detail in market got:=>[\(pAddr.address)]")
                        result[pAddr.address] = (pool_data)
                }
                
                return result
        }
        
        
        public func AllMyUserData(userAddr addr:EthereumAddress) -> [EthereumAddress:UserData]{
                guard let server = self.PaymentService else{
                        return [:]
                }
                
                let all_my_pools = server.AllMyPoolsAddress(userAddr:addr)
                guard all_my_pools.count > 0 else{
                        NSLog("=======>User data details should not be empty......")
                        return [:]
                }
                
                var result:[EthereumAddress:UserData] = [:]
                for pAddr in all_my_pools{
                        guard let u_d = server.UserDataEth(userAddr: addr, poolAddr: pAddr) else{
                                NSLog("=======>User Data details failed=>[\(addr.address)=>\(pAddr.address)]")
                                continue
                        }
                        result[pAddr] = u_d
                }
                
                return result
        }
        
        public func UserDataDetails(userAddr:EthereumAddress, poolAddr:EthereumAddress) -> UserData?{
                return self.PaymentService?.UserDataEth(userAddr: userAddr, poolAddr: poolAddr)
        }
        
        public func Balance(userAddr:EthereumAddress) -> (BigUInt, BigUInt){
                guard let server = self.PaymentService else{
                        return (0, 0)
                }
                
                return server.Balance(userAddr: userAddr)
        }
        
        public func approve(from:EthereumAddress, tokenNo:BigUInt, priKey:Data) -> web3swift.TransactionSendingResult?{
                do {
                        let pay_sys = EthereumAddress(HopConstants.DefaultPaymenstService)!
                        
                        guard let tx = try self.HopToken?.approve(from: from, spender: pay_sys, amount: tokenNo)else{
                                return nil
                        }
                        let result = try tx.send(priKey: priKey)
                        return result
                }catch let err{
                        NSLog("=======>\(err.localizedDescription)")
                        return nil
                }
        }
        
        public func waitTilResult(txHash:String)->Bool{
                var i = 0
                repeat {
                        do{
                                let tr = try self.web3?.eth.getTransactionReceipt(txHash)
                                NSLog("=======>status=>\(String(describing: tr?.status))")
                                if tr?.status == .ok{
                                        return true
                                }
                        }catch let err{
                                NSLog("=======>\(err.localizedDescription)")
                        }
                        i += 1
                        sleep(6)
                        
                } while (i < 10)
                
                return false
        }
        
        public func buyAction(user:EthereumAddress, from:String, tokenNo:BigUInt, priKey:Data) -> web3swift.TransactionSendingResult?{
                do {
                        guard let service = self.PaymentService else{
                                return nil
                        }
                        
                        guard let poolAddr = EthereumAddress(from) else{
                                return nil
                        }
                        
                        return try service.BuyPacket(user:user,
                                                      pool:poolAddr,
                                                      tokenNo:tokenNo,
                                                      priKey:priKey)
                }catch let err{
                        NSLog("=======>\(err.localizedDescription)")
                        return nil
                }
        }
        
        public func RandomMiners(inPool:String, maxItem:BigUInt = 16)->[MinerData]{
                guard let service = self.PaymentService else{
                        return []
                }
                
                guard let pool_addr = EthereumAddress(inPool) else{
                        return []
                }
                
                let miner_size = service.MinerNo(ofPool: pool_addr)
                guard miner_size > 0 else{
                        return []
                }
                
                var miner_addr:[Data] = []
                
                if miner_size < maxItem{
                        miner_addr = service.PartOfMiners(inPool: pool_addr, start:0, end:miner_size)
                }else{
                        let start = BigUInt.randomInteger(lessThan: miner_size)
                        var end = start + maxItem
                        if end > miner_size{
                                let ret_pre = service.PartOfMiners(inPool: pool_addr, start:0, end: end - miner_size)
                                miner_addr.append(contentsOf: ret_pre)
                                end = miner_size
                        }
                        let ret = service.PartOfMiners(inPool: pool_addr, start:start, end:end)
                        miner_addr.append(contentsOf: ret)
                }
                
                var result:[MinerData] = []
                for addr in miner_addr{
                        guard addr != HopAccount.invalidAddr else{
                                NSLog("=======>invalid sub address:===>")
                                continue
                        }
                        guard let m_data = service.MinerDetails(address: addr)else{
                                continue
                        }
                        result.append(m_data)
                }
                
                return result
        }
}

extension EthereumAddress{
        
        public static let ZeroAddress = "0x0000000000000000000000000000000000000000"
        
        public func isValid2() -> Bool{
                return self.isValid && self.address != EthereumAddress.ZeroAddress
        }
}
extension String {
        var locStr:String {
                return NSLocalizedString(self, comment: "")
        }
}
