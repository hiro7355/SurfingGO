//
//  Settings.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/10/18.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
class Settings {
    
    static let KEY_HEATSESSION : String = "HeatSession"
    static let KEY_AUTOLOCK : String = "AutoLock"
    static let KEY_HEATTIME : String = "HeatTime"

    static let KEY_LASTSESSION_STATEDAT : String = "LSStartedAt"
    static let KEY_LASTSESSION_TIME : String = "LSTime"
    static let KEY_LASTSESSION_WAVECOUNT : String = "LSWaveCount"
    static let KEY_LASTSESSION_LOGESTDISTANCE : String = "LSLongestDistance"
    static let KEY_LASTSESSION_TOPSPEED : String = "LSTopSpeed"
    static let KEY_LASTSESSION_TOTALDISTANCE : String = "LSTotalDistance"

    
    static func setUserDefault(value : Any, forKey : String) {
        
        // インスタンス生成
        let defaults = UserDefaults.standard
        
        // キーに値をそれぞれ保存
        defaults.set(value, forKey:forKey)
        
        // すぐに値を反映
        defaults.synchronize()
    }
    static func valueOfUserDefault(forKey : String, defaultValue : Any) -> Any {
        
        // インスタンス生成
        let defaults = UserDefaults.standard
        
        if let ret = defaults.value(forKey: forKey)  {
            return ret
        } else {
            return defaultValue
        }
        
    }

    
    
    static func isAutoLock() -> Bool {
        return Settings.valueOfUserDefault(forKey: KEY_AUTOLOCK, defaultValue: false) as! Bool
    }
    static func setAutoLock(on : Bool) -> Void {
        Settings.setUserDefault(value: on, forKey: KEY_AUTOLOCK)

    }
    static func isHeatSession() -> Bool {
        return Settings.valueOfUserDefault(forKey: KEY_HEATSESSION, defaultValue: true) as! Bool
    }
    static func setHeatSession(on : Bool) -> Void {
        Settings.setUserDefault(value: on, forKey: KEY_HEATSESSION)
    }
    
    //
    // ヒート時間（分）
    //
    static func heatTime() -> Int {
        return Settings.valueOfUserDefault(forKey: KEY_HEATTIME, defaultValue: 30) as! Int
    }
    static func setHeatTime(value : Int) -> Void {
        Settings.setUserDefault(value: value, forKey: KEY_HEATTIME)
        
    }

    //  最後のセッションの開始日時
    static func lastSessionStatedAt() -> Date? {
        var result : Date?
        let timeInterval : TimeInterval = Settings.valueOfUserDefault(forKey: KEY_LASTSESSION_STATEDAT, defaultValue: 0.0) as! TimeInterval
        if timeInterval != 0.0 {
            result = Date(timeIntervalSince1970 : timeInterval)
        }
        return result
    }
    static func setLastSessionStatedAt(value : Date) -> Void {
        Settings.setUserDefault(value: value.timeIntervalSince1970, forKey: KEY_LASTSESSION_STATEDAT)
        
    }

    //  最後のセッションの時間（秒）
    static func lastSessionTime() -> Int {
        return Settings.valueOfUserDefault(forKey: KEY_LASTSESSION_TIME, defaultValue: 0) as! Int
    }
    static func setLastSessionTime(value : Int) -> Void {
        Settings.setUserDefault(value: value, forKey: KEY_LASTSESSION_TIME)
    }
    //  最後のセッションの本数
    static func lastSessionWaveCount() -> Int {
        return Settings.valueOfUserDefault(forKey: KEY_LASTSESSION_WAVECOUNT, defaultValue: 0) as! Int
    }
    static func setLastSessionWaveCount(value : Int) -> Void {
        Settings.setUserDefault(value: value, forKey: KEY_LASTSESSION_WAVECOUNT)
    }
    //  最後のセッションの最長距離（メートル）
    static func lastSessionLongestDistance() -> Double {
        return Settings.valueOfUserDefault(forKey: KEY_LASTSESSION_LOGESTDISTANCE, defaultValue: 0) as! Double
    }
    static func setLastSessionLongestDistance(value : Double) -> Void {
        Settings.setUserDefault(value: value, forKey: KEY_LASTSESSION_LOGESTDISTANCE)
    }
    //  最後のセッションの合計距離（メートル）
    static func lastSessionTotalDistance() -> Double {
        return Settings.valueOfUserDefault(forKey: KEY_LASTSESSION_TOTALDISTANCE, defaultValue: 0) as! Double
    }
    static func setLastSessionTotalDistance(value : Double) -> Void {
        Settings.setUserDefault(value: value, forKey: KEY_LASTSESSION_TOTALDISTANCE)
    }

    //  最後のセッションのトップスピード（m/s）
    static func lastSessionTopSpeed() -> Double {
        return Settings.valueOfUserDefault(forKey: KEY_LASTSESSION_TOPSPEED, defaultValue: 0) as! Double
    }
    static func setLastSessionTopSpeed(value : Double) -> Void {
        Settings.setUserDefault(value: value, forKey: KEY_LASTSESSION_TOPSPEED)
    }
    
    static func setLastSession(result : WaveSession) {
        
        Settings.setLastSessionStatedAt(value: result.startedAt)
        
        Settings.setLastSessionTime(value: Int(result.time))
        
        Settings.setLastSessionTopSpeed(value: result.topSpeed)
        
        Settings.setLastSessionWaveCount(value: result.waves.count)
        
        Settings.setLastSessionTotalDistance(value: result.totalDistance)
        
        Settings.setLastSessionLongestDistance(value: result.longestDistance)
    }
}
