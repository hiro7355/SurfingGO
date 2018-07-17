//
//  InterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/09/26.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController /*, WCSessionDelegate */ {
    @IBOutlet var heatTimeSlider: WKInterfaceSlider!
    
    @IBOutlet var sessionTypeLabel: WKInterfaceLabel!
    
    
    //  ヒート時間スライダーが変更されるとよびだされます
    @IBAction func onChangeHeatTimeSlider(_ value: Float) {
        Settings.setHeatTime(value: Int(value))
        
        self.updateSessionTypeLabel()
    }
    
    //
    //  セッション種別のラベル表示を更新します
    //
    private func updateSessionTypeLabel() {
        
        if Settings.isHeatSession() {
            //  ヒート形式
            self.sessionTypeLabel.setText("\(Settings.heatTime())分ヒート")
        } else {
            //  フリーサーフィン
            self.sessionTypeLabel.setText("フリーサーフィン")
        }
    }
    //  スタートボタンタップ
    @IBAction func doStart() {
        
        let sessionIP = SessionInterfaceParam()
        
        let pages = ["idTimeInterface", "idStopInterface"]
        
        let contexts = [sessionIP,sessionIP]
        
        
        WKInterfaceController.reloadRootPageControllers(withNames: pages, contexts: contexts, orientation: WKPageOrientation.horizontal, pageIndex: 0)
        
    }
    
    private func updateView() {
        
        if Settings.isHeatSession() {
            //  ヒート形式のとき
            // ヒート時間スライダーを表示します
            heatTimeSlider.setHidden(false)
            //  ヒート時間を設定します
            heatTimeSlider.setValue(Float(Settings.heatTime()))
        } else {
            //  フリーサーフィンのとき
            // ヒート時間スライダーを非表示にします
            heatTimeSlider.setHidden(true)
        }
        
        //  セッション種別ラベルを表示更新します
        updateSessionTypeLabel()
        
    }
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let manager = FileManager.default
        do {
            let list = try manager.contentsOfDirectory(atPath: documentsPath)
            for path in list {
                print(path as NSString)
            }

        } catch {
            
        }
    }
    
    override func willActivate() {
        super.willActivate()
        self.updateView()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
}
