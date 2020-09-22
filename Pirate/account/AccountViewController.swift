//
//  AccountViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

        @IBOutlet weak var transactionNOLabel: UILabel!
        @IBOutlet weak var applyFreeTokenBtn: UIButton!
        @IBOutlet weak var membershipView: UIView!
        @IBOutlet weak var membershipNoLabel: UILabel!
        @IBOutlet weak var appVerLabel: UILabel!
        @IBOutlet weak var docView: UIView!
        @IBOutlet weak var shareView: UIView!
        @IBOutlet weak var dnsView: UIView!
        @IBOutlet weak var telegramView: UIView!
        @IBOutlet weak var walletAddrLabel: UILabel!
        @IBOutlet weak var ethBalanceLabel: UILabel!
        @IBOutlet weak var tokenBalanceLabel: UILabel!
        @IBOutlet weak var dnsIPLabel: UILabel!
        
        var appVersion: String? {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        }
        
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
                
                appVerLabel.text = appVersion
                dnsIPLabel.text = AppSetting.dnsIP
                
                
                
                NotificationCenter.default.addObserver(self, selector: #selector(dnsChanged(_:)), name: HopConstants.NOTI_DNS_CHANGED.name, object: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                
                applyFreeTokenBtn.isHidden = true
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func dnsChanged(_ notification: Notification?) {
                DispatchQueue.main.async {
                        self.dnsIPLabel.text = AppSetting.dnsIP
                }
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
                
                self.ShowOneInput(title: "Change Dns".locStr, placeHolder: "New Dns") { (newdns, isOK) in
                        guard let dns = newdns, isOK else{
                                return
                        }
                        
                        guard dns.isValidIP() else{
                                self.ShowTips(msg: "dns is invalid")
                                return
                        }
                        
                        AppSetting.changeDNS(dns)
                }
        }
        
        @objc func shareApp() {
                let items = [URL(string: "https://apps.apple.com/app/id1521121265")!,
                             URL(string: "https://testflight.apple.com/join/aMDfC5cV")!]
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                present(ac, animated: true)
        }
        
        @objc func showDoc() {
                if let url = URL(string: "https://docs.hyperorchid.org/") {
                    UIApplication.shared.open(url)
                }
        }

        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        }
}
