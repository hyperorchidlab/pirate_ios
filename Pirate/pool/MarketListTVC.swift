//
//  MarketListTVC.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import BigInt
import web3swift
class MarketListTVC: UITableViewController {
        // MARK: - Table view variables
        
        let dbContext = DataShareManager.privateQueueContext()
        var poolList:[PoolDetails] = []
        var poolAddrToRecharge:String?
        
        // MARK: - Table view init
        override func viewDidLoad() {
                super.viewDidLoad()
                self.tableView.estimatedRowHeight = 140
                self.tableView.rowHeight = 140
        }
        override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
                self.poolList = Array(DataSyncer.sharedInstance.poolData.values)
                self.tableView.reloadData()
        }

        // MARK: - Table view data source
        override func numberOfSections(in tableView: UITableView) -> Int {
                return 1
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return poolList.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PoolDetailInMarketCID", for: indexPath)
                if let c = cell as? PoolDetailsCellTableViewCell{
                        let pool_details = self.poolList[indexPath.row]
                        c.initWith(details:pool_details, index: indexPath.row)
                        return c
                }
                return cell
        }

        /**/
        // MARK: - Navigation

        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
                if segue.identifier == "ShowRechargePage"{
                        let vc : RechargeSimpleViewController = segue.destination as! RechargeSimpleViewController
                        vc.poolAddr = self.poolAddrToRecharge!
                }
        }

        @IBAction func BuyThisPool(_ sender: UIButton) {
                guard let _ = HopWallet.WInst?.mainAddress else{
                        self.ShowTips(msg: "Create your account first".locStr)
                        return
                }
                let pool_details = self.poolList[sender.tag]
                self.poolAddrToRecharge = pool_details.MainAddr.address
                
                self.performSegue(withIdentifier: "ShowRechargePage", sender: self)
        }
}
