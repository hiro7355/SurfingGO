//
//  WaveSession.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/07.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import RealmSwift

let UNKNOWN_TEXT = "不明"

class WaveSession : Object  {
    
    static let ValidHorizontalAccuracy = 15.0    // ライディング時の有効な位置情報の水平範囲
    static let MinRidingTime = 2.0               //  ライディングとみなす最小のライディング時間
    static let RidingSpeed : Double = 3.0   //  ライディング識別スピードしきい値（m/s）x*3600/1000 = 10.8 km/h
    static let RidingStartKeepTime : TimeInterval = 3.5    //  ライディング開始識別スピードしきい値の継続時間（秒）。この時間一定のスピード以上を継続するとライディング開始と判断します
    static let RidingEndKeepTime : TimeInterval = 3.0    //  ライディング終了識別スピードしきい値の継続時間（秒）。この時間一定のスピード以下を継続するとライディング終了と判断します
    
    //  realmに保存
    @objc dynamic var id = -1                        //  セッションID
    var waves : List<Wave> = List<Wave>()           //  のった波
    @objc dynamic var startedAt : Date = Date()     //  セッション開始日時
    @objc dynamic var surfPoint : SurfPoint?        //  ポイント
    @objc dynamic var time : TimeInterval = 0       //  セッション時間（単位秒）
    @objc dynamic var totalDistance : Double = 0    //  総距離（単位メートル）
    @objc dynamic var averageSpeed : Double = 0     //  平均速度（単位秒速メートル）
    @objc dynamic var longestDistance : Double = 0  //  最長距離（単位メートル）
    @objc dynamic var topSpeed : Double = 0         //  最高速度（単位秒速メートル）
    @objc dynamic var satisfactionLevel : Int = -1   //  満足度（0-100）
    @objc dynamic var conditionLevel : Int = -1      //  コンディション（0-100）
    @objc dynamic var waveHeight : Int = -1        //  波の高さ（フィート。1:膝、2:腿、3:腰、4:腹、5:胸、6:肩、7:頭、8:頭オーバー、9:頭半、10:ダブル）
    @objc dynamic var waveDirection : Int = -1       //  うねりの向き（0:北、90:東、180:南、270:西）
    @objc dynamic var windWeight : Int = -1          //  風の強さ（風速メートル。0:無風、2:弱い、4:やや強い、8:強い、10-:極強い）
    @objc dynamic var windDirection : Int = -1       //  風向き（0:オフ、90:再度、180:オン）
    @objc dynamic var surfBoard : SurfBoard?   //  サーフボード
    @objc dynamic var memo : String = ""            //  メモ
    @objc dynamic var isWatch : Bool = false     //  AppleWatchで記録した場合はtrue
    @objc dynamic var firstLatitude: Double = 0 //  start時の位置情報(realm保存用)
    @objc dynamic var firstLongitude: Double = 0 //  start時の位置情報（realm保存用）
    
    var firstLocationCoordinate: CLLocationCoordinate2D? {
        if self.firstLongitude != 0 && self.firstLatitude != 0 {
            return CLLocationCoordinate2D(latitude: self.firstLatitude, longitude: self.firstLongitude)
        } else {
            return nil
        }
    }
    var firstLocation : CLLocation?   //  start時の位置情報(applewatchで位置情報取得時に設定される。iphone側では使わない)

    static let conditionLevelTexts : [String] = [UNKNOWN_TEXT, "×","▼", "△", "○", "◎"]
    static let conditionLevelValues : [Int] = [-1, 0,20, 40, 60, 80]
    static let satisfactionLevelTexts : [String] = [UNKNOWN_TEXT, "最低","ダメ", "まぁまぁ", "いいね", "最高！"]
    static let satisfactionLevelSmilys : [String] = ["", "😭","😞", "🙂", "😄", "🤣"]
    static let satisfactionLevelValues : [Int] = [-1, 0,20, 40, 60, 80]
    static let waveHeightTexts : [String] = [UNKNOWN_TEXT, "膝", "腿", "腰", "腹", "胸", "肩", "頭", "頭オーバー", "頭半", "ダブル"]
    static let waveHeightValues : [Int] = [-1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    static let waveDirectionTexts : [String] = [UNKNOWN_TEXT, "北", "北東", "東", "南東", "南", "南西", "西", "北西"]
    static let waveDirectionValues : [Int] = [-1, 0, 45, 90, 135, 180, 225, 270, 315]
    static let windDirectionTexts : [String] = [UNKNOWN_TEXT, "オフ", "サイド", "オン"]
    static let windDirectionValues : [Int] = [-1, 0, 90, 180]
    static let windWeightTexts : [String] = [UNKNOWN_TEXT, "無風", "弱い", "やや強い", "強い", "極強い"]
    static let windWeightValues : [Int] = [-1, 0, 2, 4, 8, 10]

    //  最高速度（集計用）単位秒速メートル
    static let topSpeedTexts : [String] = ["0km/h〜", "10km/h〜", "20km/h〜", "30km/h〜", "40km/h〜"]
    static let topSpeedValues : [Int] = [0, 10, 20, 30, 40]
    //  最高距離（集計用）単位m
    static let longestDistanceTexts : [String] = ["0m〜", "25m〜", "50m〜", "100m〜", "200m〜"]
    static let longestDistanceValues : [Int] = [0,25,50,100,200]
    static let meterUnit : String = "m"

    //　プライマリーキーの設定
    override static func primaryKey() -> String? {
        return "id"
    }

    //  セッション一覧からトータルWave数を取得します
    static func totalWaveCount(inWaveSessions: Results<WaveSession>) -> Int {
        var totalWaveCount = 0
        for waveSession in inWaveSessions {
            if waveSession.waves.count > 0 {
                totalWaveCount = totalWaveCount + waveSession.waves.count
            }
        }
        return totalWaveCount
    }

    // 評価（波質）
    static func conditionLevel(fromLabel label : String) -> Int {
        for index in 0..<WaveSession.conditionLevelTexts.count {
            if label == WaveSession.conditionLevelTexts[index] {
                return WaveSession.conditionLevelValues[index]
            }
        }
        return -1       //
    }

    static func conditionLevelLabel(fromValue value : Int) -> String {
        if value == -1 {
            return ""
        }
        
        for index in 0..<WaveSession.conditionLevelValues.count {
            if value == WaveSession.conditionLevelValues[index] {
                return WaveSession.conditionLevelTexts[index]
            }
        }
        return ""       //
    }
    // 評価（波質）
    func conditionLevelText() -> String {
        return WaveSession.conditionLevelLabel(fromValue : self.conditionLevel)
    }
    func setConditionLevelText(text : String) -> Void {
        self.conditionLevel = WaveSession.conditionLevel(fromLabel: text)
    }
    // 評価（満足度）
    static func satisfactionLevel(fromLabel label : String) -> Int {
        for index in 0..<WaveSession.satisfactionLevelTexts.count {
            if label == WaveSession.satisfactionLevelTexts[index] {
                return WaveSession.satisfactionLevelValues[index]
            }
        }
        return -1       //
    }
    static func satisfactionLevelLabel(fromValue value : Int) -> String {
        if value == -1 {
            return ""
        }
        for index in 0..<WaveSession.satisfactionLevelValues.count {
            if value == WaveSession.satisfactionLevelValues[index] {
                return WaveSession.satisfactionLevelTexts[index]
            }
        }
        return ""       //
    }
    static func satisfactionLevelIndex(fromValue value : Int) -> Int {
        for index in 0..<WaveSession.satisfactionLevelValues.count {
            if value == WaveSession.satisfactionLevelValues[index] {
                return index
            }
        }
        return -1       //
    }

    // 評価（満足度）
    func satisfactionLevelText() -> String {
        return WaveSession.satisfactionLevelLabel(fromValue : self.satisfactionLevel)
    }
    func setSatisfactionLevelText(text : String) -> Void {
        self.satisfactionLevel = WaveSession.satisfactionLevel(fromLabel: text)
    }

    // 評価（満足度） スマイリー
    static func satisfactionLevelSmilyAndTexts() -> [String] {
        var values : [String] = []
        for index in 0..<WaveSession.satisfactionLevelSmilys.count {
            values.append(WaveSession.satisfactionLevelSmilyAndText(fromIndex : index))
        }
        return values
    }
    static func satisfactionLevelSmilyAndText(fromIndex : Int) -> String {
        return WaveSession.satisfactionLevelSmilys[fromIndex] + WaveSession.satisfactionLevelTexts[fromIndex]
    }
    func satisfactionLevelSmilyAndText() -> String {
        if self.satisfactionLevel == -1 {
            return ""
        }
        let index = WaveSession.satisfactionLevelIndex(fromValue: self.satisfactionLevel)
        return WaveSession.satisfactionLevelSmilyAndText(fromIndex : index)
    }
    static func satisfactionLevelSmily(fromValue : Int) -> String {
        if fromValue == -1 {
            return ""
        }
        let index = WaveSession.satisfactionLevelIndex(fromValue: fromValue)
        return WaveSession.satisfactionLevelSmilys[index]
    }
    func satisfactionLevelSmily() -> String {
        return WaveSession.satisfactionLevelSmily(fromValue : self.satisfactionLevel)
    }

    static func satisfactionLevel(fromSmilyAndText label : String) -> Int {
        for index in 0..<WaveSession.satisfactionLevelTexts.count {
            if label == WaveSession.satisfactionLevelSmilyAndText(fromIndex : index){
                return WaveSession.satisfactionLevelValues[index]
            }
        }
        return -1       //
    }
    func setSatisfactionLevel(fromSmilyAndText : String) -> Void {
        self.satisfactionLevel = WaveSession.satisfactionLevel(fromSmilyAndText: fromSmilyAndText)
    }

    // 波のサイズ
    static func waveHeight(fromLabel label : String) -> Int {
        for index in 0..<WaveSession.waveHeightTexts.count {
            if label == WaveSession.waveHeightTexts[index] {
                return WaveSession.waveHeightValues[index]
            }
        }
        return -1       //
    }
    static func waveHeightLabel(fromValue value : Int) -> String {
        if value == -1 {
            return ""
        }
        for index in 0..<WaveSession.waveHeightValues.count {
            if value == WaveSession.waveHeightValues[index] {
                return WaveSession.waveHeightTexts[index]
            }
        }
        return ""       //
    }
    //  波のサイズ
    func waveHeightText() -> String {
        return WaveSession.waveHeightLabel(fromValue : self.waveHeight)
    }
    func setWaveHeightText(text : String) -> Void {
        self.waveHeight = WaveSession.waveHeight(fromLabel: text)
    }
    // うねりの向き
    static func waveDirection(fromLabel label : String) -> Int {
        for index in 0..<WaveSession.waveDirectionTexts.count {
            if label == WaveSession.waveDirectionTexts[index] {
                return WaveSession.waveDirectionValues[index]
            }
        }
        return -1       //
    }
    static func waveDirectionLabel(fromValue value : Int) -> String {
        if value == -1 {
            return ""
        }
        for index in 0..<WaveSession.waveDirectionValues.count {
            if value == WaveSession.waveDirectionValues[index] {
                return WaveSession.waveDirectionTexts[index]
            }
        }
        return ""       //
    }
    // うねりの向き
    func waveDirectionText() -> String {
        return WaveSession.waveDirectionLabel(fromValue : self.waveDirection)
    }
    func setWaveDirectionText(text : String) -> Void {
        self.waveDirection = WaveSession.waveDirection(fromLabel: text)
    }

    //  風の強さ
    static func windWeight(fromLabel label : String) -> Int {
        for index in 0..<WaveSession.windWeightTexts.count {
            if label == WaveSession.windWeightTexts[index] {
                return WaveSession.windWeightValues[index]
            }
        }
        return -1       //
    }
    static func windWeightLabel(fromValue value : Int) -> String {
        if value == -1 {
            return ""
        }
        for index in 0..<WaveSession.windWeightValues.count {
            if value == WaveSession.windWeightValues[index] {
                return WaveSession.windWeightTexts[index]
            }
        }
        return ""       //
    }
    //  風の強さ
    func windWeightText() -> String {
        return WaveSession.windWeightLabel(fromValue : self.windWeight)
    }
    func setWindWeightText(text : String) -> Void {
        self.windWeight = WaveSession.windWeight(fromLabel: text)
    }

    // 風向き
    static func windDirection(fromLabel label : String) -> Int {
        for index in 0..<WaveSession.windDirectionTexts.count {
            if label == WaveSession.windDirectionTexts[index] {
                return WaveSession.windDirectionValues[index]
            }
        }
        return -1       //
    }
    static func windDirectionLabel(fromValue value : Int) -> String {
        if value == -1 {
            return ""
        }
        for index in 0..<WaveSession.windDirectionValues.count {
            if value == WaveSession.windDirectionValues[index] {
                return WaveSession.windDirectionTexts[index]
            }
        }
        return ""       //
    }
    // 風向き
    func windDirectionText() -> String {
        return WaveSession.windDirectionLabel(fromValue : self.windDirection)
    }
    func setWindDirectionText(text : String) -> Void {
        self.windDirection = WaveSession.windDirection(fromLabel: text)
    }

    func startedAtText() -> String {
        
        let dayInterval = DateUtils.dayInterval(fromDate: self.startedAt, toDate: Date())
        if dayInterval >= 7 {
            
            return DateUtils.stringFromDate(date: self.startedAt as NSDate, format: "yyyy/MM/dd HH:mm")
        } else if( dayInterval == 0 ){
            return "今日 " + DateUtils.stringFromDate(date: self.startedAt as NSDate, format: "HH:mm")
        } else {
            return DateUtils.weakDayString(for: self.startedAt) + " " + DateUtils.stringFromDate(date: self.startedAt as NSDate, format: "HH:mm")
        }
    }
    func startedOnText() -> String {
        return DateUtils.stringFromDate(date: self.startedAt as NSDate, format: "yyyy年MM月dd ") + DateUtils.weakDayString(for: self.startedAt)
    }
    func startedAtAndEndedAtText() -> String {
        let endedAt = DateUtils.addTime(for: self.startedAt, second: Int(self.time))
        return DateUtils.stringFromDate(date: self.startedAt as NSDate, format: "HH:mm") + "~" + DateUtils.stringFromDate(date: endedAt as NSDate, format: "HH:mm")
    }

    func timeText() -> String {
        return self.time > 0 ? String(Int(self.time / 60))+"分" : ""
    }
    
    func wavesCountText() -> String {
        return  self.isWatch ? WaveSession.wavesCountText(forWaveCount : self.waves.count) : ""
    }
    static func wavesCountText(forWaveCount : Int) -> String {
        return  String(forWaveCount)+WaveSession.waveCountUnit(forWaveCount : forWaveCount)
    }
    static func waveCountUnit(forWaveCount : Int) -> String {
        return  forWaveCount > 1 ? "Waves" : "Wave"
    }

    func longestDistanceText() -> String {
        return self.isWatch ? String(NumUtils.value1(forDoubleValue: self.longestDistance))+WaveSession.meterUnit : ""
    }
    func longestDistanceText2() -> String {
        return self.isWatch ? "最長"+String(NumUtils.value1(forDoubleValue: self.longestDistance))+WaveSession.meterUnit : ""
    }
    func totalDistanceText() -> String {
        return self.isWatch ? String(NumUtils.value1(forDoubleValue: self.totalDistance))+WaveSession.meterUnit : ""
    }
    func totalDistanceText2() -> String {
        return self.isWatch ? "合計" + String(NumUtils.value1(forDoubleValue: self.totalDistance))+WaveSession.meterUnit : ""
    }
    func topSpeedText() -> String {
        return self.isWatch ? String(Int(NumUtils.kph(fromMps: self.topSpeed)))+"km/h" : ""
    }
    func topSpeedText2() -> String {
        return self.isWatch ? "最速" + String(Int(NumUtils.kph(fromMps: self.topSpeed)))+"km/h" : ""
    }
    func averageSpeedText() -> String {
        return self.isWatch ? String(Int(NumUtils.kph(fromMps: self.averageSpeed)))+"km/h" : ""
    }
    func averageSpeedText2() -> String {
        return self.isWatch ? "平均" + String(Int(NumUtils.kph(fromMps: self.averageSpeed)))+"km/h" : ""
    }

    var ridingStartLocation : CLLocation? = nil
    var lastUpdatedLocation : CLLocation? = nil
    var ridingEndLocation : CLLocation? = nil
    var lastWave : Wave = Wave()
    
    enum RidingModeType: Int {
        case Waiting = 1    //  波待ち中
        case RidingStarting // 　ライディング開始判別中（Waitingから遷移）
        case Riding         //  ライディング中
        case RidingEnding   //  ライディング終了判別中
    }
    
    var ridingMode : RidingModeType = RidingModeType.Waiting
    
    func start() -> Void {
    }
    
    func updateLocation(location: CLLocation) -> Void {
        let horizontalAccuracy : Double = location.horizontalAccuracy
        if horizontalAccuracy < 0.0 || horizontalAccuracy > WaveSession.ValidHorizontalAccuracy {
            return
        }
        
        if self.firstLocation == nil {
            self.firstLocation = location
        }
        
        switch self.ridingMode {
        case RidingModeType.Waiting:    //  波待ち中
            
            if self.isContinueRiding(location : location) {
                //  ライディング開始位置を保存します
                self.ridingStartLocation = location
                
                //  ライディング中の波に位置情報を追加します
                lastWave.addLocation(location: location)
                
                //  開始判別中モードにします
                self.ridingMode = RidingModeType.RidingStarting
                Swift.print("モード変更：開始判別中!")

            }
        case RidingModeType.RidingStarting: // 　ライディング開始判別中（Waitingから遷移）
            
            if self.isContinueRiding(location : location) {
                
                //  ライディング中の波に位置情報を追加します
                lastWave.addLocation(location: location)

                let time = location.timestamp.timeIntervalSince1970 - (self.ridingStartLocation?.timestamp.timeIntervalSince1970)!
                
                if time > WaveSession.RidingStartKeepTime {
                    //  一定時間ライディング開始判別中をキープしたのでライディング中にします
                    //  ライディング中モードにします
                    self.ridingMode = RidingModeType.Riding
                    Swift.print("モード変更：ライディング中!")
                }

            } else {
                //  波待ち中モードにします
                self.ridingMode = RidingModeType.Waiting

                //  開始位置をリセットします
                self.ridingStartLocation = nil
                
                //  ライディング中の波のいち情報をリセットします
                lastWave.reset()
                Swift.print("モード変更：波待ち中にもどる")

            }
            
        case RidingModeType.Riding:         //  ライディング中
            
            if self.isContinueRiding(location : location) {
                //  ライディング中の波に位置情報を追加します
                lastWave.addLocation(location: location)

            } else {
                //  ライディング終了位置を設定します
                self.ridingEndLocation = location
                // ライディング終了判別中にします
                self.ridingMode = RidingModeType.RidingEnding
                
                //  ライディング中かもしれない位置情報を追加します
                lastWave.addTempLocation(location: location)
                Swift.print("モード変更：ライディング終了判別中!")
            }

        case RidingModeType.RidingEnding:   //  ライディング終了判別中
            
            if !self.isContinueRiding(location : location) {
                
                //  ライディング中かもしれない位置情報を追加します(Watchで記録しておく必要がある。iPhoneに転送してiPhone側で終了判別できるようにするため)
                lastWave.addTempLocation(location: location)
                
                let time = location.timestamp.timeIntervalSince1970 - (self.ridingEndLocation?.timestamp.timeIntervalSince1970)!
                
                if time > WaveSession.RidingEndKeepTime {
                    //  一定時間ライディング停止判別中をキープしたのでライディング停止にします
                    if self.endRiding() {
                        Swift.print("ライディング停止")
                    }
                }
            } else {
                //  ライディング終了位置をリセットします
                self.ridingEndLocation = nil
                //  ライディング中モードにもどします
                self.ridingMode = RidingModeType.Riding
                //  ライディング中かもしれない位置情報をライディング中位置情報に追加します
                lastWave.commitTempLocations(location : location)
                Swift.print("モード変更：ライディングモードにもどる")
            }
        }
        
        //  次回のために位置情報を保存します
        self.lastUpdatedLocation = location
    }
    
    //
    // ライディングを終了します
    //
    func endRiding() -> Bool {
        var result = false
        
        if self.ridingMode  == RidingModeType.RidingEnding || self.ridingMode == RidingModeType.Riding {
            
            //  波待ち中モードにします
            self.ridingMode = RidingModeType.Waiting

            self.lastWave.calc()
            
            if self.lastWave.time > WaveSession.MinRidingTime {
                
                self.lastWave.commit()
                
                //  セッション中の波に追加します
                self.waves.append(self.lastWave)
                
                result = true
                Swift.print("ライディング追加!")

            } else {
                Swift.print("ライディング時間が短すぎ!")
            }
            
            Swift.print("モード変更：波待ち中")

            self.lastWave = Wave()
        }

        return result
    }

    //
    //  ライディング中継続を判別します
    //
    func isContinueRiding(location : CLLocation) -> Bool {
        let speed : Double = location.speed
        
        return speed > WaveSession.RidingSpeed ? true : false
    }
    func commit() {
        //  Realmように位置情報を変換してリストに追加します
        for wave in self.waves {
            // Realmのobjectに変換します
            wave.commit()
        }
    }

    func print() {
        Swift.print("Wave:\(self.waves.count)本")
        for wave : Wave in waves {
            Swift.print(wave.toString())
        }
    }
    
    //
    //総距離、平均速度、最長距離、最高速度を位置情報からもとめてメンバーに設定します
    // @objc dynamic var totalDistance : Double = 0    //  総距離（単位メートル）
    // @objc dynamic var averageSpeed : Double = 0     //  平均速度（単位秒速メートル）
    // @objc dynamic var longestDistance : Double = 0  //  最長距離（単位メートル）
    // @objc dynamic var topSpeed : Double = 0         //  最高速度（単位秒速メートル）
    //
    func calc(withWaveCalc : Bool) {
        var totalDistance : Double = 0
        var totalRidingTime : Double = 0
        var longestDistance : Double = 0
        var topSpeed : Double = 0

        for wave in self.waves {
            
            if withWaveCalc {
                wave.calc()
            }
            
            totalDistance = totalDistance + wave.distance
            totalRidingTime = totalRidingTime + wave.time
            
            //  最長距離を更新します
            if longestDistance < wave.distance {
                longestDistance = wave.distance
            }
            //  トップスピードを更新します
            if topSpeed < wave.topSpeed {
                topSpeed = wave.topSpeed
            }
        }
        
        self.averageSpeed = totalDistance / totalRidingTime
        self.totalDistance = totalDistance
        self.longestDistance = longestDistance
        self.topSpeed = topSpeed
    }
    
    
    func topSpeedWave() -> Wave? {
        var topSpeed : Double = 0
        var topSpeedWave : Wave?
        
        for wave in self.waves {
            //  トップスピードを更新します
            if topSpeed < wave.topSpeed {
                topSpeed = wave.topSpeed
                topSpeedWave = wave
            }
        }
        return topSpeedWave
    }

    func longestDistanceWave() -> Wave? {
        var longestDistance : Double = 0
        var longestDistanceWave : Wave?
        
        
        for wave in self.waves {
            //  最長距離を更新します
            if longestDistance < wave.distance {
                longestDistance = wave.distance
                longestDistanceWave = wave
            }
        }
        return longestDistanceWave
        
    }

    func calcTime(endedAt: Date) {
        //  セッション時間を設定します
        self.time = (endedAt.timeIntervalSince1970 - self.startedAt.timeIntervalSince1970)

    }
    
    static func location(from locationValuesText : String) -> CLLocation? {
        let locationValues : [String] = locationValuesText.components(separatedBy: ",")
        
        if locationValues.count > 8 {
            
            let latitudeString : String = locationValues[2]
            let longitudeString: String = locationValues[3]
            let altitudeString: String = locationValues[4]
            let horizontalAccuracyString: String = locationValues[5]
            let verticalAccuracyString: String = locationValues[6]
            let courseString: String = locationValues[7]
            let speedString: String = locationValues[1]
            let timestampString: String = locationValues[8]
            let timestamp : NSDate = DateUtils.dateFromString(string: timestampString, format: "yyyy-MM-dd HH:mm:ss Z")
            
            let location : CLLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: atof(latitudeString), longitude: atof(longitudeString)), altitude: atof(altitudeString), horizontalAccuracy : atof(horizontalAccuracyString), verticalAccuracy : atof(verticalAccuracyString), course: atof(courseString), speed: atof(speedString), timestamp: timestamp as Date)
            
            return location
        } else {
            return nil
        }
        
    }

    static func Create(fromWavesLocationTexts wavesLocationTexts : [String]?,
                       andFirstLocationText firstLocationText : String?, andStartedAtText startedAtText : String?, andEndedAtText endedAtText : String?) -> WaveSession {
        let session : WaveSession = WaveSession()
        session.isWatch = true      //  apple Watchからの情報にもとづいて生成されたことを示します

        if let wavesLocationTexts = wavesLocationTexts {
            for locationTexts in wavesLocationTexts {
                let locationArray : [String] = locationTexts.components(separatedBy: "\n")
                
                let wave = Wave()
                
                for locationValuesText : String in locationArray {
                    //  位置情報を追加します
                    if let location = WaveSession.location(from: locationValuesText) {
                        wave.addLocation(location: location)
                    }
                }
                
                session.waves.append(wave)
            }
            session.calc(withWaveCalc: true)
        }

        if let firstLocationText = firstLocationText {
            if let firstLocation = WaveSession.location(from: firstLocationText) {
                session.firstLatitude = firstLocation.coordinate.latitude
                session.firstLongitude = firstLocation.coordinate.longitude
            }
        }
        
        if let startedAtText = startedAtText {
            //  セッション開始日時を設定します
            session.startedAt = DateUtils.dateFromString(string: startedAtText, format: "yyyy-MM-dd HH:mm:ss Z") as Date
            
            if let endedAtText = endedAtText {
                let endedAt : Date = DateUtils.dateFromString(string: endedAtText, format: "yyyy-MM-dd HH:mm:ss Z") as Date
                
                //  セッション時間を設定します
                session.time = (endedAt.timeIntervalSince1970 - session.startedAt.timeIntervalSince1970)
            }
        }
        return session
    }

    static func loadWaveSessionsBySections(realm : Realm) -> [Results<WaveSession>] {
        return loadWaveSessionsBySections(realm : realm, fromDate : nil, toDate : nil)
    }

    static func loadWaveSessionsBySections(realm : Realm, fromDate : Date?, toDate : Date?) -> [Results<WaveSession>] {
        //  realmからデータを取得します
        var waveSessions : Results<WaveSession>

        if fromDate == nil {
            waveSessions = realm.objects(WaveSession.self)
            
        } else {
            waveSessions = realm.objects(WaveSession.self).filter("startedAt >= %@ AND startedAt < %@", fromDate! , toDate!)
        }
        
        return loadWaveSessionsBySections(waveSessions : waveSessions)
    }

    static func loadWaveSessionsBySections(waveSessions : Results<WaveSession>) -> [Results<WaveSession>] {
        var waveSessionsBySections : [Results<WaveSession>] = []

        if waveSessions.count > 0 {
            
            var waveSessionsBySection : Results<WaveSession>!
            //  月ごとにまとめます
            
            let sortedWaveSessions = waveSessions.sorted(byKeyPath: "startedAt", ascending: true)
            var lastDate : Date = DateUtils.nextMonth(for : DateUtils.startOfMonth(for: (sortedWaveSessions.last?.startedAt)!))
            let firstDate = DateUtils.startOfMonth(for : (sortedWaveSessions.first?.startedAt)!)
            
            repeat {
                let preMonthDate = DateUtils.preMonth(for: lastDate)
                waveSessionsBySection = waveSessions.filter("startedAt >= %@ AND startedAt < %@", preMonthDate, lastDate).sorted(byKeyPath: "startedAt", ascending: false)
                if waveSessionsBySection.count > 0 {

                    waveSessionsBySections.append(waveSessionsBySection)
                }
                lastDate = preMonthDate
                
            } while firstDate < lastDate
            
        }
        return waveSessionsBySections
    }
    
    static func loadWaveSessions(realm: Realm) -> Results<WaveSession> {
        return realm.objects(WaveSession.self)
    }
    
    
    //
    //  waveを削除します
    //
    func remove(wave : Wave, fromRealm realm : Realm) {
        if let index = self.waves.index(of: wave) {
            //  realmから削除します
            try! realm.write() {
                self.waves.remove(at: index)
                self.calc(withWaveCalc: false)
            }
        }
    }
    
    //
    //  waveのindexをもどします
    //
    func index(ofWave : Wave) -> Int? {
        return self.waves.index(of: ofWave)
    }

    func surfPointName() -> String {
        if let surfPoint = self.surfPoint {
            return surfPoint.name
        } else {
            return ""
        }
    }
    
    
    func surfBoardName() -> String {
        if let surfBoard = self.surfBoard {
            return surfBoard.name
        } else {
            return ""
        }
    }
    
    static func surfPoint(fromLocationCoordinate: CLLocationCoordinate2D?, completion: ((_ surfpoint: SurfPoint?) -> Void)?) -> Bool {
        if let locationCoordinate = fromLocationCoordinate {
            //  位置情報から住所を取得します
            GeoUtils.address(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude) { (address, placemark) in
                
                var foundSurfPoint: SurfPoint? = nil
                
                if address != nil && placemark != nil {
                    
                    //  住所が一覧に存在するか調べます
                    if let surfPoint = SurfPoint.find(byAddressKey: address!, in: SurfPoint.surfPointArray) {
                        
                        foundSurfPoint = surfPoint
                        
                    } else {
                        
                        //  住所が一覧に存在しないのであらたに登録します
                        if let name : String = placemark!.pointName() {
                            
                            foundSurfPoint = SurfPoint.newSurfPoint(name: name, addressKey: address!, latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
                        }
                    }
                } else {
                    //   住所取得に失敗
                }
                
                completion?(foundSurfPoint)
            }
            
            return true

        } else {
            return false
        }
    }
}
