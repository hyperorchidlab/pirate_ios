//
//  PoolDetailsCellTableViewCell.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/27.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class PoolDetailsCellTableViewCell: UITableViewCell {
        let BackGroudColor:[UIColor] = [UIColor.init(red: CGFloat(109)/255, green: CGFloat(151)/255, blue: CGFloat(206)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(247)/255, green: CGFloat(170)/255, blue: CGFloat(110)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(76)/255, green: CGFloat(194)/255, blue: CGFloat(208)/255, alpha: 1)]
        
        @IBOutlet weak var backGroundView: UIView!
        @IBOutlet weak var buyButton: UIButton!
//        @IBOutlet weak var GTN: UILabel!
        @IBOutlet weak var shortName: UILabel!
        @IBOutlet weak var email: UILabel!
        @IBOutlet weak var url: UILabel!
//        @IBOutlet weak var address: UILabel!
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        override func layoutSubviews() {
                super.layoutSubviews()
                self.backGroundView.layer.cornerRadius = 10
        }
        
        public func initWith(details d:PoolDetails, index:Int){
                self.shortName.text = d.ShortName
                self.email.text = d.Email
                self.url.text = d.Url ?? "NAN".locStr
//                self.address.text = d.MainAddr.address
//                self.GTN.text = d.GTN.ToCoin()
                let color = BackGroudColor[index%3]
                self.buyButton.setTitleColor(color, for: .normal)
                self.backGroundView.backgroundColor = color
                self.buyButton.tag = index
        }
}
