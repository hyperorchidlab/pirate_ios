//
//  SystemSettingTableViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/17.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import BigInt
import web3swift

class SystemSettingTableViewController: UITableViewController {

        @IBOutlet var settingTableView: UITableView!
//        @IBOutlet weak var refundDurationCell: UITableViewCell!
//        @IBOutlet weak var packetsPriceCell: UITableViewCell!
        @IBOutlet weak var mainAddrCell: UITableViewCell!
//        @IBOutlet weak var subAddrCell: UITableViewCell!
//        @IBOutlet weak var curTokenCell: UITableViewCell!
//        @IBOutlet weak var curMPSCell: UITableViewCell!
//        @IBOutlet weak var curBasIPLabel: UILabel!
        @IBOutlet weak var applyEthCell: UITableViewCell!
        @IBOutlet weak var applyTokenCell: UITableViewCell!
//        @IBOutlet weak var curApiUrlCell: UITableViewCell!
//        @IBOutlet weak var curTokenInUseCell: UITableViewCell!
        
        var mainAddr:EthereumAddress?
        var imagePicker: UIImagePickerController!
        var curToken:BigUInt = 0
        var curEth:BigUInt = 0
        override func viewDidLoad() {
                super.viewDidLoad()
                
//                curTokenCell.detailTextLabel?.text = HopConstants.DefaultTokenAddr
//                curMPSCell.detailTextLabel?.text = HopConstants.DefaultPaymenstService
//                curBasIPLabel.text = HopConstants.DefaultBasIP
//                curApiUrlCell.detailTextLabel?.text = "https://ropsten.infura.io/v3/"
//                curTokenInUseCell.detailTextLabel?.text = "HOP"
                NotificationCenter.default.addObserver(self, selector: #selector(WalletChanged(_:)), name: HopConstants.NOTI_NEW_WALLET, object: nil)
        }
        
        
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        
        @objc func WalletChanged(_ notification: Notification?) {
                guard let w =  DataSyncer.sharedInstance.wallet else{
                        return
                }
                DispatchQueue.main.async {
                        self.mainAddrCell.detailTextLabel?.text = w.mainAddress?.address
//                        self.subAddrCell.detailTextLabel?.text = w.subAddress
                }
        }
        
        override func viewWillAppear(_ animated: Bool){
                super.viewWillAppear(animated)
                if let addr = DataSyncer.sharedInstance.wallet?.mainAddress {
                        let main_addr = addr.address
//                        let sub_addr =  DataSyncer.sharedInstance.wallet?.subAddress
                        mainAddrCell.detailTextLabel?.text = main_addr
//                        subAddrCell.detailTextLabel?.text = sub_addr
                        
                        DispatchQueue.global().async {
                                let (token_balance, eth_balance) = EthUtil.sharedInstance.Balance(userAddr: addr)
                                DispatchQueue.main.async {
                                        self.applyEthCell.detailTextLabel?.text = "\(eth_balance.ToCoin())"
                                        self.applyTokenCell.detailTextLabel?.text = "\(token_balance.ToCoin())"
                                        self.curToken = token_balance
                                        self.curEth = eth_balance
                                        self.mainAddr = addr
                                }
                        }
                }
                
//                guard let setting = DataSyncer.sharedInstance.ethSetting else{
//                        return
//                }
//                packetsPriceCell.detailTextLabel?.text = "\(setting.MBytesPerToken) M/HOP"
//                refundDurationCell.detailTextLabel?.text = "\(setting.RefundDuration.DoubleV()/(24 * 60 * 60)) "+"Days".locStr
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
                if indexPath.section == 0{
                        
                        switch indexPath.row {
                        case 0:
                                guard nil == DataSyncer.sharedInstance.wallet?.mainAddress else {
                                       self.showConfirm(msg: "Replace your current account?".locStr, yesHandler:{
                                               self.createWallet()
                                       })
                                       return
                               }
                               createWallet()
                        case 1:
                                self.exportWallet()
                        case 2:
                                guard nil == DataSyncer.sharedInstance.wallet?.mainAddress else {
                                        self.showConfirm(msg: "Replace your current account?".locStr, yesHandler:{
                                                self.importFromLib()
                                        })
                                        return
                                }
                                importFromLib()
                        case 3:
                                guard nil == DataSyncer.sharedInstance.wallet?.mainAddress else {
                                        self.showConfirm(msg: "Replace your current account?".locStr, yesHandler:{
                                                self.importFromCamera()
                                        })
                                        return
                                }
                                importFromCamera()
                        case 4:
                                guard let str = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text else {
                                        return
                                }
                                UIPasteboard.general.string = str
                                self.ShowTips(msg: "Copy Success".locStr)
                        default:
                                return
                        }
                }else if indexPath.section == 1{
                        switch indexPath.row {
                        case 0:
                                self.getFreeEth()
                        case 1:
                                self.getFreeHOP()
                        default:
                                guard let str = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text else {
                                        return
                                }
                                UIPasteboard.general.string = str
                                self.ShowTips(msg: "Copy Success".locStr)
                                return
                        }
                }
        }

        private func createWallet(){
                
                self.showIndicator(withTitle: "", and: "Create new account....".locStr)
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
                        
                        DispatchQueue.main.async {
                                self.mainAddrCell.detailTextLabel?.text = wallet.mainAddress?.address
//                                self.subAddrCell.detailTextLabel?.text = wallet.subAddress
                                self.settingTableView.reloadData()
                        }
                        }
                        
                
        }
        // MARK: - Wallet action
        
        @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
                self.hideIndicator()
                if let error = error {
                self.ShowTips(msg: error.localizedDescription)
            } else {
                self.ShowTips(msg: "Save success to your photo library".locStr)
            }
        }
        
        func exportWallet(){
                self.showIndicator(withTitle: "", and: "Exporting......".locStr)
                guard let w_json = DataSyncer.sharedInstance.wallet?.toJson() else{
                        self.hideIndicator()
                        return
                }
                
                guard let ciImage = Utils.generateQRCode(from: w_json) else{
                        self.hideIndicator()
                        return
                }
                
                let context = CIContext()
                let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
                let uiImage = UIImage(cgImage: cgImage!)

                UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        func importFromLib(){
                self.imagePicker =  UIImagePickerController()
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = .photoLibrary
                self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        func importFromCamera(){
                self.performSegue(withIdentifier: "ShowQRScanerID", sender: self)
        }
        
        func transfer(){
                
        }
        func generateQR(){
                
        }
        
        // MARK: - System parameter action
        func changeBas(){
        }
        
        
        // MARK: - Block chain parameter
        func changeTokenInUse(){
        }
        
        func changeAPIURL(){
        }
        
        func getFreeEth(){
                self.showIndicator(withTitle: "", and: "Approving......".locStr)
                DispatchQueue.global().async {
                        defer {
                                self.hideIndicator()
                        }
                        guard let addr = self.mainAddr, self.curEth.DoubleV().ToCoinUnit() < 0.1 else {
                                self.ShowTips(msg: "Create wallet or you have more than 0.1 token".locStr)
                                return
                        }
                        
                        do {
                                let request = ApplyToken()
                                try request.initRequest()
                                _ = try request.ApplyeETH(user: addr)
                                self.ShowTips(msg: "Approving".locStr)
                        } catch let err {
                                self.ShowTips(msg: "Apply failed".locStr + ":\(err.localizedDescription)")
                        }
                }
        }
        
        func getFreeHOP(){
                self.showIndicator(withTitle: "", and: "Approving......".locStr)
                DispatchQueue.global().async {
                        defer {
                                self.hideIndicator()
                        }
                        guard let addr = self.mainAddr, self.curToken.DoubleV().ToCoinUnit() <= 1000  else {
                                self.ShowTips(msg: "Create wallet or you have more than 1000 hop".locStr)
                                return
                        }
                        
                        do {
                                
                                let request = ApplyToken()
                                try request.initRequest()
                                let tx = try request.ApplyeToken(user: addr)
                                self.ShowTips(msg: "Approving".locStr)
                                NSLog("=======>\(tx.hash)")
                        } catch let err {
                                self.ShowTips(msg: "Apply failed".locStr + ":\(err.localizedDescription)")
                        }
                }
                
        }
        
        // Mark View Action
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "ShowQRScanerID"{
                        let vc : ScannerViewController = segue.destination as! ScannerViewController
                        vc.delegate = self
                }
        }
}


extension SystemSettingTableViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate, ScannerViewControllerDelegate{

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
                        NotificationCenter.default.post(name: HopConstants.NOTI_IMPORT_WALLET, object: nil, userInfo: ["mainAddress":w.mainAddress!.address])
                }
        }
}
