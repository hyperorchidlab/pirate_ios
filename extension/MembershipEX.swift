//
//  CDMembership.swift
//  Pirate
//
//  Created by hyperorchid on 2020/10/7.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import web3swift

class MembershipEX:NSObject{
        
        public static var membership:CDMemberShip!
        public static var minerCredit:CDMinerCredit!
        
        public static func Membership(user:String, pool:String, miner:String) -> Bool{
                let dbContext = DataShareManager.privateQueueContext()
                var w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                    HopConstants.DefaultPaymenstService,
                                    user, pool)//"0xfa0628a247e35ba340eb1d4a058ab8a9755dd044"

                
                guard let result =  NSManagedObject.findOneEntity(HopConstants.DBNAME_MEMBERSHIP,
                                             where: w,
                                             context: dbContext) as? CDMemberShip else{
                        NSLog("--------->Invalid Membership user=\(user) pool=\(pool)")
                        return false
                }
                
                w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND minerID == %@", HopConstants.DefaultPaymenstService, user, miner)
                guard let mc = NSManagedObject.findOneEntity(HopConstants.DBNAME_MINERCREDIT,
                                                             where: w,
                                                             context: dbContext) as? CDMinerCredit else{
                        NSLog("--------->Invalid miner credit user=\(user) miner=\(miner)")
                        return false
                }
                NSLog("--------->\(result.toString())")
                membership = result
                
                NSLog("--------->\(mc.toString())")
                minerCredit = mc
                return true
        }
}

extension CDMemberShip{
        
        func toString() -> String{
                
                return "\nUserAccount =>{\nUserAddr=\(self.userAddr!)\n PoolAddr=\(self.poolAddr!)\n TokenBalance=\(self.tokenBalance)\n RemindPacket=\(self.packetBalance)\n  usedTraffic=\(self.usedTraffic)\n } "
        }
}

extension CDMinerCredit{
        
        public func toString()->String{
                return "{\nuserAddr=\(self.userAddr!)\nminerID=\(self.minerID!)\ninCharge=\(self.inCharge)\ncredit=\(self.credit)}"
        }
        
        
        func syncData() {
                let dbContext = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
        }
        
        public func update(json:JSON)throws{
                
                let rcp = ReceiptData(json: json)
                guard let tx = rcp.tx else{
                        throw HopError.rcpWire("No valid transaction data")
                }
                NSLog("--------->create rcp\n\(rcp.toString())")
                
                guard tx.verifyTx() == true else{
                        throw HopError.rcpWire("Signature verify failed for receipt")
                }
                guard self.userAddr?.lowercased() == tx.user?.lowercased(),
                      self.minerID?.lowercased() == tx.minerID?.lowercased() else {
                        throw HopError.rcpWire("Pool and user are not for me!")
                }
                
                NSLog("--------->********>User account before update\n\(self.toString())")
                defer {
                        NSLog("--------->++++++++>User account after update\n\(self.toString())")
                        self.syncData()
                }
                let credit = json["miner_credit"].int64 ?? 0
                if self.credit > credit{
                        return
                }
                
                self.credit = credit
        }
}
