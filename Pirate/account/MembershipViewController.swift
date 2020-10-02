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
        
        var memberships:[CDMemberShip] = []
        var curPoolAddr:String?
        override func viewDidLoad() {
                super.viewDidLoad()
                tableView.rowHeight = 80
                self.memberships = MemberShip.MemberArray()
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
