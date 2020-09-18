//
//  ConfirmViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit



class ConfirmViewController: UIViewController {
        
        @IBOutlet weak var CTitle: UILabel!
        @IBOutlet weak var Msg: UILabel!
        
        
        var CancelAction:(()->Void)?
        var OKAction:(()->Void)!
        
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        @IBAction func Close(_ sender: UIButton) {
                dismiss(animated: true) {
                        self.CancelAction?()
                }
        }
        
        @IBAction func OK(_ sender: UIButton) {
                dismiss(animated: true) {
                        self.OKAction()
                }
        }
}
