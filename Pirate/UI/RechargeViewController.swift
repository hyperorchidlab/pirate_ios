//
//  RechargeViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import web3swift
import BigInt
import MBProgressHUD

class RechargeViewController: UIViewController {
        
        @IBOutlet weak var packetPrice: UILabel!
        @IBOutlet weak var TokenNoTF: UITextField!
        @IBOutlet weak var tokenBalance: UILabel!
        @IBOutlet weak var currentTokenName2: UILabel!
        @IBOutlet weak var currentTokenName1: UILabel!
        
        @IBOutlet weak var backFor20G: UIView!
        @IBOutlet weak var backFor8G: UIView!
        @IBOutlet weak var backFor5G: UIView!
        @IBOutlet weak var backFor2G: UIView!
        @IBOutlet weak var backFor1G: UIView!
        @IBOutlet weak var backFor500M: UIView!
        
        @IBOutlet weak var PacketForHalfHop: UILabel!
        @IBOutlet weak var PacketFor1Hop: UILabel!
        @IBOutlet weak var PacketFor2Hop: UILabel!
        @IBOutlet weak var PacketFor5Hop: UILabel!
        @IBOutlet weak var PacketFor8Hop: UILabel!
        @IBOutlet weak var PacketFor20Hop: UILabel!
        
        
        var poolAddr:String?
        var packetsPrice:Double = 0.0
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.packetsPrice = (DataSyncer.sharedInstance.ethSetting?.MBytesPerToken.DoubleV())!
                self.currentTokenName2.text = "HOP"
                self.currentTokenName1.text = "HOP"
                
                let setting = DataSyncer.sharedInstance.ethSetting!
                self.packetPrice.text = "Packet Price".locStr+": \(setting.MBytesPerToken) M/HOP"
                
                self.backFor500M.layer.cornerRadius = 10
                self.backFor1G.layer.cornerRadius = 10
                self.backFor2G.layer.cornerRadius = 10
                self.backFor5G.layer.cornerRadius = 10
                self.backFor8G.layer.cornerRadius = 10
                self.backFor20G.layer.cornerRadius = 10
                
                self.PacketForHalfHop.text = (setting.MBytesPerToken.DoubleV() * 5e5).ToPackets()
                self.PacketFor1Hop.text = (setting.MBytesPerToken.DoubleV() * 1e6).ToPackets()
                self.PacketFor2Hop.text = (setting.MBytesPerToken.DoubleV() * 2e6).ToPackets()
                self.PacketFor5Hop.text = (setting.MBytesPerToken.DoubleV() * 5e6).ToPackets()
                self.PacketFor8Hop.text = (setting.MBytesPerToken.DoubleV() * 8e6).ToPackets()
                self.PacketFor20Hop.text = (setting.MBytesPerToken.DoubleV() * 2e7).ToPackets()
                
                let tap = UITapGestureRecognizer.init(target: self, action: #selector(tap(_:)))
                self.view.addGestureRecognizer(tap)
                DispatchQueue.global(qos: .background).async {
                        let user_addr = DataSyncer.sharedInstance.wallet?.mainAddress
                        let (tokenBalance, _) = EthUtil.sharedInstance.Balance(userAddr: user_addr!)
                        DispatchQueue.main.async {
                                self.tokenBalance.text = "\(tokenBalance.ToCoin())"
                        }
                }
        }
        @objc func tap(_ gr:UIGestureRecognizer){
                self.view.endEditing(true)
        }
        @IBAction func BuyStaticPackets(_ sender: UIButton) {
                let token_no = Double(sender.tag) * 0.5
                _buyAction(tokenNo: token_no)
        }
        
        
        @IBAction func BuyDynamicPackets(_ sender: UIButton) {
                guard let token_no = (TokenNoTF.text as NSString?)?.doubleValue, token_no > 0.1 else{
                        self.ShowTips(msg: "Token no is too small".locStr)
                        return
                }
                
                _buyAction(tokenNo: token_no)
        }
        
        private func _ethAction(priKey pri_data:Data,
                                tokenNo:Double,
                                user:EthereumAddress,
                                pool pool_addr:String){
                
                defer {
                        self.hideIndicator()
                }
                
                self.showIndicator(withTitle: "", and: "Approving......".locStr)
                let no = BigUInt(tokenNo * HopConstants.DefaultTokenDecimal.DoubleV())
                guard let approve_tx = EthUtil.sharedInstance.approve(from: user,
                                                                tokenNo: no,
                                                                priKey: pri_data) else{
                        self.ShowTips(msg: "Approve failed".locStr)
                        return
                }
                
                self.hideIndicator()
                self.showIndicator(withTitle: "", and: "Packaging at".locStr + ":[\(approve_tx.hash)]")
                var success = EthUtil.sharedInstance.waitTilResult(txHash: approve_tx.hash)
                if !success{
                        self.ShowTips(msg: "Approve failed".locStr)
                        return
                }
                
                self.hideIndicator()
                self.showIndicator(withTitle: "", and: "Buying packets......".locStr)
                guard let buy_tx = EthUtil.sharedInstance.buyAction(user:user,
                                                                    from:pool_addr,
                                                                    tokenNo:no,
                                                                    priKey:pri_data) else{
                        self.ShowTips(msg: "Buy action failed".locStr)
                        return
                }
                self.hideIndicator()
                self.showIndicator(withTitle: "", and: "Packaging at".locStr + "[\(buy_tx.hash)]")
                success = EthUtil.sharedInstance.waitTilResult(txHash: approve_tx.hash)
                if !success{
                        self.ShowTips(msg: "Buy action  failed".locStr)
                        return
                }
                self.ShowTips(msg: "Buy Success".locStr + "[\(buy_tx.hash)]")
        }
        
        func _buyAction(tokenNo: Double) {
                
                guard let wallet = DataSyncer.sharedInstance.wallet else{
                        self.ShowTips(msg: "Invalid account".locStr)
                        return
                }
                
                guard let pool_addr = self.poolAddr else {
                        self.ShowTips(msg: "Invalid targe pool address".locStr)
                        return
                }
                
                self.showIndicator(withTitle: "Account".locStr, and: "Open account......".locStr)
                self.ShowPassword { (password, isOK) in
                        defer {
                                self.hideIndicator()
                        }
                        guard let pwd = password, isOK else{
                                return
                        }
                        
                        
                        do{
                                try wallet.Open(auth: pwd)
                                guard let pri_data = wallet.privateKey?.mainPriKey else{
                                        return
                                }

                                DispatchQueue.global(qos: .background).async {
                                        
                                        self._ethAction(priKey:pri_data,
                                                        tokenNo: tokenNo,
                                                        user: wallet.mainAddress!,
                                                        pool: pool_addr)
                                }
                                
                                
                        }catch let err{
                                NSLog("=======>buy packets failed\(err.localizedDescription)")
                                self.ShowTips(msg: "Buy err:\(err.localizedDescription)]")
                        }
                }
        }
}
