//
//  HopError.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation

public enum HopError: Error,LocalizedError {

        case wallet(String)
        case eth(String)
        case dataBase(String)
        case rcpWire(String)
        case txWire(String)
        case minerErr(String)
        case msg(String)
        case hopProtocol(String)
        
        public var errorDescription: String? {
        
        switch self {
        case .wallet(let err): return "Hop wallet operation err:=>[\(err)]"
        case .eth(let err): return "Operation with ethereum err:=>[\(err)]"
        case .dataBase(let err): return "Core Data operation err:=>[\(err)]"
        case .rcpWire(let err): return "Receipt Wire err:=>[\(err)]"
        case .txWire(let err): return "Transaction Wire err:=>[\(err)]"
        case .minerErr(let err): return "Miner Connection err:=>[\(err)]"
        case .msg(let err): return "Message create err:=>[\(err)]"
        case .hopProtocol(let err): return "Hyper Orchid Protocol err:=>[\(err)]"
        }
    }
}
