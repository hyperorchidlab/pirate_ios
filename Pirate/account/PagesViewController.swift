//
//  PagesViewController.swift
//  Pirate
//
//  Created by wesley on 2020/11/20.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class PagesViewController: UIPageViewController {
        
        private(set) var imageViewController: UserManualViewController!
        var imageNames = ["IOS_01","IOS_02","IOS_03","IOS_04","IOS_05","IOS_06"]
        var pageIdx:Int = 0
        
        override func viewDidLoad() {
                super.viewDidLoad()
                dataSource = self
                delegate = self
                
                imageViewController = UIStoryboard(name: "Main", bundle: nil) .
                        instantiateViewController(withIdentifier: "UserManualViewController") as? UserManualViewController
                
                setViewControllers([imageViewController],
                                   direction: .forward,
                            animated: true,
                            completion: nil)
        }
}

// MARK: UIPageViewControllerDataSource
extension PagesViewController: UIPageViewControllerDataSource {
 
        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
                pageIdx += 1
                if pageIdx == 6 {
                        self.dismiss(animated: true)
                        return nil
                }
                
                let imageName = imageNames[pageIdx]
                imageViewController.changeImageTo(name:imageName)
                
                return imageViewController
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
                pageIdx -= 1
                if pageIdx < 0{
                        return nil
                }
                let imageName = imageNames[pageIdx]
                imageViewController.changeImageTo(name:imageName)
                return imageViewController
        }
}

// MARK: UIPageViewControllerDelegate
extension PagesViewController: UIPageViewControllerDelegate{
        
}
