//
//  PoolChoseTableViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/2.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class PoolChoseItemTableViewCell: UITableViewCell {
        
        @IBOutlet weak var poolAddrLabel: UILabel!
        @IBOutlet weak var poolNameLabel: UILabel!
        @IBOutlet weak var checkImg: UIImageView!
        var checked: Bool = false
        public func initWith(name:String?, addr:String?, isSelected:Bool){
                poolAddrLabel.text = addr
                poolNameLabel.text = name
                checkImg.isHidden = !isSelected
                checked = isSelected
        }
        
        func update(check:Bool){
                checkImg.isHidden = !check
        }
}

class PoolChoseTableViewController: UITableViewController {

        var validPoolArr:[CDUserAccount] = []
        var curPoolAddr:String?
        var curCell:PoolChoseItemTableViewCell?
        override func viewDidLoad() {
                super.viewDidLoad()
                self.tableView.rowHeight = 64
                validPoolArr =  PacketAccountant.Inst.allAccountants()
                curPoolAddr = DataSyncer.sharedInstance.localSetting?.poolInUse
        }
        
        override func viewDidDisappear(_ animated: Bool) {
                super.viewDidDisappear(animated)
                if curPoolAddr != DataSyncer.sharedInstance.localSetting?.poolInUse{
                        NotificationCenter.default.post(name:HopConstants.NOTI_CHANGE_POOL, object: nil, userInfo: ["New_Pool": curPoolAddr as Any])
                }
        }
        // MARK: - Table view data source

        override func numberOfSections(in tableView: UITableView) -> Int {
                return 1
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return self.validPoolArr.count
        }

    
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PoolItemToChooseID", for: indexPath)
                if let c = cell as? PoolChoseItemTableViewCell{
                        let p_data = self.validPoolArr[indexPath.row]
                        let p_addr = p_data.poolAddr!
                        let pool = DataSyncer.sharedInstance.poolData[p_addr]
                        let is_checked = p_addr == self.curPoolAddr
                        c.initWith(name: pool?.ShortName, addr: p_addr, isSelected: is_checked)
                        if is_checked{
                                self.curCell = c
                                self.curPoolAddr = p_addr
                        }
                }
                
                return cell
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                guard let cell = tableView.cellForRow(at: indexPath) as? PoolChoseItemTableViewCell else{
                        return
                }
                let p_data = self.validPoolArr[indexPath.row]
                self.curCell?.update(check:false)
                self.curPoolAddr = p_data.poolAddr
                
                cell.update(check: true)
                self.curCell = cell
        }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    */
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "ShowMinerListOfPool"{
//                let miner_sel = segue.destination as! MinerChooseViewController
//                miner_sel.curPool = curPoolAddr
//        }
//    }

}
