//
//  Transaction.swift
//  Pirate
//
//  Created by wesley on 2020/9/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import IosLib

public enum TransactionStatus:Int16 {
        case pending
        case fail
        case success
        case nosuch
        
        var name:String {
                switch self {
                case .pending:
                        return "Pending".locStr
                case .fail:
                        return "Failed".locStr
                case .success:
                        return "Success".locStr
                case .nosuch:
                        return "No suche TX".locStr
                }
        }
        var StatusBGColor:UIColor{
                switch self {
                case .success:
                        return UIColor.init(hex: "#458AF933")!
                case .fail:
                        return UIColor.init(hex: "#F9704533")!
                case .pending, .nosuch:
                        return UIColor.init(hex: "#FFAC0033")!
                }
        }
        
        var StatusBorderColor:CGColor{
                switch self {
                case .success:
                        return UIColor.init(hex: "#458AF94D")!.cgColor
                case .fail:
                        return UIColor.init(hex: "#F970454D")!.cgColor
                case .pending, .nosuch:
                        return UIColor.init(hex: "#FFAC004D")!.cgColor
                }
        }
        
        var StatusTxtColor:UIColor{
                switch self {
                case .success:
                        return UIColor.init(hex: "#458AF9FF")!
                case .fail:
                        return UIColor.init(hex: "#F97045FF")!
                case .pending, .nosuch:
                        return UIColor.init(hex: "#FFB214FF")!
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
                obj.coreData = cdata
                
                DataShareManager.saveContext(dbCtx)
                return true
        }
}

extension CDTransaction{
        
        func initByObj(obj:Transaction, addr:String){
                self.walletAddr = addr
                self.txHash = obj.txHash
                self.actType = obj.txType.rawValue
                self.status = obj.txStatus.rawValue
        }
}
