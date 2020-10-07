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
        var coreData:CDMemberShip?
        
        public static func updateByReceipt(data:Data){
                let json = JSON(data)
                let rcp = ReceiptData(json: json)
        }
}

extension CDMemberShip{
        
        func updateByReceipt(rcp:ReceiptData){
        }
}
