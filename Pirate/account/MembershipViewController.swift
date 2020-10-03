//
//  MemberShipViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/10/1.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class MembershipViewController: UIViewController {

        @IBOutlet weak var tableView: UITableView!
        
        var refreshControl = UIRefreshControl()
        var memberships:[CDMemberShip] = []
        var curPoolAddr:String?
        override func viewDidLoad() {
                super.viewDidLoad()
                tableView.rowHeight = 80
                self.memberships = Membership.MemberArray()
                
                refreshControl.addTarget(self, action: #selector(self.reloadMemberDetail(_:)), for: .valueChanged)
                tableView.addSubview(refreshControl)
                
                NotificationCenter.default.addObserver(self,
                                               selector: #selector(walletChanged(_:)),
                                               name: HopConstants.NOTI_WALLET_CHANGED.name,
                                               object: nil)
        }
        //MARK: - object c
        @objc func reloadMemberDetail(_ sender: Any?){
                AppSetting.workQueue.async {
                        Membership.syncAllMyMemberships()
                        self.memberships =  Membership.MemberArray()
                        DispatchQueue.main.async {
                                self.refreshControl.endRefreshing()
                                self.tableView.reloadData()
                        }
                }
        }
        @objc func walletChanged(_ notification: Notification?) {
                AppSetting.workQueue.async {
                        Membership.syncAllMyMemberships()
                        self.memberships = Membership.MemberArray()
                        DispatchQueue.main.async {
                                self.tableView.reloadData()
                        }
                }
        }
        
        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if let vc = segue.destination as? RechargeViewController,
                   let addr = self.curPoolAddr{
                        vc.poolAddr = addr
                }
        }
        
        @IBAction func RechargeAction(_ sender: UIButton) {
                curPoolAddr = self.memberships[sender.tag].poolAddr
                self.performSegue(withIdentifier: "ShowRechargePage", sender: self)
        }
        
}
extension MembershipViewController:UITableViewDelegate, UITableViewDataSource{
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return memberships.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MembershipTableViewCellRID", for: indexPath)
                if let c = cell as? MembershipTableViewCell{
                        let obj = self.memberships[indexPath.row]
                        c.populate(membership: obj, idx:indexPath.row)
                        return c
                }
                return cell
        }
}
