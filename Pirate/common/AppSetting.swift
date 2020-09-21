//
//  AppSetting.swift
//  Pirate
//
//  Created by wesley on 2020/9/21.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib

class AppSetting:NSObject{
        public static var curPoolAddr:String?
        public static var curMinerAddr:String?
        
        public func initSystem(){
                IosLibInitSystem(HopConstants.DefaultBasIP)
        }
}

