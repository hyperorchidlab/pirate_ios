//
//  AccountViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

        @IBOutlet weak var citBalanceLabel: UILabel!
        @IBOutlet weak var applyFreeEthBtn: UIButton!
        @IBOutlet weak var applyFreeTokenBtn: UIButton!
        @IBOutlet weak var walletView: UIView!
        @IBOutlet weak var transactionNOLabel: UILabel!
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
        @IBOutlet weak var authorBtn: UIButton!
        
        var appVersion: String? {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                walletAddrLabel.text = Wallet.WInst.Address
                appVerLabel.text = appVersion
                dnsIPLabel.text = AppSetting.dnsIP
                
                
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
                
                let tap5 = UITapGestureRecognizer(target: self, action: #selector(copyAddress))
                tap5.numberOfTapsRequired = 2
                walletView.addGestureRecognizer(tap5)
                
                checkStatusButon()
                
                NotificationCenter.default.addObserver(self, selector: #selector(dnsChanged(_:)), name: HopConstants.NOTI_DNS_CHANGED.name, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(walletChanged(_:)), name: HopConstants.NOTI_TX_STATUS_CHANGED.name, object: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                ethBalanceLabel.text = Wallet.WInst.ethBalance.ToCoin()
                tokenBalanceLabel.text = Wallet.WInst.tokenBalance.ToCoin()
                
                if Transaction.CachedTX.count > 0{
                        transactionNOLabel.isHidden = false
                        transactionNOLabel.text = "\(Transaction.CachedTX.count)"
                }else{
                        transactionNOLabel.isHidden = true
                }
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        // MARK: - Embedded Actions
        
        @objc func dnsChanged(_ notification: Notification?) {
                DispatchQueue.main.async {
                        self.dnsIPLabel.text = AppSetting.dnsIP
                }
        }
        
        @objc func walletChanged(_ notification: Notification?) {
                reloadWalletData()
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
        
        @objc func copyAddress() {
                UIPasteboard.general.string = Wallet.WInst.Address
                self.ShowTips(msg: "Copy Success".locStr)
        }
        
        private func checkStatusButon(){
                self.applyFreeEthBtn.isHidden =  Wallet.WInst.ethBalance > 0.005
                self.applyFreeTokenBtn.isHidden = Wallet.WInst.tokenBalance > 20
                self.authorBtn.isHidden = Wallet.WInst.ethBalance > 0.005 && Wallet.WInst.approve > 1000
        }
        private func reloadWalletData(){
                AppSetting.workQueue.async {
                        Wallet.WInst.queryBalance()
                        DispatchQueue.main.async { [self] in
                                self.ethBalanceLabel.text = Wallet.WInst.ethBalance.ToCoin()
                                self.tokenBalanceLabel.text = Wallet.WInst.tokenBalance.ToCoin()
                                self.checkStatusButon()
                        }
                }
        }
        // MARK: - Button Actions
        @IBAction func ApplyTokenAction(_ sender: UIButton) {
                self.showIndicator(withTitle: "", and: "Applying......".locStr)
                
                AppSetting.workQueue.async {
                        defer{self.hideIndicator()}
                        if false == Transaction.applyFreeToken(forAddr: Wallet.WInst.Address!){
                                self.ShowTips(msg: "Apply Failed".locStr)
                                return
                        }
                        
                        DispatchQueue.main.async {
                                self.applyFreeTokenBtn.isHidden = true
                                self.performSegue(withIdentifier: "ShowTransactionDetailsSegID", sender: self)
                        }
                }
        }
        
        @IBAction func ApplyEthAction(_ sender: UIButton) {
                self.showIndicator(withTitle: "", and: "Applying......".locStr)
                
                AppSetting.workQueue.async {
                        defer{self.hideIndicator()}
                        if false == Transaction.applyFreeEth(forAddr: Wallet.WInst.Address!){
                                self.ShowTips(msg: "Apply Failed".locStr)
                                return
                        }
                        
                        DispatchQueue.main.async {
                                self.applyFreeEthBtn.isHidden = true
                                self.performSegue(withIdentifier: "ShowTransactionDetailsSegID", sender: self)
                        }
                }
        }
        
        private func approve(){
                AppSetting.workQueue.async {
                        defer{self.hideIndicator()}
                        if false == Wallet.WInst.ApproveThisApp(){
                                self.ShowTips(msg: "Approve Failed".locStr)
                                return
                        }
                        
                        DispatchQueue.main.async {
                                self.authorBtn.isHidden = true
                                self.performSegue(withIdentifier: "ShowTransactionDetailsSegID", sender: self)
                        }
                }
        }
        
        @IBAction func AuthorizeAction(_ sender: UIButton) {
                
                guard Wallet.WInst.IsOpen() else {
                        self.ShowOnePassword(){
                                self.approve()
                        }
                        return
                }
                
                self.approve()
        }
        
        @IBAction func ShowAdressQR(_ sender: UIButton) {
                self.ShowQRAlertView(data: Wallet.WInst.Address!)
        }
        
        @IBAction func ReloadWallet(_ sender: UIBarButtonItem) {
                reloadWalletData()
        }
        
        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        }
}
