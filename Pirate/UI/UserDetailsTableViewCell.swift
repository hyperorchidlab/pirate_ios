//
//  UserDetailsTableViewCell.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/28.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class UserDetailsTableViewCell: UITableViewCell {
        let BackGroudColor:[UIColor] = [UIColor.init(red: CGFloat(109)/255, green: CGFloat(151)/255, blue: CGFloat(206)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(247)/255, green: CGFloat(170)/255, blue: CGFloat(110)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(76)/255, green: CGFloat(194)/255, blue: CGFloat(208)/255, alpha: 1)]
        
        @IBOutlet weak var BackGroundView: UIView!
        @IBOutlet weak var rechargeButton: UIButton!
        @IBOutlet weak var poolShortName: UILabel!
        @IBOutlet weak var refundTime: UILabel!
        @IBOutlet weak var tokenBalance: UILabel!
        @IBOutlet weak var packetBalance: UILabel!
        @IBOutlet weak var credit: UILabel!
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }
        
        override func layoutSubviews() {
                super.layoutSubviews()
                self.BackGroundView.layer.cornerRadius = 10
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        public func initWith(userData u:CDUserAccount, poolData p:PoolDetails?, index:Int){
                
                var desc = "Pool:[\(p?.ShortName ?? "Removed")]\n "
                desc += "Balance:[\(u.tokenBalance.ToPackets())]\n "
                desc += "Nonce:[\(u.nonce)]\t Epoch:[\(u.epoch)]\n"
                desc += "Credit:[\(u.credit.ToPackets())]\n "
                desc += "InRecharge:[\(u.inRecharge.ToPackets())]\n "
                
                poolShortName.text = p?.ShortName
                refundTime.text = Date.init(timeIntervalSince1970: TimeInterval(u.expire)).stringVal //u.expire
                packetBalance.text = "\(u.packetBalance.ToPackets())\n "+"Packets".locStr
                tokenBalance.text = "\(u.tokenBalance.ToCoin())HOP\n "+"Token".locStr
                credit.text = "\(u.credit.ToPackets())\n "+"Credit".locStr
                
                let color = BackGroudColor[index%3]
                self.rechargeButton.setTitleColor(color, for: .normal)
                self.BackGroundView.backgroundColor = color
                self.rechargeButton.tag = index
       }        
}
