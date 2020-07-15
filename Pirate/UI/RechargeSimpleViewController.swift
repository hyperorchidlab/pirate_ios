//
//  RechargeSimpleViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/7/16.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import web3swift
import BigInt
import MBProgressHUD
class RechargeSimpleViewController: UIViewController {
        var poolAddr:String?
        var packetsPrice:Double = 0.0
        @IBOutlet weak var packetPrice: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.packetsPrice = (DataSyncer.sharedInstance.ethSetting?.MBytesPerToken.DoubleV())!
        let setting = DataSyncer.sharedInstance.ethSetting!
        self.packetPrice.text = "Points Cost".locStr+": \(setting.MBytesPerToken) M/HOP"
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tap(_:)))
        self.view.addGestureRecognizer(tap)
                       
    }

    @objc func tap(_ gr:UIGestureRecognizer){
            self.view.endEditing(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
        @IBAction func JoinLevel1(_ sender: UIButton) {
                _buyAction(tokenNo: 10)
        }
        
        @IBAction func JoinLevel2(_ sender: Any) {
                _buyAction(tokenNo: 20)
        }
        
        @IBAction func JoinLevel3(_ sender: Any) {
                _buyAction(tokenNo: 30)
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
                        
        //                self.hideIndicator()
        //                self.showIndicator(withTitle: "", and: "Packaging at".locStr + ":[\(approve_tx.hash)]")
                        var success = EthUtil.sharedInstance.waitTilResult(txHash: approve_tx.hash)
                        if !success{
                                self.ShowTips(msg: "Approve failed".locStr)
                                return
                        }
                        
        //                self.hideIndicator()
        //                self.showIndicator(withTitle: "", and: "Buying packets......".locStr)
                        guard let _ = EthUtil.sharedInstance.buyAction(user:user,
                                                                            from:pool_addr,
                                                                            tokenNo:no,
                                                                            priKey:pri_data) else{
                                self.ShowTips(msg: "Failed".locStr)
                                return
                        }
        //                self.hideIndicator()
        //                self.showIndicator(withTitle: "", and: "Packaging at".locStr + "[\(buy_tx.hash)]")
                        success = EthUtil.sharedInstance.waitTilResult(txHash: approve_tx.hash)
                        if !success{
                                self.ShowTips(msg: "Failed".locStr)
                                return
                        }
                        self.ShowTips(msg: "Approved".locStr)
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
                                self.ShowTips(msg: "\(err.localizedDescription)]")
                        }
                }
        }
}
