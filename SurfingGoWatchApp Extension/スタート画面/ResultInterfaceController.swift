//
//  ResultInterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/10/18.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation


class ResultInterfaceController: WKInterfaceController {

    @IBOutlet var startedOnLabel: WKInterfaceLabel!
    @IBOutlet var statedAtAndTimeLabel: WKInterfaceLabel!
    @IBOutlet var waveCountLabel: WKInterfaceLabel!
    @IBOutlet var longestDistanceLabel: WKInterfaceLabel!
    @IBOutlet var topSpeedLabel: WKInterfaceLabel!
    @IBOutlet var totalDistanceLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        super.willActivate()
        
        self.updateView()
    }
    
    private func updateView() {
        //  最後のセッションの開始日時
        if let date = Settings.lastSessionStatedAt() {
            
            self.startedOnLabel.setText("最終:" + DateUtils.stringFromDate(date: date as NSDate, format: "yyyy/MM/dd"))
            
            //  最後のセッションの時間（秒）
            let time = Settings.lastSessionTime()
            
            let startedAtString = DateUtils.stringFromDate(date: date as NSDate, format: "HH:mm")
            let text = startedAtString + "から\(Int(time/60))分"
            
            self.statedAtAndTimeLabel.setText(text)
            
            //  最後のセッションの本数
            self.waveCountLabel.setText("\(Settings.lastSessionWaveCount())Wave")

            //  最後のセッションの最長距離（メートル）
            self.longestDistanceLabel.setText("最長\(NumUtils.value1(forDoubleValue:Settings.lastSessionLongestDistance()))メートル")

            //  最後のセッションのトップスピード（m/s）
            self.topSpeedLabel.setText("最速\(NumUtils.kph(fromMps: Settings.lastSessionTopSpeed()))Km/h")

            //  最後のセッションの合計距離（メートル）
            self.totalDistanceLabel.setText("合計\(NumUtils.value1(forDoubleValue:Settings.lastSessionTotalDistance()))メートル")

        } else {
            self.startedOnLabel.setText("最終セッション")
        }
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
}
