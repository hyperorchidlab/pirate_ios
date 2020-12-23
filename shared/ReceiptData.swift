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
                                                               .uint(bits: 256), .uint(bits: 256), .uint(bits: 256)]
        
        public static let abiSignType:[ABI.Element.ParameterType] = [.string, .bytes(length: 32)]
        
        public static let abiPrefix = "\u{19}Ethereum Signed Message:\n32"
        
        var usedTraffic:Int64?
        var time:String?
        var minerID:String?
        var minerAmount:Int64?
        var minerCredit:Int64?
        var contractAddr : String?
        var tokenAddr : String?
        var user:String?
        var pool:String?
        var txSig:String?
        var hashV:String?
        
        public init(json:JSON){
                self.txSig = json["signature"].string
                self.hashV = json["hash"].string
                self.time = json["time"].string
                self.minerID = json["minerID"].string
                self.user = json["user"].string
                self.pool = json["pool"].string
                self.minerAmount = json["miner_amount"].int64
                self.minerCredit = json["miner_credit"].int64
                self.contractAddr = json["author"]["contract"].string
                self.tokenAddr = json["author"]["token"].string
        }
        
        public func toString()->String{
                return "Transaction=>{\ntxsig=\(txSig ?? "<->")\nhashV=\(hashV ?? "<->")\ntime=\(time!)\nminerID=\(minerID!)\nfrom=\(user!) \nto=\(pool!)\nminerAmount=\(minerAmount!)\nminerCredit=\(minerCredit!)\ncontractAddr=\(contractAddr!)\ntokenAddr=\(tokenAddr!)\n}\n"
        }
        
        public init(userData:CDMemberShip, amount:Int64, for miner:String){
                super.init()
                self.minerID = miner
                self.user = EthereumAddress.toChecksumAddress(userData.userAddr!)
                self.pool = EthereumAddress.toChecksumAddress(userData.poolAddr!)
                self.minerAmount = amount
                self.minerCredit = userData.usedTraffic
        }
        
        func createABIHash() -> Data?{
                
                let parameters:[AnyObject] = [EthereumAddress(HopConstants.DefaultPaymenstService)! as AnyObject,
                                              EthereumAddress(HopConstants.DefaultTokenAddr)! as AnyObject,
                                        EthereumAddress(self.user!)! as AnyObject,
                                        EthereumAddress(self.pool!)! as AnyObject,
                                        self.minerCredit as AnyObject,
                                        self.minerAmount as AnyObject,
                                        self.usedTraffic as AnyObject]
                
                let tx_encode = ABIEncoder.encode(types:TransactionData.txInputType, values: parameters)
                let tx_hash = tx_encode!.sha3(.keccak256)
                let pre_parameters:[AnyObject] = [TransactionData.abiPrefix as AnyObject, tx_hash as AnyObject]
                
                let pre_encode = ABIEncoder.encode(types:TransactionData.abiSignType, values: pre_parameters)
                return  pre_encode?.sha3(.keccak256)
        }
        /*
         {"signature":"wcOjDhMc2nthSa3jTHzO/nsxqsv9d3ESo8cYTFvlmg8177fNqJk6ION/hCMXb5Qp+wqlfiM6m8PD1qjStnE/7AA=","hash":"8HGDVD9Q8fz2iqs8/pBWv6EjECbrjeNgeyDeNIuDe7Q=","used_traffic":1000,"time":1608721312222,"minerID":"HOGpBCzYGgzuSsJGuMDMpVsp24gPVScuiziZswwWLJ8fN1","user":"0xc3df37433b0aaa18e120dbff932cc3e64db79336","pool":"0xc3df37433b0aaa18e120dbff932cc3e64db79336","miner_amount":4,"miner_credit":12,"author":{"contract":"0xc3df37433b0aaa18e120dbff932cc3e64db79336","token":"0xc3df37433b0aaa18e120dbff932cc3e64db79336"}}
         */
        
        public static let TxFormat = "{\"signature\":\"%@\",\"hash\":\"%@\",\"used_traffic\":%d,\"time\":\"%@\",\"minerID\":\"%@\",\"user\":\"%@\",\"pool\":\"%@\",\"miner_amount\":%d,\"miner_credit\":%d,\"author\":{\"contract\":\"%@\",\"token\":\"%@\"}}"
        
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
                
                let tx_str = "{\"signature\":\"\(self.txSig!)\",\"hash\":\"\(self.hashV!)\",\"used_traffic\":\(self.usedTraffic!),\"time\":\"\(now_str)\",\"minerID\":\"\(self.minerID!)\",\"user\":\"\(self.user!)\",\"pool\":\"\(self.pool!)\",\"miner_amount\":\(self.minerAmount!),\"miner_credit\":\(self.minerCredit!),\"author\":{\"contract\":\"\(HopConstants.DefaultPaymenstService)\",\"token\":\"\(HopConstants.DefaultTokenAddr)\"}}"

                NSLog("--------->Create transaction:\(tx_str)")
                return tx_str.data(using: .utf8)
        }
        public func verifyTx() -> Bool{
           
                guard self.tokenAddr?.lowercased() == HopConstants.DefaultTokenAddr.lowercased(),
                      self.contractAddr?.lowercased() == HopConstants.DefaultPaymenstService.lowercased() else {
                        NSLog("--------->verifyTx mps or token wrong")
                        return false
                }
                
                guard let hash_data = self.createABIHash() else {
                        NSLog("--------->verifyTx createABIHash failed")
                        return false
                }
                
                guard let signature = Data.init(base64Encoded: self.txSig!) else{
                        NSLog("--------->verifyTx signature base64Encoded failed")
                        return false
                }
                
                guard let recovered = Web3.Utils.hashECRecover(hash: hash_data, signature: signature) else {
                        NSLog("--------->verifyTx recovered failed")
                        return false
                }
                
                guard let userAddr = EthereumAddress(self.user!) else{
                        NSLog("--------->verifyTx userAddr invalid")
                        return false
                }
                NSLog("--------->recoverd=\(recovered) userAddr=\(userAddr)")
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
