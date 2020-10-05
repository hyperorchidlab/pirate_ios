//
//  HopConstants.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt
public struct ScryptParam {
        var dkLen:Int
        var N:Int
        var R:Int
        var P:Int
        var S:Int
}

public struct HopConstants {
        
        static public let EthScanUrl = "https://ropsten.etherscan.io/tx/"//https://ropsten.etherscan.io///etherscan.io
        static public let DefaultDnsIP = "198.13.44.159"//47.242.11.173//198.13.44.159
        static public let DefaultBasPort = 8853
        static public let ReceiptSyncPort = 32021
        static public let TxReceivePort = 32020
        static public let DefaultRCPTimeOut = 4
        static public let RCPKeepAlive = TimeInterval(30)
        static public let RechargePieceSize  = 1 << 22 //4M
        static public let TimeOutConn = 4.0
        
        public static let UDPBufferSize = 10240
        static public let SocketPortInit  = UInt32(52000)
        static public let SocketPortRange = UInt32(12000)
        
        static public let GroupImageUrl = "https://hopwesley.github.io/group.jpg"
        static public let DefaultTokenAddr = "0xAd44c8493dE3FE2B070f33927A315b50Da9a0e25"
        static public let DefaultPaymenstService = "0x4291d9Ff189D90Ba875E0fc1Da4D602406DD7D6e"
        static public let DefaultInfruaToken = "f3245cef90ed440897e43efc6b3dd0f7"
        static public let DefaultServicePrice = Int64(1000)
        
        static public let DefaultApplyFreeAddr = "0xE4d20a76c18E73ce82035ef43e8C3ca7Fd94035E"
        static public let DefaultTokenDecimal = BigUInt(1e18)
        
        static public let DefaultTokenDecimal2 = Double(1e18)
        
        static public let ECSDA_AES_MODE = "aes-128-ctr"
        static public let HOP_SUB_PREFIX = "HO"
        static public let HOP_WALLET_VERSION = 1
        static public let HOP_WALLET_IVLEN = 16
        static public let HOP_WALLET_FILENAME = "wallet.json"
        static public let ETH_AES_PARAM = ScryptParam(dkLen: 32, N: 1 << 18, R:8, P:1, S:0)
        static public let HOP_AES_PARAM = ScryptParam(dkLen: 32, N: 1 << 15, R:8, P:1, S:8)
        
        static public let DBNAME_POOL_DETAILS = "CDPoolData"
        static public let DBNAME_VERSION = "CDVersionManager"
        static public let DBNAME_SETTING = "CDSystemSettings"
        static public let DBNAME_UserAccount = "CDUserAccount"
        static public let DBNAME_LocalSetting = "CDCurSettings"
        
        static public let DBNAME_WALLET = "CDWallet"
        static public let DBNAME_APPSETTING = "CDAppSetting"
        static public let DBNAME_TRASACTION = "CDTransaction"
        static public let DBNAME_POOL = "CDPool"
        static public let DBNAME_MINER = "CDMiner"
        static public let DBNAME_MEMBERSHIP = "CDMemberShip"
        
        
        static let NOTI_DNS_CHANGED = Notification.init(name: Notification.Name("NOTI_DNS_CHANGED"))
        static let NOTI_TX_STATUS_CHANGED = Notification.init(name: Notification.Name("NOTI_TX_STATUS_CHANGED"))
        static let NOTI_POOL_CACHE_LOADED = Notification.init(name: Notification.Name("NOTI_POOL_CACHE_LOADED"))
        static let NOTI_MEMBERSHIP_SYNCED = Notification.init(name: Notification.Name("NOTI_MEMBERSHIP_SYNCED"))
        static let NOTI_MEMBERSHIPL_CACHE_LOADED = Notification.init(name: Notification.Name("NOTI_MEMBERSHIPL_CACHE_LOADED"))
        static let NOTI_WALLET_CHANGED = Notification.init(name: Notification.Name("NOTI_WALLET_CHANGED"))
        static let NOTI_POOL_INUSE_CHANGED = Notification.init(name: Notification.Name("NOTI_POOL_INUSE_CHANGED"))
        static let NOTI_MINER_CACHE_LOADED = Notification.init(name: Notification.Name("NOTI_MINER_CACHE_LOADED"))
        static let NOTI_MINER_SYNCED = Notification.init(name: Notification.Name("NOTI_MINER_SYNCED"))
        static let NOTI_MINER_INUSE_CHANGED = Notification.init(name: Notification.Name("NOTI_MINER_INUSE_CHANGED"))
        
        static public func WalletPath() -> URL{
                let base = DataShareManager.sharedInstance.containerURL
               return base.appendingPathComponent(HOP_WALLET_FILENAME, isDirectory: false)
        }
        
        static public let TelegramIPRange = ["149.154.160.0/22",
                                                "149.154.164.0/22",
                                                "91.108.4.0/22",
                                                "91.108.56.0/22",
                                                "91.108.8.0/22",
                                                "95.161.64.0/20",
                                                "149.154.171.0/24"]
        static public let NetflixIPRange = [
                "108.175.32.0/20",
                "185.2.220.0/22",
                "185.9.188.0/22",
                "192.173.127.0/24",
                "192.173.64.0/18",
                "192.173.68.0/24",
                "192.173.70.0/24",
                "192.173.72.0/24",
                "192.173.73.0/24",
                "192.173.74.0/24",
                "192.173.75.0/24",
                "192.173.76.0/24",
                "192.173.77.0/24",
                "192.173.78.0/24",
                "192.173.79.0/24",
                "192.173.83.0/24",
                "192.173.84.0/24",
                "198.38.100.0/24",
                "198.38.108.0/24",
                "198.38.109.0/24",
                "198.38.110.0/24",
                "198.38.111.0/24",
                "198.38.112.0/24",
                "198.38.113.0/24",
                "198.38.114.0/24",
                "198.38.115.0/24",
                "198.38.120.0/24",
                "198.38.121.0/24",
                "198.38.122.0/24",
                "198.38.96.0/19",
                "198.38.98.0/24",
                "198.38.99.0/24",
                "198.45.48.0/20",
                "198.45.48.0/24",
                "198.45.49.0/24",
                "198.45.50.0/24",
                "198.45.56.0/24",
                "208.75.76.0/22",
                "23.246.0.0/18",
                "23.246.10.0/24",
                "23.246.11.0/24",
                "23.246.14.0/24",
                "23.246.15.0/24",
                "23.246.16.0/24",
                "23.246.17.0/24",
                "23.246.20.0/24",
                "23.246.2.0/24",
                "23.246.21.0/24",
                "23.246.26.0/24",
                "23.246.27.0/24",
                "23.246.30.0/24",
                "23.246.3.0/24",
                "23.246.31.0/24",
                "23.246.36.0/24",
                "23.246.38.0/24",
                "23.246.39.0/24",
                "23.246.41.0/24",
                "23.246.42.0/24",
                "23.246.44.0/24",
                "23.246.45.0/24",
                "23.246.46.0/24",
                "23.246.47.0/24",
                "23.246.48.0/24",
                "23.246.49.0/24",
                "23.246.50.0/24",
                "23.246.51.0/24",
                "23.246.52.0/24",
                "23.246.54.0/24",
                "23.246.55.0/24",
                "23.246.56.0/24",
                "23.246.57.0/24",
                "23.246.58.0/24",
                "23.246.59.0/24",
                "23.246.6.0/24",
                "23.246.7.0/24",
                "37.77.184.0/21",
                "37.77.186.0/24",
                "37.77.187.0/24",
                "37.77.188.0/24",
                "37.77.189.0/24",
                "45.57.0.0/17",
                "45.57.0.0/24",
                "45.57.100.0/24",
                "45.57.10.0/24",
                "45.57.101.0/24",
                "45.57.102.0/24",
                "45.57.1.0/24",
                "45.57.103.0/24",
                "45.57.11.0/24",
                "45.57.12.0/24",
                "45.57.13.0/24",
                "45.57.14.0/24",
                "45.57.15.0/24",
                "45.57.16.0/24",
                "45.57.17.0/24",
                "45.57.18.0/24",
                "45.57.19.0/24",
                "45.57.20.0/24",
                "45.57.2.0/24",
                "45.57.21.0/24",
                "45.57.22.0/24",
                "45.57.23.0/24",
                "45.57.28.0/24",
                "45.57.29.0/24",
                "45.57.3.0/24",
                "45.57.36.0/24",
                "45.57.37.0/24",
                "45.57.4.0/24",
                "45.57.44.0/24",
                "45.57.45.0/24",
                "45.57.48.0/24",
                "45.57.49.0/24",
                "45.57.5.0/24",
                "45.57.56.0/24",
                "45.57.58.0/24",
                "45.57.59.0/24",
                "45.57.60.0/24",
                "45.57.6.0/24",
                "45.57.62.0/24",
                "45.57.63.0/24",
                "45.57.64.0/24",
                "45.57.65.0/24",
                "45.57.68.0/24",
                "45.57.69.0/24",
                "45.57.70.0/24",
                "45.57.7.0/24",
                "45.57.71.0/24",
                "45.57.72.0/24",
                "45.57.73.0/24",
                "45.57.74.0/24",
                "45.57.75.0/24",
                "45.57.78.0/24",
                "45.57.79.0/24",
                "45.57.80.0/24",
                "45.57.81.0/24",
                "45.57.82.0/24",
                "45.57.83.0/24",
                "45.57.88.0/24",
                "45.57.89.0/24",
                "45.57.95.0/24",
                "45.57.98.0/24",
                "45.57.99.0/24",
                "64.120.128.0/17",
                "66.197.128.0/17",
                "69.53.224.0/19",
                "69.53.225.0/24",
                "69.53.226.0/24",
                "69.53.228.0/24",
                "69.53.242.0/24"
        ]
}
