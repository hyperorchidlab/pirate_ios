//
//  Utils.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import BigInt

class Utils: NSObject {
        
        public static var Domains:Dictionary<String, NSObject>!
        public static var JavaScriptString = ""
        private override init() {
                super.init()
        }
        //TODO:: throw
        static func initDomains() {
                guard let url = Bundle.main.path(forResource: "gfw", ofType: "plist") else{
                        return
                }
                guard let dic = NSDictionary(contentsOfFile: url) else{
                        return
                }
                Utils.Domains = (dic as! Dictionary<String, NSObject>)
        } 
        
        static func getJavascriptProxyForRules (domains:Array<String>, address:String, port:String) -> String {
            
            if domains.count == 0 {
                return "function FindProxyForURL(url, host) { return \"DIRECT\";}"
            }
            else {
                
                //forced URLs to go through VPN (right now just IP address to show to user)
                let forcedVPNConditions = "dnsDomainIs(host, \"ip.confirmedvpn.com\")"
                
                var conditions = ""
                for (index, domain) in domains.enumerated() {
                    if index > 0 {
                        conditions = conditions + " || "
                    }
                    let formattedDomain = domain.replacingOccurrences(of: "*.", with: "")
                        NSLog("formattedDomain=\(formattedDomain)")
                    conditions = conditions + "dnsDomainIs(host, \"" + formattedDomain + "\")"
                }
                
                return "function FindProxyForURL(url, host) { if (\(forcedVPNConditions)) { return \"DIRECT\";} else if (\(conditions)) { return \"PROXY \(address):\(port); DIRECT\"; } return \"DIRECT\";}"
            }
        }
        
        static func generateQRCode(from message: String) -> CIImage? {
                
                guard let data = message.data(using: .utf8) else{
                        return nil
                }
                
                guard let qr = CIFilter(name: "CIQRCodeGenerator",
                                        parameters: ["inputMessage":
                                                data, "inputCorrectionLevel":"H"]) else{
                        return nil
                }
                
                let qrImage = qr.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
                return qrImage
        }
}

public func PostNoti(_ namedNoti:Notification){
        NotificationCenter.default.post(namedNoti)
}

extension Data{
        
        public func ToInt() -> Int{
                let b = self.bytes
                let len = Int(b[3]) | Int(b[2])<<8 | Int(b[1])<<16 | Int(b[0])<<24
                return len
        }
}
        
public func DataWithLen(data:Data) -> Data {
        let data_len = Int32(data.count)
        let len_data = withUnsafeBytes(of: data_len.bigEndian, Array.init)
        var lv_data = Data(len_data)
        lv_data.append(data)
        return lv_data
}

extension BigUInt{
        
        public init?(_ data: Data?){
                
                guard let d = data else{
                        return nil
                }
                self.init(d)
        }
        
        public init(_ data: Data?, defaultValue:BigUInt){
                
                guard let d = data else{
                        self = defaultValue
                        return
                }
                self.init(d)
        }
        
        public func ToPackets() ->String{
                
                let ss = Double(self)
                
                if ss > 1e12{
                        return String.init(format: "%.2f T", (ss / 1e12))
                }
                if ss > 1e9{
                        return String.init(format: "%.2f G", (ss / 1e9))
                }
                if ss > 1e6{
                        return String.init(format: "%.2f M", (ss / 1e6))
                }
                if ss > 1000{
                        return String.init(format: "%.2f M", (ss / 1000))
                }
                
                return "\(self) B"
        }
        
        public func ToCoin(decimal:BigUInt = HopConstants.DefaultTokenDecimal) -> String{
                let val = Double(self)/Double(decimal)
                return String.init(format: "%.4f", val)
        }
        
        public func IntV32() -> Int32{
                return Int32(self)
        }
        
        public func IntV64() -> Int64{
                return Int64(self)
        }
        
        public func DoubleV() -> Double{
                return Double(self)
        }
}
extension Int64{
        
        public func ToPackets() ->String{
                       
               let ss = Double(self)
               
               if ss > 1e12{
                       return String.init(format: "%.2f T", (ss / 1e12))
               }
               if ss > 1e9{
                       return String.init(format: "%.2f G", (ss / 1e9))
               }
               if ss > 1e6{
                       return String.init(format: "%.2f M", (ss / 1e6))
               }
               if ss > 1000{
                       return String.init(format: "%.2f M", (ss / 1000))
               }
               
               return "\(self) B"
       }
       
       public func ToCoin(decimal:BigUInt = HopConstants.DefaultTokenDecimal) -> String{
               let val = Double(self)/Double(decimal)
               return String.init(format: "%.4f", val)
       }
}

extension Formatter {
    static let date = DateFormatter()
}

extension Date {
    var stringVal : String {
        Formatter.date.calendar = Calendar(identifier: .iso8601)
        Formatter.date.timeZone = .current
        Formatter.date.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSZZZZZ"
        return Formatter.date.string(from: self)
    }
}

extension Double{
        public func ToPackets() ->String{
                
                if self >= 1e12{
                        return String.init(format: "%.2f T", (self / 1e12))
                }
                if self >= 1e9{
                        return String.init(format: "%.2f G", (self / 1e9))
                }
                if self >= 1e6{
                        return String.init(format: "%.2f M", (self / 1e6))
                }
                if self >= 1000{
                        return String.init(format: "%.2f M", (self / 1000))
                }
                
                return "\(self) B"
        }
        
        public func ToCoin(decimal:BigUInt = HopConstants.DefaultTokenDecimal) -> String{
                let val = self/Double(decimal)
                return String.init(format: "%.4f", val)
        }
        
        public func ToCoinUnit(decimal:BigUInt = HopConstants.DefaultTokenDecimal) -> Double{
                return self/Double(decimal)
        }
}

extension String {
        var locStr:String {
                return NSLocalizedString(self, comment: "")
        }
        
        func isValidIP() -> Bool {
                let parts = self.split(separator: ".")// .componentsSeparatedByString(".")
                let nums = parts.compactMap { Int($0) }
            return parts.count == 4 && nums.count == 4 && nums.filter { $0 >= 0 && $0 < 256}.count == 4
        }
}
