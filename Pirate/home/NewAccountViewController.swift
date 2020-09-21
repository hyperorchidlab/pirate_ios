//
//  NewAccountViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class NewAccountViewController: UIViewController {

        @IBOutlet weak var passwordTips: UILabel!
        @IBOutlet weak var Password1: UITextField!
        @IBOutlet weak var Password2: UITextField!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
                self.view.addGestureRecognizer(tapGesture)
        }
        
        @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
                Password1.resignFirstResponder()
                Password2.resignFirstResponder()
        }
        
        @IBAction func CreateAccount(_ sender: UIButton) {
                guard Password1.text == Password2.text else {
                        self.passwordTips.isHidden = false
                        return
                }
                
                guard let password = Password1.text,  password != ""else {
                        self.ShowTips(msg: "Invalid password".locStr)
                        return
                }
                
                self.showIndicator(withTitle: "", and: "Creating Account".locStr)
                AppSetting.workQueue.async {
                        
                        defer{self.hideIndicator()}
                        
                        if false == Wallet.NewInst(auth: password){
                                return
                        }
                        DispatchQueue.main.async {
                                self.dismiss(animated: true)
                        }
                }
        }
        
        @IBAction func ImportAccount(_ sender: UIButton) {
        }
}
