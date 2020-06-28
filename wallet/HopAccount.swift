//
//  HopAccount.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import CryptoSwift
import Curve25519

public struct New32aHash{
        public static let offset = UInt32(2166136261)
        public static let prime32 = UInt32(16777619)
        
        public static func hash(_ str:String) -> UInt32 {
                
                var hash = New32aHash.offset
                let data = str.data(using: .utf8)
                
                for c in  data! {
                        hash = hash ^ UInt32(c)
                        (hash, _) = hash.multipliedReportingOverflow(by: New32aHash.prime32)
                }
                
//                NSLog("\(hash)")
                return hash
        }
}

public class HopAccount:NSObject, Codable{
        
        public var address:String?
        public var cipher:String?
        public var priKey:Data?
        public static let invalidAddr = Data.init(repeating: 0, count: 32)
        
        
        public override init() {
                super.init()
        }
        
        public init(addr:String, cipher c:String){
                self.address = addr
                self.cipher = c
                super.init()
        }
        
        public static func IsHopID(str:String)->Bool{
                return str.hasPrefix(HopConstants.HOP_SUB_PREFIX)
        }
        
        public static func NewAcc(auth:String) -> HopAccount?{
                do{
                        let (pubKey, priKey) = try HopSodium.genKeyPair()
                        
                        NSLog(pubKey.toHexString())
                        NSLog(priKey.toHexString())
        
                        let instance = HopAccount()
                        instance.address = HopConstants.HOP_SUB_PREFIX + Base58.base58FromBytes(pubKey.bytes)
                        instance.priKey = priKey
                        
                        guard let aes_key = HopAccount.aesKey(pubKey: pubKey, auth: auth) else{
                                return nil
                        }
                                
                        guard var iv = Data.randomBytes(length: HopConstants.HOP_WALLET_IVLEN) else{
                               return nil
                        }

                        let encrypted:Array<UInt8> = try AES(key: aes_key,
                                                             blockMode: CFB(iv: iv.bytes),
                                                             padding:.noPadding).encrypt(priKey.bytes)
                        
                        iv.append(contentsOf: encrypted)
                        instance.cipher = Base58.base58FromBytes(iv.bytes)
                        
                        return instance
                
                }catch let err{
                        NSLog(err.localizedDescription)
                                return nil
                }
        }
        
        public static func aesKey(pubKey:Data, auth:String) -> [UInt8]?{
                let _P = HopConstants.HOP_AES_PARAM
                let salt = pubKey[...(_P.S - 1)]
                guard let password = auth.data(using: .utf8)?.bytes else{
                       return nil
                }
                
                let deriver = try? CryptoSwift.Scrypt(password: password,
                                                    salt: salt.bytes,
                                                     dkLen: _P.dkLen,
                                                     N: _P.N,
                                                     r: _P.R,
                                                     p: _P.P)
                guard let der = deriver else{
                        return nil
                }
                
                do {
                        return try der.calculate()
                }catch let err{
                        NSLog(err.localizedDescription)
                        return nil
                }
        }
        
        public static func getPub(address:String?)->Data?{
                
                guard let str = address else{
                        return nil
                }
                
                let index = str.index(str.endIndex, offsetBy: HopConstants.HOP_SUB_PREFIX.count - str.count)
                let sub_str = str.suffix(from: index)
                
                return String(sub_str).base58DecodedData
        }
        
        public func getPri(auth:String) -> Data?{
                
                guard let cipher_data = self.cipher?.base58DecodedData else{
                        return nil
                }
                
                guard let pub_data = HopAccount.getPub(address: self.address) else{
                        return nil
                }
                
                guard let aes_key = HopAccount.aesKey(pubKey: pub_data, auth: auth) else{
                        return nil
                }
                
                let iv = cipher_data[...(HopConstants.HOP_WALLET_IVLEN - 1)]
                
                let ciph_data = cipher_data[HopConstants.HOP_WALLET_IVLEN...]
                do{
                        let decrypt:Array<UInt8> = try AES(key: aes_key,
                                              blockMode: CFB(iv: iv.bytes),
                                              padding:.noPadding).decrypt(ciph_data.bytes)
                        
                        return Data(decrypt)
                }catch let err{
                        NSLog(err.localizedDescription)
                        return nil
                }
        }
        
        public static func dataToPub(data:Data?)->String?{
                guard let d = data, d.count == 32, invalidAddr != d else{
                        return nil
                }
                
                return HopConstants.HOP_SUB_PREFIX + Base58.base58FromBytes(d.bytes)
        }
        
        public static func AddressToPort(addr:String) -> Int32{
                let hash = New32aHash.hash(addr)
                let (reminder, _) = hash.remainderReportingOverflow(dividingBy: HopConstants.SocketPortRange)
                return Int32(HopConstants.SocketPortInit + reminder)
        }
        
        public static func testCase(){
                let acc = NewAcc(auth: "123")!
                NSLog("address=>\(acc.address!)")
                NSLog("cipher=>\(acc.cipher!)")
                NSLog("pri=>\(acc.priKey!.toHexString())")
                
                let pri2 = acc.getPri(auth: "123")!
                NSLog("pri2=>\(pri2.toHexString())")
                let pub = getPub(address: acc.address!)!
                NSLog("pub=>\(pub.toHexString())")
        }
        
        public static func testCase2(){
                 let acc = HopAccount(addr: "HOjutVsvYzL5JvqbvTkWV5SqwkaQYqgmbfGnWxkzaZYef", cipher: "2o1PHRWYsC25uqbv42zvNhhHsRPFtWGo6CeCkdFRBQ63yLbEjkNGoJfoRMLom5JAbhc61SAmQ3XcPy3eMTVi6Q5XcSsz2b3ruRLsWMJojFrF4M")
                let pri2 = acc.getPri(auth: "123")!
                NSLog("pri2=>\(pri2.toHexString())")
                let pub = getPub(address: acc.address!)!
                NSLog("pub=>\(pub.toHexString())")
        }
        
        
        public static func testCase3(){
                let password = "123".data(using: .utf8)?.bytes
                var salt = Data(repeating: 0, count: 8)
                salt[0] = UInt8(4)
                let ss = salt[...3]
                NSLog("ss==\(ss.count)=>\(ss.toHexString())")
                let deriver = try? CryptoSwift.Scrypt(password: password!,
                                                    salt: salt.bytes,
                                                     dkLen: 32,
                                                     N: (1 << 15),
                                                     r: 8,
                                                     p: 1)
                               
               do {
                       let data = try deriver!.calculate()

                NSLog("deriver=>\(data.toHexString())")
                
               }catch let err{
                       NSLog(err.localizedDescription)
               }
        }
}
