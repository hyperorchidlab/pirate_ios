//
//  UserData.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/27.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt
import CoreData
import web3swift

public class UserData:NSObject{
        public var Nonce:BigUInt = 0
        public var TokenBalance:BigUInt = 0
        public var RemindPacket:BigUInt = 0
        public var Expire:BigUInt = 0
        public var Epoch:BigUInt = 0
        public var ClaimedAmount:BigUInt = 0
        public var ClaimedMicNonce:BigUInt = 0
        
        public override init() {
                super.init()
        }
        
        public init(_ dict:[String:Any]) {
                self.Nonce = dict["nonce"] as! BigUInt
                self.TokenBalance = dict["tokenBalance"] as! BigUInt
                self.RemindPacket = dict["remindPacket"] as! BigUInt
                self.Expire = dict["expiration"] as! BigUInt
                self.Epoch = dict["epoch"] as! BigUInt
                self.ClaimedAmount = dict["claimedAmount"] as! BigUInt
                self.ClaimedMicNonce = dict["claimedMicNonce"] as! BigUInt
        }
        
        public func toString()->String{
                
                return "\n UserData=>{\n Nonce=\(Nonce) \n TokenBalance=\(TokenBalance) \n RemindPacket=\(RemindPacket) \n Expire=\(Expire) \n Epoch=\(Epoch) \n ClaimedAmount=\(ClaimedAmount) \n ClaimedMicNonce=\(ClaimedMicNonce) \n}"
        }
}
