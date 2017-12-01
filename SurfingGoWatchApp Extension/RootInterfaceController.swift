//
//  RootInterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/10/17.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation


class RootInterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        RootInterfaceController.showStartPages(pageIndex : 1)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    //  スタート画面を表示
    static func showStartPages(pageIndex : Int) {
        let pages = ["idResult","idStart", "idSetting"]
        
        let contexts = ["1","1","1"] as [Any]
        
        WKInterfaceController.reloadRootPageControllers(withNames: pages, contexts: contexts, orientation: WKPageOrientation.horizontal, pageIndex: pageIndex)
        
    }

}
