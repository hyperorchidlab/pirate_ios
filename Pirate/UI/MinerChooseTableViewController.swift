//
//  MinerChooseTableViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/2.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class MinerChooseViewController: UIViewController {

        @IBOutlet weak var minerListView: UITableView!
        var minerArray:[MinerData] = []
        var curPool:String?
        var curMiner:String?
        var curCell:MinerDetailsTableViewCell?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                minerArray = Array(MinerData.MinerDetailsDic.values)
                minerListView.rowHeight = 97
                
                curPool = DataSyncer.sharedInstance.localSetting?.poolInUse
                curMiner = DataSyncer.sharedInstance.localSetting?.minerInUse
        }
        
        override func viewDidDisappear(_ animated: Bool) {
                super.viewDidDisappear(animated)
                if curMiner != DataSyncer.sharedInstance.localSetting?.minerInUse{
                        NotificationCenter.default.post(name:HopConstants.NOTI_CHANGE_MINER, object: nil, userInfo: ["New_Miner":curMiner as Any])
                }
        }
        
        @IBAction func LoadRandomMiners(_ sender: Any) {
                self.showIndicator(withTitle: "", and: "Chosing random miner......".locStr)
                EthUtil.sharedInstance.queue.async {
                        self.minerArray = EthUtil.sharedInstance.RandomMiners(inPool: self.curPool!)
                        DataSyncer.sharedInstance.updateLocalSetting(minerArr: self.minerArray)
                        DispatchQueue.main.async {
                                self.minerListView.reloadData()
                                self.hideIndicator()
                        }
                }
        }
        
        @IBAction func PingAction(_ sender: UIButton) {
                let m_data = self.minerArray[sender.tag]
                self.showIndicator(withTitle: "", and: "Ping......".locStr)
                
                BasUtil.queue.async {
                        defer {
                                self.hideIndicator()
                                DispatchQueue.main.async {
                                       self.minerListView.reloadData()
                                }
                       }
                       let miner_addr = m_data.Address
                       guard let ip = BasUtil.Query(addr: miner_addr) else{
                        m_data.IP = "no bas".locStr
                               return
                       }
                       
                       m_data.IP = ip
                       let ping =  BasUtil.Ping(addr: miner_addr, withIP: ip)
                       m_data.Ping = ping
                }
        }
        
        
        @IBAction func PingAllMiners(_ sender: Any) {
                
                guard self.minerArray.count > 0 else {
                        return
                }
                self.showIndicator(withTitle: "", and: "Ping all miners......".locStr)

                BasUtil.queue.async {
                let dispatchGrp = DispatchGroup()
                
                
                for miner in self.minerArray{
                        
//                        BasUtil.queue.async {
                        
                        dispatchGrp.enter()
                                let (ip, ping) = BasUtil.Ping(addr: miner.Address)
                                miner.IP = ip
                                miner.Ping = ping
                                NSLog("=======> ip=\(ip) ping=\(ping)")
                        dispatchGrp.leave()
//                        }
                }
                
                dispatchGrp.notify(queue: DispatchQueue.main){
                        self.minerListView.reloadData()
                        self.hideIndicator()
                }
        }

                }

}

// MARK: - Table view data source

extension MinerChooseViewController:UITableViewDelegate, UITableViewDataSource{
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MinerItemToChoose", for: indexPath)
                
                if let c = cell as? MinerDetailsTableViewCell{
                        var m_data = self.minerArray[indexPath.row]
                        c.initWith(minerData:&m_data, isChecked: curMiner == m_data.Address, index: indexPath.row)
                        if self.curMiner == m_data.Address{
                                NSLog("=======>find selector=>\(m_data.Address)")
                                self.curCell = c
                        }
                        
                        return c
                }
                return cell
        }
        
        
        func numberOfSections(in tableView: UITableView) -> Int {
                return 1
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return self.minerArray.count
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                let miner = self.minerArray[indexPath.row]
                self.curCell?.update(check:false)
                curMiner = miner.Address
                guard let c = tableView.cellForRow(at: indexPath) as? MinerDetailsTableViewCell else{
                        return
                }
                c.update(check:true)
                self.curCell = c
        }
}
