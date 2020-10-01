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
        override func viewDidLoad() {
                super.viewDidLoad()
                self.memberships = MemberShip.MemberArray()
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
