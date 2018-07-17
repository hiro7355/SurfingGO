//
//  UIViewControllerExtension.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/11/10.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit

extension UIViewController {
    var currentTopViewController: UIViewController? {
        if let viewController = self as? UINavigationController {
            return viewController.topViewController?.currentTopViewController
        }
        if let viewController = self as? UITabBarController {
            return viewController.selectedViewController?.currentTopViewController
        }
        if let viewController = self.presentedViewController {
            return viewController.currentTopViewController
        }
        return self
    }
    
    static func topViewController() -> UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController?.currentTopViewController
    }
}
