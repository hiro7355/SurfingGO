//
//  AlertViewUtils.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/23.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit

class AlertViewUtils {
    
    static func showConfirmView(forViewController: UIViewController, title: String, message: String, doneTitle: String, cancelTitle: String, doneHandler: ((UIAlertAction) -> Swift.Void)? = nil) {
        
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertControllerStyle.actionSheet)
        
        // doneボタン
        let okAction: UIAlertAction = UIAlertAction(title: doneTitle, style: UIAlertActionStyle.destructive, handler:doneHandler)
        // Cancelボタン
        let cancelButton: UIAlertAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.cancel)
        alertController.addAction(okAction)
        alertController.addAction(cancelButton)
        
        forViewController.present(alertController,animated: true,completion: nil)

    }
}
