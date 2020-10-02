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
        
        var mainAddr:EthereumAddress?
        var imagePicker: UIImagePickerController!
        var curToken:BigUInt = 0
        var curEth:BigUInt = 0
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

                switch indexPath.row {
                case 0:
                        self.ConfirmAlert(title: "Confirm".locStr, msg: "Replace current account") {self.createWallet()}
                case 1:
                        exportWallet()
                case 2:
                        importFromLib()
                case 3:
                        importFromCamera()
                case 4:
                        showAccountQR()
                default:
                        return
                }
        }

        private func createWallet(){
                self.performSegue(withIdentifier: "CreateAccountSegID", sender: self)
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
                guard let w_json = HopWallet.WInst?.toJson() else{
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
        
        func showAccountQR(){
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

//                self.ShowPassword(){
//
//                        (password, isOK) in
//
//                        defer{
//                                self.hideIndicator()
//                        }
//
//                        if !isOK || password == nil{
//                                return
//                        }
//
//                        do {try w.Open(auth: password!)}catch let err{
//                                NSLog("=======>\(err.localizedDescription)")
//                                self.ShowTips(msg: "Author failed".locStr)
//                                return
//                        }
//
//                        w.saveToDisk()
//                        DataSyncer.sharedInstance.loadWallet()
//                        NotificationCenter.default.post(name: HopConstants.NOTI_IMPORT_WALLET, object: nil, userInfo: ["mainAddress":w.mainAddress!.address])
//                }
        }
}
