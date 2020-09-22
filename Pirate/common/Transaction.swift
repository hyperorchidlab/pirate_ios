//
//  Transaction.swift
//  Pirate
//
//  Created by wesley on 2020/9/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import IosLib


public enum TransactionStatus:Int16 {
        case pending
        case failed
        case success
        case nosuch
        
        var name:String {
                switch self {
                case .pending:
                        return "Pending".locStr
                case .failed:
                        return "Failed".locStr
                case .success:
                        return "Success".locStr
                case .nosuch:
                        return "No suche TX".locStr
                }
        }
}


public enum TransactionType:Int16 {
        case unknown
        case applyEth
        case applyToken
        case buyPool
        
        var name:String{
                switch self {
                case .applyEth:
                        return "Apply GAS".locStr
                case .applyToken:
                        return "Apply Token".locStr
                case .buyPool:
                        return "Buy Service".locStr
                case .unknown:
                        return "Unknown".locStr
                }
        }
}
        
        
class Transaction : NSObject {
        
        public static var CachedTX:[Transaction] = []
        
        var coreData:CDTransaction?
        var txValue:Double = 0
        var txStatus:TransactionStatus = .nosuch
        var txHash:String?
        var txType:TransactionType = .unknown
        
        override init() {
                super.init()
        }
        
        public init(tx:String, typ:TransactionType, value:Double? = nil){
                super.init()
                txHash = tx
                txType = typ
                txValue = value ?? 0
                
        }
        
        private func syncCache(reloadAll:Bool = false){
               
        }
        
        public static func applyFreeEth(forAddr address:String) -> Bool{
                guard address != ""  else {
                        return false
                }
                
                let txHash = IosLibApplyFreeEth(address)
                if txHash == ""{
                        return false
                }
                
                let obj = Transaction(tx: txHash, typ: .applyEth)
                CachedTX.append(obj)
                
                let dbCtx = DataShareManager.privateQueueContext()
                let cdata = CDTransaction(context: dbCtx)
                cdata.initByObj(obj: obj, addr: address)
                
                
                
                
                return true
        }
}


extension CDTransaction{
        
        func initByObj(obj:Transaction, addr:String){
                self.walletAddr = addr
        }
}
