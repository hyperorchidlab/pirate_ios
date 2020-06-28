//
//  HOPAdapter.swift
//  extension
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import NEKit
import CryptoSwift

class HOPAdapter: AdapterSocket {
        
        public static let MAX_BUFFER_SIZE = 1 << 16 - 1
        
        enum HopAdapterStatus {
                case invalid,
                connecting,
                readingACK,
                readingACK2,
                forwarding,
                stopped
                public var description: String {
                        switch self {
                        case .invalid:
                                return "invalid"
                        case .connecting:
                                return "connecting"
                        case .readingACK:
                                return "readingACK"
                        case .readingACK2:
                                return "readingACK2"
                        case .forwarding:
                                return "forwarding"
                        case .stopped:
                                return "stopped"
                        }
                }
        }
        
        var readHead:Bool = true
        public let serverHost: String
        public let serverPort: Int
        public let hopdelegate:MicroPayDelegate
        var internalStatus: HopAdapterStatus = .invalid
        var target:String?
        var salt:Data?
        var aesKey:AES?
        var objID:Int
        
        public init(serverHost: String,
                    serverPort: Int,
                    delegate d:MicroPayDelegate,
                    ID:Int) {
                self.serverHost = serverHost
                self.serverPort = serverPort
                self.hopdelegate = d
                self.objID = ID
                super.init()
        }
        
        override public func openSocketWith(session: ConnectSession) {
                super.openSocketWith(session: session)
                guard !isCancelled else {
                        return
                }
                
                self.target = "\(session.host):\(session.port)"
                NSLog("--------->[\(objID)]openSocketWith===target:[\(self.target!)]")
  
                internalStatus = .connecting
                do {
                        self.salt = Data.randomBytes(length: HopConstants.HOP_WALLET_IVLEN)!
                        let key = self.hopdelegate.AesKey()
                        self.aesKey = try AES(key: key,
                                              blockMode: CFB(iv: self.salt!.bytes),
                                              padding:.noPadding)
                        
                        try socket.connectTo(host: self.serverHost,
                                             port: Int(self.serverPort),
                                             enableTLS: false,
                                             tlsSettings: nil)
                } catch let error {
                        observer?.signal(.errorOccured(error, on: self))
                        disconnect()
                }
        }
        
        override public func didConnectWith(socket: RawTCPSocketProtocol) {
                guard let syn_data = self.hopdelegate.getSetupMsg(salt:self.salt!) else{
                        observer?.signal(.errorOccured(HopError.msg("invalid setup message to miner"), on: self))
                        disconnect()
                        return
                }
                
                internalStatus = .readingACK
                write(data: syn_data)
                socket.readData()
//                NSLog("--------->[\(objID)]didConnectWith status:[\(internalStatus.description)] ---")
        }

        override public func didRead(data: Data, from rawSocket: RawTCPSocketProtocol) {
//                NSLog("--------->[\(objID)]didRead=len=\(data.count) status:[\(internalStatus.description)] ---")
                do {
                switch internalStatus {
                        
                case .readingACK:

//                        NSLog("--------->[\(objID)]didRead msg:[\(String(data:data, encoding: .utf8) ?? "-")] ---")
                        let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
                        guard let Success = obj?["Success"] as? Bool, Success == true else{
                                throw HopError.minerErr("miner setup protocol failed")
                        }
                        
                        internalStatus = .readingACK2
                        let prob_data = try HopMessage.ProbMsg(target: self.target!)                        
                        write(data: prob_data)
                        socket.readDataTo(length: 4)
                        self.readHead = true
                        
                case .readingACK2:
                        if self.readHead{
                                try self.readLen(data: data)
                                return
                        }
                        let decoded_data = try self.readEncoded(data:data)
                        let obj = try JSONSerialization.jsonObject(with: decoded_data, options: []) as? [String:Any]
                        guard let Success = obj?["Success"] as? Bool, Success == true else{
                                throw HopError.minerErr("miner setup protocol failed")
                        }
                        
                        internalStatus = .forwarding
//                        NSLog("--------->[\(objID)] into forwarding")
                        observer?.signal(.readyForForward(self))
                        delegate?.didBecomeReadyToForwardWith(socket: self)
                        
                case .forwarding:
                        if self.readHead{
                                try readLen(data: data)
                                return
                        }
                       
                        let decode_data = try self.readEncoded(data: data)
                        observer?.signal(.readData(decode_data, on: self))
                        let size = decode_data.count
                        guard size > HOPAdapter.MAX_BUFFER_SIZE else{
                                delegate?.didRead(data: decode_data, from: self)
                                return
                        }
                        var idx = 0;
                        while idx < size{
                                var end = idx + HOPAdapter.MAX_BUFFER_SIZE
                                if end > size{
                                        end = size
                                }
                                delegate?.didRead(data: decode_data[idx..<end], from: self)
                                idx = end
                        }
                        
                       
                default:
                    return
                }
                }catch let err{
                        observer?.signal(.errorOccured(err, on: self))
                        disconnect()
                        NSLog("--------->[\(objID)] didRead err:\(err.localizedDescription)")
                }
        }

        override public func didWrite(data: Data?, by rawSocket: RawTCPSocketProtocol) {
//                NSLog("--------->[\(objID)]didWrite status:[\(internalStatus.description)] len=\(data?.count ?? 0)---")
                
                if internalStatus == .forwarding {
                    observer?.signal(.wroteData(data, on: self))
                    delegate?.didWrite(data: data, by: self)
                }
        }
        
        override open func didDisconnectWith(socket: RawTCPSocketProtocol) {
//                NSLog("--------->[\(objID)]didDisconnectWith status:[\(internalStatus.description)] ---")
                super.didDisconnectWith(socket: socket)
        }
        
        override open func disconnect(becauseOf error: Error? = nil) {
//                NSLog("--------->[\(objID)]disconnect=\(error?.localizedDescription ?? "<-e->")---status:[\(internalStatus.description)]---")
                super.disconnect(becauseOf: error)
        }
        
        func hopWrite(data:Data){do{
//                NSLog("--------->[\(objID)]hopWrite before msg:[\(String(data:data, encoding: .utf8) ?? "-")] ---")
//                NSLog("--------->[\(objID)]hopWrite before msg:[\(data.toHexString())] ---")
                let encode_data = try self.aesKey!.encrypt(data.bytes)
                
                let data_len = Int32(encode_data.count)
                let len_data = withUnsafeBytes(of: data_len.bigEndian, Array.init)
                var lv_data = Data(len_data)
                lv_data.append(contentsOf: encode_data)
                self.socket.write(data: lv_data)
                
//                NSLog("--------->[\(objID)]hopWrite after msg:[\(lv_data.toHexString())] ---")
                }catch let err{
                        observer?.signal(.errorOccured(err, on: self))
                        disconnect()
                }
        }
        override open func readData() {
                if internalStatus == .forwarding{
//                         NSLog("--------->[\(objID)]readData --forwarding-")
                        if self.readHead{
                                self.socket.readDataTo(length: 4)
                        }
                        return
                }
//                NSLog("--------->[\(objID)]readData ---")
                super.readData()
        }
        override open func write(data: Data) {
                if internalStatus == .readingACK2 || internalStatus == .forwarding{
                        self.hopWrite(data: data)
                        return
                }
                
//                NSLog("--------->[\(objID)]write msg:[\(String(data:data, encoding: .utf8) ?? data.toHexString())] ---")
                super.write(data: data)
        }
        
        
        func readLen(data:Data)throws{
                
                guard data.count == 4 else{
                        throw HopError.minerErr("parse crypted data length err:")
                }
                let b = data.bytes
                let len = Int(b[3]) | Int(b[2])<<8 | Int(b[1])<<16 | Int(b[0])<<24
                if len > HOPAdapter.MAX_BUFFER_SIZE{
                        throw HopError.minerErr("too big data len[\(len)]")
                }
                self.socket.readDataTo(length: len)
                self.readHead = false
                self.hopdelegate.CounterWork(size:len)
//                NSLog("--------->[\(objID)]readLen:[\(len)] and counter---")
        }
        
        func readEncoded(data:Data) throws-> Data {
//                NSLog("--------->[\(objID)]forwarding read crypt data-> before:[\(data.toHexString())] ---")
                guard let decode_data = try self.aesKey?.decrypt(data.bytes) else{
                        throw HopError.minerErr("miner undecrypt data")
                }
                self.readHead = true
                
//                NSLog("--------->[\(objID)]read1 crypt data-> after:[\(String.init(bytes: decode_data, encoding: .utf8) ?? "-")] ---")
//                NSLog("--------->[\(objID)]read2 crypt data-> after:[\(decode_data.toHexString())] ---")
                return Data(decode_data)
        }
}
