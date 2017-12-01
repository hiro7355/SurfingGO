//
//  StopInterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/10/17.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation


class StopInterfaceController: WKInterfaceController {

    
    var sessionIP : SessionInterfaceParam?
    @IBOutlet var stopButton: WKInterfaceButton!
    @IBOutlet var lockButton: WKInterfaceButton!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        sessionIP = context as? SessionInterfaceParam
        sessionIP?.stopIC = self
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    //
    //   MARK: ストップ
    //
    @IBAction func doStop() {
        
        
        let actYes = WKAlertAction(title: "保存", style: .default) {
            //  セッション停止
            self.sessionIP?.timeIC?.isKeep = true
            self.sessionIP?.timeIC?.doStop()

        }
        
        let actNo = WKAlertAction(title: "破棄", style: .destructive) {
            //  セッション停止
            self.sessionIP?.timeIC?.isKeep = false
            self.sessionIP?.timeIC?.doStop()
        }
        let actCancel = WKAlertAction(title: "Cancel", style: .cancel) {
            print("Cancel")
            
            
            
            //  セッション画面にきりかえます
            self.sessionIP?.timeIC?.becomeCurrentPage()
            
            
        }
        
        presentAlert(withTitle: "", message: "記録する場合は[保存]をタップしてください。", preferredStyle: .actionSheet, actions: [actYes, actNo, actCancel])


    }
    
    //
    //  ボタンを無効にします
    //
    func disableButtons() {
        stopButton.setEnabled(false)
        lockButton.setEnabled(false)
    }
    //
    //  画面をロックします
    //
    @IBAction func doLock() {
        //  セッション画面にきりかえます
        self.sessionIP?.timeIC?.becomeCurrentPage()
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //  ロックします
            WKExtension.shared().enableWaterLock()
        }
    }
    
}
