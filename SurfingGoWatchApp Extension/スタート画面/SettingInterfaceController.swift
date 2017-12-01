//
//  SettingInterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/10/17.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation


class SettingInterfaceController: WKInterfaceController {
    @IBOutlet var isHeatSessionSwitch: WKInterfaceSwitch!
    @IBOutlet var isAutoLockSwitch: WKInterfaceSwitch!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
        isAutoLockSwitch.setOn(Settings.isAutoLock())

        isHeatSessionSwitch.setOn(Settings.isHeatSession())

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func doSwitchAutoLock(_ value: Bool) {
        Settings.setAutoLock(on: value)
    }
    @IBAction func doSwitchHeatSession(_ value: Bool) {
        Settings.setHeatSession(on: value)
    }
    
}
