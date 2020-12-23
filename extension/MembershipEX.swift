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
        
        public static func Membership(user:String, pool:String) -> Bool{
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                    HopConstants.DefaultPaymenstService,
                                    user, pool)//"0xfa0628a247e35ba340eb1d4a058ab8a9755dd044"

                
                guard let result =  NSManagedObject.findOneEntity(HopConstants.DBNAME_MEMBERSHIP,
                                             where: w,
                                             context: dbContext) as? CDMemberShip else{
                        NSLog("--------->Invalid Membership user=\(user) pool=\(pool)")
                        return false
                }
                
                NSLog("--------->\(result.toString())")
                membership = result
                return true
        }
}

extension CDMemberShip{
        //TODO::need a big check
        func updateByReceipt(data:Data) throws{
                
                let json = JSON(data)
                let rcp = ReceiptData(json: json)
                guard let tx = rcp.tx else{
                        throw HopError.rcpWire("No valid transaction data")
                }
                NSLog("--------->create rcp\n\(rcp.toString())")
                
                guard tx.verifyTx() == true else{
                        throw HopError.rcpWire("Signature verify failed for receipt")
                }
                guard self.userAddr?.lowercased() == tx.user?.lowercased(),
                      self.poolAddr?.lowercased() == tx.pool?.lowercased() else {
                        throw HopError.rcpWire("Pool and user are not for me!")
                }
                
                NSLog("--------->********>User account before update\n\(self.toString())")
                defer {
                        NSLog("--------->++++++++>User account after update\n\(self.toString())")
                        self.syncData()
                }
//                
//                if self.epoch != tx.epoch!{
//                        self.needReload = true
//                        throw HopError.rcpWire("epoch are not same, need reload from eth")
//                }
//                
//                if self.microNonce + 1 > tx.nonce!{
//                        NSLog("--------->Receipt's nonce[\(tx.nonce!)] is too low[\(self.microNonce)]")
//                        return
//                }
//                
//                let next_credit = tx.credit! + tx.amount!
//                let cur_credit = self.credit + self.inRecharge
//                if cur_credit > next_credit{
//                        NSLog("--------->Lower packet receipt cur=[\(cur_credit)] next=[\(next_credit)]")
//                        return
//                }
//                
//                self.credit = next_credit
//                self.microNonce = tx.nonce!
//                self.curTXHash = nil
//                self.inRecharge = 0
        }
        
        func toString() -> String{
                
                return "\nUserAccount =>{\nUserAddr=\(self.userAddr!)\n PoolAddr=\(self.poolAddr!)\n TokenBalance=\(self.tokenBalance)\n RemindPacket=\(self.packetBalance)\n  usedTraffic=\(self.usedTraffic)\n inRecharge=\(self.inRecharge)\n } "
        }
        
        func syncData() {
                let dbContext = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
        }
}
