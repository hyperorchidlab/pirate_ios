//
//  AccountViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

        @IBOutlet weak var walletAddrLabel: UILabel!
        @IBOutlet weak var ethBalanceLabel: UILabel!
        @IBOutlet weak var tokenBalanceLabel: UILabel!
        override func viewDidLoad() {
                super.viewDidLoad()
                walletAddrLabel.text = Wallet.WInst.Address
                ethBalanceLabel.text = Wallet.WInst.ethBalance.ToCoin()
                tokenBalanceLabel.text = Wallet.WInst.tokenBalance.ToCoin()
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
