//
//  TransactionViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class TransactionViewController: UIViewController {

        @IBOutlet weak var tableview: UITableView!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                loadTXData()
        }
        
        func loadTXData(){
                AppSetting.workQueue.async {
                        Transaction.reLoad()
                        DispatchQueue.main.async {
                                self.tableview.reloadData()
                        }
                }
        }
}

extension TransactionViewController:UITableViewDelegate, UITableViewDataSource{
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return Transaction.CachedTX.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableview.dequeueReusableCell(withIdentifier: "TransactionTableViewCellID")
                guard let c = cell as? TransactionTableViewCell else {
                        return cell!
                }
                
                let tx = Transaction.CachedTX[indexPath.row]
                c.fieldUP(tx)
                return c
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                let tx = Transaction.CachedTX[indexPath.row]
                let urlStr = "https://etherscan.io/tx/\(tx.txHash!)"
                if let url = URL(string: urlStr) {
                        UIApplication.shared.open(url)
                }
        }
}
