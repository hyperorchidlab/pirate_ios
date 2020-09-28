//
//  RechargeViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/28.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class RechargeViewController: UIViewController {
        
        var poolAddr:String = ""
        
        @IBOutlet weak var TokenNoTFD: UITextField!
        @IBOutlet weak var AddressTFD: UITextField!
        @IBOutlet weak var pasteBtn: UIButton!
        @IBOutlet weak var PriceLabel: UILabel!
        
        
        override func viewDidLoad() {
                super.viewDidLoad()
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
                self.view.addGestureRecognizer(tapGesture)
                
                PriceLabel.text = AppSetting.servicePrice.ToPackets()
                AddressTFD.text = Wallet.WInst.Address
        }
        @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
                TokenNoTFD.resignFirstResponder()
                AddressTFD.resignFirstResponder()
        }
    
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                let content = UIPasteboard.general.string
                
                if let str = content, Wallet.IsValidAdress(addrStr: str){
                        pasteBtn.isHidden = false
                }else{
                        pasteBtn.isHidden = true
                }
        }
        
        
        @IBAction func PasteCopiedAddress(_ sender: UIButton) {
                guard let content = UIPasteboard.general.string,Wallet.IsValidAdress(addrStr:content) else{
                        pasteBtn.isHidden = true
                        return
                }
                AddressTFD.text = content
        }
        
        @IBAction func BuyPackets(_ sender: UIButton) {
        }
        
        
        
        /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
