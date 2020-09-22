//
//  AccountViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

        @IBOutlet weak var applyFreeView: UIView!
        @IBOutlet weak var membershipView: UIView!
        @IBOutlet weak var membershipNoLabel: UILabel!
        @IBOutlet weak var appVerLabel: UILabel!
        @IBOutlet weak var docView: UIButton!
        @IBOutlet weak var shareView: UIView!
        @IBOutlet weak var dnsView: UIView!
        @IBOutlet weak var telegramView: UIView!
        @IBOutlet weak var walletAddrLabel: UILabel!
        @IBOutlet weak var ethBalanceLabel: UILabel!
        @IBOutlet weak var tokenBalanceLabel: UILabel!
        @IBOutlet weak var dnsIPLabel: UILabel!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                walletAddrLabel.text = Wallet.WInst.Address
                ethBalanceLabel.text = Wallet.WInst.ethBalance.ToCoin()
                tokenBalanceLabel.text = Wallet.WInst.tokenBalance.ToCoin()
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(openTelegram))
                tap.numberOfTapsRequired = 1
                telegramView.addGestureRecognizer(tap)
                
                let tap2 = UITapGestureRecognizer(target: self, action: #selector(changeBASIP))
                tap2.numberOfTapsRequired = 1
                dnsView.addGestureRecognizer(tap2)
                
                let tap3 = UITapGestureRecognizer(target: self, action: #selector(showDoc))
                tap3.numberOfTapsRequired = 1
                docView.addGestureRecognizer(tap3)
                
                let tap4 = UITapGestureRecognizer(target: self, action: #selector(shareApp))
                tap4.numberOfTapsRequired = 1
                shareView.addGestureRecognizer(tap4)
        }
        
        @objc func openTelegram() {

                let screenName = "hopcommunity"
                let appURL = NSURL(string: "tg://resolve?domain=\(screenName)")!
                let webURL = NSURL(string: "https://t.me/\(screenName)")!
                if UIApplication.shared.canOpenURL(appURL as URL) {
                        UIApplication.shared.open(appURL as URL, options: [:])
                }
                else {
                        UIApplication.shared.open(webURL as URL, options: [:])
                }
        }
        
        @objc func changeBASIP() {
        }
        
        @objc func shareApp() {
        }
        
        @objc func showDoc() {
        }

        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        }
}
