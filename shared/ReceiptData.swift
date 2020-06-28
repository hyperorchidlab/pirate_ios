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

public class CreditAuthor:NSObject{
        
        var contract:String?
        var token:String?
        
        public init?(json:[String:Any]){
                super.init()
                
                guard let contract = json["contract"] as? String,
                      let token = json["token"] as? String else{
                        NSLog("--------->Invalid credit author data:")
                        return nil
                }
                
                self.contract = EthereumAddress.toChecksumAddress(contract)
                self.token = EthereumAddress.toChecksumAddress(token)
        }
        
        public func verify(_ tokenAddr:String, _ paymentAddr:String) -> Bool{
                return EthereumAddress.toChecksumAddress(tokenAddr)  == self.token! &&
                        EthereumAddress.toChecksumAddress(paymentAddr) == self.contract!
        }
}

public class TransactionDatya:NSObject{
        
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
        var author : CreditAuthor?
        
        public init?(json: [String: Any]){
                super.init()
                
                guard let txSig = json["signature"] as? String,
                        let hashV = json["hash"] as? String,
                        let epoch = json["CN"] as? Int32,
                        let nonce = json["nonce"] as? Int64,
                        let time = json["time"] as? String,
                        let minerID = json["minerID"] as? String,
                        let from = json["from"] as? String,
                        let to = json["to"] as? String,
                        let amount = json["amount"] as? Int64,
                        let credit = json["credit"] as? Int64 else{
                                NSLog("--------->Parse transaction data failed")
                                return
                }
                
                guard let author_json = json["author"] as? [String:Any] else{
                        NSLog("--------->Parse auther data failed")
                        return nil
                }
                
                guard let author = CreditAuthor(json: author_json) else{
                        return nil
                }
                
                self.txSig = txSig
                self.hashV = hashV
                self.epoch = epoch
                self.nonce = nonce
                self.time = time
                self.minerID = minerID
                self.from = EthereumAddress.toChecksumAddress(from)
                self.to = EthereumAddress.toChecksumAddress(to)
                self.amount = amount
                self.credit = credit
                self.author = author
        }
        
        public func toString()->String{
                return "Transaction=>{\ntxsig=\(txSig ?? "<->")\nhashV=\(hashV ?? "<->")\nepoch=\(epoch!)\nnonce=\(nonce!)\ntime=\(time!)\nminerID=\(minerID!)\nfrom=\(from!) \nto=\(to!)\namount=\(amount!)\ncredit=\(credit!)\nauthor={\ncontract=\(author!.contract!) \ntoken=\(author!.token!)}}"
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
                
                let tx_encode = ABIEncoder.encode(types:TransactionDatya.txInputType, values: parameters)
                let tx_hash = tx_encode!.sha3(.keccak256)
                let pre_parameters:[AnyObject] = [TransactionDatya.abiPrefix as AnyObject, tx_hash as AnyObject]
                
                let pre_encode = ABIEncoder.encode(types:TransactionDatya.abiSignType, values: pre_parameters)
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
//                let tx_str = String(format: TransactionDatya.TxFormat, self.txSig!, self.hashV!, self.epoch!,
//                                    self.nonce!, now_str, self.minerID!, self.from!, self.to!, self.amount!,
//                                    self.credit!, HopConstants.DefaultPaymenstService, HopConstants.DefaultTokenAddr)

                NSLog("--------->Create transaction:\(tx_str)")
                return tx_str.data(using: .utf8)
        }
        
        public func verifyTx() -> Bool{
                
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
        var tx:TransactionDatya?
        
        public override init() {
                super.init()
        }
        
        public init?(json: [String: Any]){
                super.init()
                guard let sig = json["sig"] as? String else{
                        NSLog("--------->Parse sig from receipt failed")
                        return nil
                }
                self.sig = sig
                
                guard let tx_data = json["tx"] as? [String:Any] else{
                        NSLog("--------->Parse tx data from receipt failed")
                        return nil
                }
                
                guard let tx = TransactionDatya(json: tx_data) else{
                        NSLog("--------->Parse transaction data failed")
                        return nil
                }
                self.tx = tx
        }
        
        public func toString()->String{
                return "\n ReceiptData=>{\n sig=\(self.sig ?? "<->") \n\(self.tx!.toString())\n}"
        }
}
