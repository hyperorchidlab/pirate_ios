//
//  UserManualViewController.swift
//  Pirate
//
//  Created by wesley on 2020/11/20.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class UserManualViewController: UIViewController {

        @IBOutlet weak var GuideImageView: UIImageView!
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        public func changeImageTo(name:String){
                DispatchQueue.main.async {
                        self.GuideImageView.image = UIImage.init(named: name)
                }
        }
}
