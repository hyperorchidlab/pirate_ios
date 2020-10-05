//
//  HopWallet.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//
import Foundation
import web3swift
import CryptoSwift
import Curve25519

public class HopWallet: NSObject, Codable {
        
        public static var WInst:HopWallet?
        
        public var version:Int = 0
        public var mainAddress:EthereumAddress?
        public var crypto:CryptoParamsV3?
        
        public var subAddress:String?
        public var subCipher:String?
        
        public var privateKey:HopKey?
        
        override init() {
                super.init()
        }
        
        public static func loadWallet(){
                let w_url = HopConstants.WalletPath()
                NSFileCoordinator().coordinate(readingItemAt: w_url, options: [], error: nil, byAccessor: { (new_url:URL) in
                        
                        do{
                                guard let data = try? Data.init(contentsOf: new_url) else{
                                        return
                                }
                                let decoder = JSONDecoder()
                                
                                HopWallet.WInst = try decoder.decode(HopWallet.self, from: data)
                                
                        }catch let err{
                                NSLog(err.localizedDescription)
                        }
                })
        }
        
        required public init(from decoder: Decoder) throws{
                let values = try decoder.container(keyedBy: CodingKeys.self)
                version = try values.decode(Int.self, forKey: HopWallet.CodingKeys.version)
                mainAddress = try values.decode(EthereumAddress.self, forKey: HopWallet.CodingKeys.mainAddress)
                crypto = try values.decode(CryptoParamsV3.self, forKey: HopWallet.CodingKeys.crypto)
                subAddress = try values.decode(String.self, forKey: HopWallet.CodingKeys.subAddress)
                subCipher = try values.decode(String.self, forKey: HopWallet.CodingKeys.subCipher)
        }
        
        public static func initWithPassword(auth:String, priKey:Data)throws -> CryptoParamsV3{
                
                guard let password = auth.data(using: .utf8)?.bytes else{
                        throw HopError.wallet("Convert pass word to data err:".locStr)
                }
                
                guard let salt = Data.randomBytes(length: 32) else{
                       throw HopError.wallet("Random salt err:".locStr)
                }
                
                guard let iv = Data.randomBytes(length: HopConstants.HOP_WALLET_IVLEN) else{
                       throw HopError.wallet("Random salt err:".locStr)
                }
                
                let _P = HopConstants.ETH_AES_PARAM
                
                let deriver = try CryptoSwift.Scrypt(password: password, salt: salt.bytes,
                                                      dkLen: _P.dkLen, N: _P.N, r: _P.R, p: _P.P)
                let key =  try deriver.calculate()
                        
                let encryptionKey = Array<UInt8>(key[0...15])
                let last16bytes =  Array<UInt8>(key[16...31])
                
                let aesCipher = try AES(key: encryptionKey, blockMode: CTR(iv: iv.bytes), padding: .noPadding)
                
                let encryptedKey = try aesCipher.encrypt(priKey.bytes)
                
                var dataForMAC = Data(last16bytes)
                dataForMAC.append(contentsOf: encryptedKey)
                
                let mac = dataForMAC.sha3(.keccak256)
                
                let cp = CipherParamsV3.init(iv: iv.toHexString())
                let kp = KdfParamsV3.init(salt: salt.toHexString(), dklen: _P.dkLen, n: _P.N, p: _P.P, r: _P.R, c: nil, prf: nil)
        
                let crypto = CryptoParamsV3.init(ciphertext: encryptedKey.toHexString(),
                                          cipher: HopConstants.ECSDA_AES_MODE,
                                        cipherparams: cp,
                                        kdf: "scrypt",
                                        kdfparams: kp,
                                        mac: mac.toHexString(),
                                        version: nil)
        
                return crypto
        }
        
        public static func NewWallet(auth:String) ->HopWallet?{
                do{
                        guard let main_pri = SECP256K1.generatePrivateKey() else{
                                return nil
                        }
                        
                        let wallet = HopWallet()
                        
                        wallet.crypto = try HopWallet.initWithPassword(auth: auth, priKey: main_pri)
                        wallet.version = HopConstants.HOP_WALLET_VERSION
                
                        guard let main_pub = Web3.Utils.privateToPublic(main_pri) else {
                                return nil
                        }
                        guard let addr = Web3.Utils.publicToAddress(main_pub) else {
                                return nil
                        }
                        wallet.mainAddress = addr
                
                        guard let hop_acc = HopAccount.NewAcc(auth: auth) else{
                                return nil
                        }
                        
                        wallet.subAddress = hop_acc.address
                        wallet.subCipher = hop_acc.cipher
                        wallet.privateKey = HopKey.init(main: main_pri, sub: hop_acc.priKey!)
                        hop_acc.priKey = nil
                        
                        return wallet
                }catch let err{
                        NSLog(err.localizedDescription)
                        return nil
                }
        }
        
        public func toJson() -> String? {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                do{
                        let data = try encoder.encode(self)
                        return String(data: data, encoding: .utf8)
                }catch let err{
                        NSLog(err.localizedDescription)
                        return nil
                }
        }
        
        public static func from(json:String)->HopWallet?{
                guard let data = json.data(using:.utf8) else{
                        return nil
                }
                let decoder = JSONDecoder()
                do{
                        return try decoder.decode(HopWallet.self, from: data)
                }catch let err{
                        NSLog(err.localizedDescription)
                        return nil
                }
        }
        
        
        public func saveToDisk(){
                
                let w_url = HopConstants.WalletPath()
                let fileCoordinator = NSFileCoordinator()
                
                fileCoordinator.coordinate(writingItemAt: w_url, options: [], error: nil) {
                        (new_url:URL) in
                        do {
                                guard let json = self.toJson() else{
                                        throw HopError.wallet("No json data to save".locStr)
                                }
                               
                               try json.data(using: .utf8)?.write(to: new_url)
                        }catch let err{
                                NSLog(err.localizedDescription)
                                return
                        }
                }
        }
        
        public func Open(auth:String) throws{
                
                guard  let subAddr = self.subAddress,
                        let subCip = self.subCipher else {
                        throw HopError.wallet("Empty account".locStr)
                }
                let hop_acc = HopAccount.init(addr: subAddr, cipher: subCip)
                guard let sub_pri = hop_acc.getPri(auth: auth) else{
                        throw HopError.wallet("Failed to open hop account".locStr)
                }
                
                guard let main_pri = try self.crypto?.derivePriKey(password:auth) else{
                        throw HopError.wallet("Failed to open main adress".locStr)
                }
                
                self.privateKey = HopKey(main: main_pri, sub: sub_pri)
        }
        
        public func Close(){
                self.privateKey = nil
        }
        
        public static func mainSign(data:Data, key:Data) ->Data?{
                let hash = data.sha3(.keccak256)
//                NSLog("--------->hash==>\(hash.toHexString())")
                let (compressedSignature, _) = SECP256K1.signForHash(hash: hash, privateKey: key)
                return compressedSignature
        }
        
        public func IsOpen()->Bool{
                return self.privateKey != nil
        }
}


extension HopWallet{
        
        enum CodingKeys : String, CodingKey{
                case version
                case mainAddress
                case crypto
                case subAddress
                case subCipher
                case privateKey = "_"
        }
        
        public func encode(to encoder: Encoder) throws{
                var container = encoder.container(keyedBy: CodingKeys.self)

                try container.encode(version, forKey: .version)
                try container.encode(mainAddress, forKey: .mainAddress)
                try container.encode(crypto, forKey: .crypto)
                try container.encode(subAddress, forKey: .subAddress)
                try container.encode(subCipher, forKey: .subCipher)
        }
}
