//
//  HOPAdapterFactory.swift
//  extension
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import NEKit

class HOPAdapterFactory: AdapterFactory {
        let miner: String
        let serverIP: String
        let serverPort: Int
        let delegate:MicroPayDelegate
        var objID:Int = 0
        
        public init?(miner: String, delegate d:MicroPayDelegate) {
                self.miner = miner
                guard let ip = BasUtil.Query(addr: miner) else{
                        return nil
                }
                self.serverIP = ip
                self.serverPort = Int(HopAccount.AddressToPort(addr: miner))
                self.delegate = d
        }
        
        override open func getAdapterFor(session: ConnectSession) -> AdapterSocket {
                objID += 1
                let adapter = HOPAdapter(serverHost: serverIP,
                                         serverPort: serverPort,
                                         delegate:self.delegate,
                                         ID:objID)
                adapter.socket = RawSocketFactory.getRawSocket()
                return adapter
        }
}
