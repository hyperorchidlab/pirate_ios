//
//  ReceiptData.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/9.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt
import web3swift
import SwiftyJSON
import CoreData

public class TransactionData:NSObject{
        
        public static let txInputType:[ABI.Element.ParameterType] = [.address, .address,
                                                               .address, .address,
                                                               .uint(bits: 256), .uint(bits: 256),
                                                               .uint(bits: 256), .uint(bits: 256)]
        
        public static let abiSignType:[ABI.Element.ParameterType] = [.string, .bytes(length: 32)]
        
        public static let abiPrefix = "\u{19}Ethereum Signed Message:\n32"
        
        var txSig:String?
        var hashV:String?
        var epoch:Int32?
        var nonce:Int64?
        var time:String?
        var minerID:String?
        var from:String?
        var to:String?
        var amount:Int64?
        var credit:Int64?
        var contractAddr : String?
        var tokenAddr : String?
        
        public init(json:JSON){
                self.txSig = json["signature"].string
                self.hashV = json["hash"].string
                self.epoch = json["CN"].int32
                self.nonce = json["nonce"].int64
                self.time = json["time"].string
                self.minerID = json["minerID"].string
                self.from = json["from"].string
                self.to = json["to"].string
                self.amount = json["amount"].int64
                self.credit = json["credit"].int64
                self.contractAddr = json["contract"].string
                self.tokenAddr = json["token"].string
        }
        
        public func toString()->String{
                return "Transaction=>{\ntxsig=\(txSig ?? "<->")\nhashV=\(hashV ?? "<->")\nepoch=\(epoch!)\nnonce=\(nonce!)\ntime=\(time!)\nminerID=\(minerID!)\nfrom=\(from!) \nto=\(to!)\namount=\(amount!)\ncredit=\(credit!)\n}}"
        }
        
        public init?(userData:CDUserAccount, amount:Int64, for miner:String){
                super.init()
                self.epoch = userData.epoch
                self.nonce = userData.microNonce + 1
                self.minerID = miner
                self.from = EthereumAddress.toChecksumAddress(userData.userAddr!)
                self.to = EthereumAddress.toChecksumAddress(userData.poolAddr!)
                self.amount = amount
                self.credit = userData.credit
        }
        
        func createABIHash() -> Data?{
                
                let parameters:[AnyObject] = [EthereumAddress(HopConstants.DefaultPaymenstService)! as AnyObject,
                                              EthereumAddress(HopConstants.DefaultTokenAddr)! as AnyObject,
                                        EthereumAddress(self.from!)! as AnyObject,
                                        EthereumAddress(self.to!)! as AnyObject,
                                        self.credit as AnyObject,
                                        self.amount as AnyObject,
                                        self.nonce as AnyObject,
                                        self.epoch as AnyObject]
                
                let tx_encode = ABIEncoder.encode(types:TransactionData.txInputType, values: parameters)
                let tx_hash = tx_encode!.sha3(.keccak256)
                let pre_parameters:[AnyObject] = [TransactionData.abiPrefix as AnyObject, tx_hash as AnyObject]
                
                let pre_encode = ABIEncoder.encode(types:TransactionData.abiSignType, values: pre_parameters)
                return  pre_encode?.sha3(.keccak256)
        }
        
        public static let TxFormat = "{\"signature\":\"%@\",\"hash\":\"%@\",\"CN\":%d,\"nonce\":%d,\"time\":\"%@\",\"minerID\":\"%@\",\"from\":\"%@\",\"to\":\"%@\",\"amount\":%d,\"credit\":%d,\"author\":{\"contract\":\"%@\",\"token\":\"%@\"}}"
        
        func createTxData(sigKey:Data) -> Data?{
                guard let hash_data = self.createABIHash() else {
                        return nil
                }
                
                let (signVal, _) = SECP256K1.signForHash(hash: hash_data, privateKey: sigKey)
                guard let d = signVal else{
                        return nil
                }
                self.txSig = d.base64EncodedString()
                self.hashV = hash_data.base64EncodedString()
                let now_str =  Date().stringVal
                
                let tx_str = "{\"signature\":\"\(self.txSig!)\",\"hash\":\"\(self.hashV!)\",\"CN\":\(self.epoch!),\"nonce\":\(self.nonce!),\"time\":\"\(now_str)\",\"minerID\":\"\(self.minerID!)\",\"from\":\"\(self.from!)\",\"to\":\"\(self.to!)\",\"amount\":\(self.amount!),\"credit\":\(self.credit!),\"author\":{\"contract\":\"\(HopConstants.DefaultPaymenstService)\",\"token\":\"\(HopConstants.DefaultTokenAddr)\"}}"

                NSLog("--------->Create transaction:\(tx_str)")
                return tx_str.data(using: .utf8)
        }
        public func verifyTx() -> Bool{
           
                guard self.tokenAddr?.lowercased() == HopConstants.DefaultTokenAddr.lowercased(),
                      self.contractAddr?.lowercased() == HopConstants.DefaultPaymenstService.lowercased() else {
                        return false
                }
                
                guard let hash_data = self.createABIHash() else {
                        return false
                }
                
                guard let signature = Data.init(base64Encoded: self.txSig!) else{
                        return false
                }
                
                guard let recovered = Web3.Utils.hashECRecover(hash: hash_data, signature: signature) else {
                        return false
                }
                
                guard let userAddr = EthereumAddress(self.from!) else{
                        return false
                }
                
                 return recovered == userAddr
        }
}

public class ReceiptData:NSObject{
        
        var sig:String?
        var tx:TransactionData?
        
        public override init() {
                super.init()
        }
        
        public init(json:JSON){
                self.sig = json["sig"].string
                let txJson = json["tx"]
                self.tx = TransactionData(json: txJson)
        }
        
        public func toString()->String{
                return "\n ReceiptData=>{\n sig=\(self.sig ?? "<->") \n\(self.tx!.toString())\n}"
        }
}

extension CDMemberShip{
        
        func updateByReceipt(json:JSON){
                
        }

}
