//
//  BasUtil.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/3.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import SwiftSocket
import web3swift

public class BasUtil{
        
        public static var BacCache:[String:String] = [:]
        public static let queue = DispatchQueue(label: "BAS_QUERY", qos: .utility)
        
        public static func Query(addr:String)->String?{
                var resultIP:String? = nil
                defer{
                        NSLog("--------->Bas result:[\(addr)=>\(resultIP ?? "<->")]")
                }
                
                resultIP = BacCache[addr]
                if resultIP != nil{
                        return resultIP
                }
                
                var ba_data:String?
                if HopAccount.IsHopID(str:addr){
                        ba_data = addr.data(using: .utf8)?.base64EncodedString()
                }else{
                        ba_data = EthereumAddress(addr)?.addressData.base64EncodedString()
                }
                
                do {
                        let client = UDPClient(address: HopConstants.DefaultDnsIP,
                                               port: Int32(HopConstants.DefaultBasPort))
                        
                        let req = ["ba": ba_data!]
                        if (!JSONSerialization.isValidJSONObject(req)) {
                                    NSLog("--------->is not a valid json object")
                                    return nil
                        }
                        
                        let data = try JSONSerialization.data(withJSONObject: req, options: [])
                        let ret = client.send(data: data)
                        guard ret.isSuccess else{
                                NSLog("--------->\(ret.error?.localizedDescription ?? "<->")")
                                return nil
                        }
                        DispatchQueue.global().asyncAfter(deadline: .now() + HopConstants.TimeOutConn) {
                                NSLog("--------->Prepare to close Query BAS(\(addr)")
                                client.close()
                        }
                        let (rdata, _, _) = client.recv(HopConstants.UDPBufferSize)
                        
                        guard let rec_data = rdata else{
                                return nil
                        }
                        
                        guard let query_ret = try JSONSerialization.jsonObject(with: Data(rec_data),
                                                                               options: .mutableContainers) as? [String:Any] else{
                                        return nil
                        }
                        
                        NSLog("\(String(describing: query_ret))")
                        guard let typ = query_ret["networkType"] as? Int, typ  != 1 else{
                                NSLog("--------->No such bas[\(addr)]")
                                return nil
                        }
                        
                        guard let ip_data = query_ret["networkAddr"] as? String else{
                                return nil
                        }
                        guard let decodedData = Data(base64Encoded: ip_data) else{
                                return nil
                        }
                        guard let decodedString = String(data: decodedData, encoding: .utf8) else{
                                return nil
                        }
                        resultIP = decodedString
                        BacCache[addr] = resultIP
                        return resultIP
                }catch let err{
                        NSLog(err.localizedDescription)
                        return nil
                }
        }
        
        public static func Ping(addr:String)->(String, TimeInterval){
                guard let ip = BasUtil.Query(addr: addr) else{
                        return ("", -1)
                }
                return (ip, Ping(addr: addr, withIP: ip))
        }
        
        public static func Ping(addr:String, withIP ip:String)->TimeInterval{do{
                let current = Date()
                let port = HopAccount.AddressToPort(addr:addr)
                let conn = UDPClient(address: ip, port: Int32(port))
                
                
                let req = ["PayLoad": addr]
                let data = try JSONSerialization.data(withJSONObject: req, options: [])
                let ret = conn.send(data: data)
                guard  ret.isSuccess else {
                        return -1
                }

                DispatchQueue.global().asyncAfter(deadline: .now() + HopConstants.TimeOutConn) {
                        NSLog("--------->Connection timeout[Ping[\(addr)]")
                        conn.close()
                }
                
                let (rec_data, _, _) = conn.recv(HopConstants.UDPBufferSize)
                guard let rd = rec_data else {
                        return -1
                }
                guard let ping_resut = try JSONSerialization.jsonObject(with: Data(rd),
                                                              options: .mutableContainers) as? [String:Any] else{
                       return -1
                }
                guard let Success = ping_resut["Success"] as? Bool, Success == true else{
                        return -1
                }
                let ping  = Date().timeIntervalSince(current) * 1000
                return ping
                
        }catch let err{
                NSLog(err.localizedDescription)
                return -1
                }
        }
}
