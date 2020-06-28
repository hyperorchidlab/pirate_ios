//
//  MinerData.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/2.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt

public class MinerData:NSObject, NSCoding{
        
        public func encode(with coder: NSCoder) {
                coder.encode(Address, forKey: "Address")
                coder.encode(ID, forKey: "ID")
                coder.encode(Zone, forKey: "Zone")
        }
        
        
        public static var MinerDetailsDic:[String:MinerData] = [:]
        
        public var Address:String = ""
        public var ID:Int64 = 0
        public var Zone:String?
        public var Ping:Double?
        public var IP:String?
        
        public override init() {
                super.init()
        }
        
        public convenience init(_ ethData:[String:Any]){
                self.init()
                Address = HopAccount.dataToPub(data: ethData["subAddr"] as? Data) ?? ""
                ID = ethData["ID"] as? Int64 ?? 0
                Zone = String.init(data: (ethData["zone"] as? Data ?? Data()), encoding: .utf8)
        }
        
        public static func fullFill(data:Data?){
                guard let d = data else{
                        return
                }
                
                guard let dic = NSKeyedUnarchiver.unarchiveObject(with: d) as? [MinerData] else{
                        return
                }
                
                MinerDetailsDic.removeAll()
                for md in dic{
                        MinerDetailsDic[md.Address] = md
                }
        }
        
        public static func serialize(miners:[MinerData]) -> Data?{
                return NSKeyedArchiver.archivedData(withRootObject: miners)
        }
        
        required public init(coder aDecoder: NSCoder)  {
                super.init()
                Address = aDecoder.decodeObject(forKey: "Address") as? String ?? ""
                ID = aDecoder.decodeObject(forKey: "ID") as? Int64 ?? 0
                Zone = aDecoder.decodeObject(forKey: "Zone") as? String ?? ""
        }
}
