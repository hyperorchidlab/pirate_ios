//
//  SecondViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import AVFoundation
import web3swift

class WalletVC: UIViewController {
 
        @IBOutlet weak var SubedPoolTV: UITableView!
//        @IBOutlet weak var ETHBalance: UILabel!
//        @IBOutlet weak var TokenBalance: UILabel!
        @IBOutlet weak var reloadWalletBarItem: UIBarButtonItem!
        
        
        var imagePicker: UIImagePickerController!
        var Accounts:[CDUserAccount] = []
        var poolAddrToRecharge:String?
        
        enum ImageSource {
            case photoLibrary
            case camera
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                NSLog(DataSyncer.sharedInstance.wallet?.toJson() ?? "")
                self.SubedPoolTV.rowHeight = 128
                self.Accounts = PacketAccountant.Inst.allAccountants()
                self.SubedPoolTV.reloadData()
        }
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                
                if let _ =  DataSyncer.sharedInstance.wallet?.mainAddress {
                        reloadWalletBarItem.image = UIImage.init(named: "fresh-icon")
                        loadMyUserData()
//                        loadBalance(addr: addr)
                } else {
                        reloadWalletBarItem.image = UIImage.init(named: "add")
                        return
                }
        }
        
        func loadMyUserData(){
                guard let addr =  DataSyncer.sharedInstance.wallet?.mainAddress else {
                        return
                }
                
                self.showIndicator(withTitle: "", and: "Syncing from block chain......".locStr)
                DispatchQueue.global().async {
                        
                        defer{
                                self.hideIndicator()
                        }
                        
                        //TODO:: need to refactor
                        let user_datas = EthUtil.sharedInstance.AllMyUserData(userAddr:addr)
                        for (pool, u_d) in user_datas{
                               PacketAccountant.Inst.updateByEthData(userData: u_d, forPool:pool)
                        }
                        self.Accounts = PacketAccountant.Inst.allAccountants()
                        DispatchQueue.main.async {
                                self.SubedPoolTV.reloadData()
                        }
                }
                
        }
        
//        func loadBalance(addr:EthereumAddress){
//
//                DispatchQueue.global(qos: .background).async {
//                        let (tokenBalance, ethBalance) = EthUtil.sharedInstance.Balance(userAddr: addr)
//                        DispatchQueue.main.async {
//                                self.ETHBalance.text = "\(ethBalance.ToCoin())"
//                                self.TokenBalance.text = "\(tokenBalance.ToCoin())"
//                        }
//                }
//        }
        
//        @IBAction func reloadMyPools(_ sender: UIButton) {
//                loadMyUserData()
//        }
        
        @IBAction func reloadBalance(_ sender: Any) {
                loadMyUserData()
//                guard let addr =  DataSyncer.sharedInstance.wallet?.mainAddress else {
//                        self.showWalletOption()
//                        return
//                }
//                self.showIndicator(withTitle: "", and: "Loading.....".locStr)
//                loadBalance(addr: addr)
//                self.hideIndicator()
        }
        
        func showWalletOption(){
                let alert = UIAlertController(title: "Options".locStr, message: "Please Select an Option".locStr, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Create".locStr, style: .default , handler:{ (UIAlertAction)in
                        self.createNewWallet()
                }))
                
                alert.addAction(UIAlertAction(title: "Import QR image".locStr, style: .default , handler:{ (UIAlertAction)in
                        self.imagePicker =  UIImagePickerController()
                        self.imagePicker.delegate = self
                        self.imagePicker.sourceType = .photoLibrary
                        self.present(self.imagePicker, animated: true, completion: nil)
                }))

                alert.addAction(UIAlertAction(title: "Scan QR Code".locStr, style: .default , handler:{ (UIAlertAction)in
                        self.performSegue(withIdentifier: "ShowQRScanerID", sender: self)
                }))

                alert.addAction(UIAlertAction(title: "Cancel".locStr, style: .cancel, handler:{ (UIAlertAction)in
                    NSLog("=======>User click Dismiss button")
                }))
                
                alert.popoverPresentationController?.sourceView = self.view;
                alert.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1) //(0,0,1.0,1.0);
                self.present(alert, animated: true, completion: nil)
        }
        
        func createNewWallet(){
                self.showIndicator(withTitle: "", and: "Create new wallet....".locStr)
                self.ShowPassword() { (password , isOK) in
                        defer {
                                
                                self.hideIndicator()
                        }
                        
                        guard let pwd = password, isOK == true else{
                                return
                        }
                        
                        guard let wallet = HopWallet.NewWallet(auth: pwd) else{
                                self.ShowTips(msg: "Create failed".locStr)
                                return
                        }
                        
                        wallet.saveToDisk()
                        DataSyncer.sharedInstance.loadWallet()
                        self.ShowTips(msg: "Create success".locStr)
                        PacketAccountant.Inst.setEnv(MPSA: PacketAccountant.Inst.paymentAddr!, user: wallet.mainAddress!.address)
                }
        }
        
        // Mark View Action
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "ShowQRScanerID"{
                        let vc : ScannerViewController = segue.destination as! ScannerViewController
                        vc.delegate = self
                }else if segue.identifier == "ShowRechargePage"{
                        let vc : RechargeViewController = segue.destination as! RechargeViewController
                        vc.poolAddr = self.poolAddrToRecharge!
                }
        }

        @IBAction func rechargeThisPool(_ sender: UIButton) {
                guard let _ =  DataSyncer.sharedInstance.wallet?.mainAddress else{
                        self.ShowTips(msg: "Create your account first".locStr)
                        return
                }
                let user = self.Accounts[sender.tag]
                let pool_addr = user.poolAddr
                self.poolAddrToRecharge = pool_addr
                
                self.performSegue(withIdentifier: "ShowRechargePage", sender: self)
        }
}

extension WalletVC: UITextFieldDelegate{
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
}

extension WalletVC:UITableViewDelegate, UITableViewDataSource{
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return self.Accounts.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "UserDetailsCID", for: indexPath)
                if let c = cell as? UserDetailsTableViewCell{
                        let user = self.Accounts[indexPath.row]
                        let pool_addr = user.poolAddr
                        let pool = DataSyncer.sharedInstance.poolData[pool_addr!]
                        c.initWith(userData: user, poolData: pool, index: indexPath.row)
                        return c
                }
                return cell
        }
}

extension WalletVC: UINavigationControllerDelegate, UIImagePickerControllerDelegate, ScannerViewControllerDelegate{

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
                
                imagePicker.dismiss(animated: true, completion: nil)
                guard let qrcodeImg = info[.originalImage] as? UIImage else {
                        self.ShowTips(msg: "Image not found!".locStr)
                        return
                }
                
                let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                let ciImage:CIImage=CIImage(image:qrcodeImg)!
               
                let features=detector.features(in: ciImage)
                 var codeStr = ""
                for feature in features as! [CIQRCodeFeature] {
                    codeStr += feature.messageString!
                }
                
                if codeStr == "" {
                        self.ShowTips(msg: "Parse image failed".locStr)
                        return
                }else{
                        NSLog("=======>image QR string message: \(codeStr)")
                        self.codeDetected(code: codeStr)
                }
                
        }
        
        func codeDetected(code: String){
                self.showIndicator(withTitle: "", and: "Importing......".locStr)
                NSLog("=======>Scan result:=>[\(code)]")
                
                guard let w = HopWallet.from(json: code) else{
                        self.hideIndicator()
                        self.ShowTips(msg: "Parse json data to account failed".locStr)
                        return
                }
                
                self.ShowPassword(){
                        (password, isOK) in
                        
                        defer{
                                self.hideIndicator()
                        }
                        
                        if !isOK || password == nil{
                                return
                        }
                        
                        do {try w.Open(auth: password!)}catch let err{
                                NSLog("=======>\(err.localizedDescription)")
                                self.ShowTips(msg: "Author failed".locStr)
                                return
                        }
                        
                        w.saveToDisk()
                        DataSyncer.sharedInstance.loadWallet()
                        self.loadMyUserData()
//                        self.loadBalance(addr: (DataSyncer.sharedInstance.wallet?.mainAddress)!)
                        DispatchQueue.main.async {
                                self.reloadWalletBarItem.image = UIImage.init(named: "fresh-icon")
                        }
                        NotificationCenter.default.post(name: HopConstants.NOTI_IMPORT_WALLET, object: nil, userInfo: ["mainAddress":w.mainAddress!.address])
                }
        }
}
