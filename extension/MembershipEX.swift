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

class MembershipEX:NSObject{
        
        public static var membership:CDMemberShip!
        
        public static func Membership(user:String, pool:String) -> Bool{
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                    HopConstants.DefaultPaymenstService,
                                    user,
                                    pool)

                let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MEMBERSHIP)
                request.predicate = w
                guard let result = try? dbContext.fetch(request).last as? CDMemberShip else{
                        return false
                }
                
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
                
                guard tx.verifyTx() == true else{
                        throw HopError.rcpWire("Signature verify failed for receipt")
                }
                guard self.userAddr?.lowercased() == tx.from?.lowercased(),
                      self.poolAddr?.lowercased() == tx.to?.lowercased() else {
                        throw HopError.rcpWire("Pool and user are not for me!")
                }
                
                NSLog("--------->********>User account before update\n\(self.toString())")
                defer {
                        NSLog("--------->++++++++>User account after update\n\(self.toString())")
                        self.syncData()
                }
                
                if self.epoch != tx.epoch!{
                        self.needReload = true
                        throw HopError.rcpWire("epoch are not same, need reload from eth")
                }
                
                if self.microNonce + 1 > tx.nonce!{
                        NSLog("--------->Receipt's nonce[\(tx.nonce!)] is too low[\(self.microNonce)]")
                        return
                }
                
                let next_credit = tx.credit! + tx.amount!
                let cur_credit = self.credit + self.inRecharge
                if cur_credit > next_credit{
                        NSLog("--------->Lower packet receipt cur=[\(cur_credit)] next=[\(next_credit)]")
                        return
                }
                
                self.credit = next_credit
                self.microNonce = tx.nonce!
                self.curTXHash = nil
                self.inRecharge = 0
        }
        
        func toString() -> String{
                
                return "\nUserAccount =>{\nUserAddr=\(self.userAddr!)\n PoolAddr=\(self.poolAddr!)\n Nonce=\(self.nonce)\n Epoch=\(self.epoch) \n TokenBalance=\(self.tokenBalance)\n RemindPacket=\(self.packetBalance)\n Expire=\(self.expire ?? "<--->")\n Credit=\(self.credit)  \n MicroNonce=\(self.microNonce)\n InRecharge=\(self.inRecharge)\n CurTXHash=\(self.curTXHash ?? "---")\n } "
        }
        
        func syncData() {
                let dbContext = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
        }
}
