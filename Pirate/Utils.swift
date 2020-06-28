//
//  Utils.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import BigInt
import MBProgressHUD

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

extension UIViewController {
        
        func showIndicator(withTitle title: String, and Description:String) {DispatchQueue.main.async {
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.detailsLabel.text = Description
                Indicator.show(animated: true)
        }}
        
        func createIndicator(withTitle title: String, and Description:String) -> MBProgressHUD{
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.detailsLabel.text = Description
                return Indicator
        }
        
        func hideIndicator() {DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
        }}
        
        func ShowPassword(complete:@escaping((String?, Bool) -> Void)){
               DispatchQueue.main.async {
                let alert = UIAlertController(title: "Password Confirmation!".locStr, message: nil, preferredStyle: .alert)
                       
                       var pass_word:String? = nil
                       
                       alert.addAction(UIAlertAction(title: "Cancel".locStr, style: .cancel, handler: { action in
                               complete(nil, false)
                       }))

                       alert.addTextField(configurationHandler: { textField in
                           textField.placeholder = "password".locStr
                       })

                       
                       alert.addAction(UIAlertAction(title: "OK".locStr, style: .default, handler: { action in
                           pass_word = alert.textFields?.first?.text
                               complete(pass_word, true)
                       }))

                       self.present(alert, animated: true)
               }
        }
        
        func ShowTips(msg:String){
                DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Tips!".locStr, message: msg, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                }
        }
        
        func showConfirm(msg:String, yesHandler:@escaping (() -> Void) , noHandler:(() -> Void)? = nil){
                
                DispatchQueue.main.async {
                        
                        let ac = UIAlertController(title: "Are you sure?".locStr, message: msg, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "YES".locStr, style: .default, handler: { (alert) in
                                yesHandler()
                        }))
                        ac.addAction(UIAlertAction(title: "NO".locStr, style: .default, handler: {(alert) in
                                noHandler?()
                        }))
                        self.present(ac, animated: true)
               }
        }
}
extension MBProgressHUD{
        
        func setDetailText(msg:String) {
                 DispatchQueue.main.async {
                        self.detailsLabel.text = msg
                }
        }
}
