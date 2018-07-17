//
//  DateUtiles .swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/09/29.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
import UIKit

class DateUtils {
    static func dateFromString(string: String, format: String) -> NSDate {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: string)! as NSDate
    }
    
    //  "yyyy/MM/dd HH:mm:ss z"
    static func stringFromDate(date: NSDate, format: String) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date as Date)
    }
    
    //  秒をmm:SSに変換します
    static func stringFromTimeinterval(timeinterval : TimeInterval) -> String {
        let time : Int = Int(timeinterval)
        let min : Int = time / 60
        let sec  : Int = time % 60
        return "\(min):\(sec)"
    }
    //  秒をmm分SS秒に変換します
    static func stringFromTimeintervalInJapanese(timeinterval : TimeInterval) -> String {
        let time : Int = Int(timeinterval)
        let min : Int = time / 60
        let sec  : Int = time % 60
        return "\(min)分\(sec)秒"
    }
    //  秒をmm'SS''に変換します
    static func stringFromTimeintervalInEng(timeinterval : TimeInterval) -> String {
        let time : Int = Int(timeinterval)
        let min : Int = time / 60
        let sec  : Int = time % 60
        return "\(min)'\(sec)''"
    }

    static func weakDayString(forDate date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return calendar.standaloneWeekdaySymbols[weekday - 1]
    }

    //  00:00:00にします
    static func startOfDay(for date : Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: date)
    }
    
    //  月初の00:00:00にします
    static func startOfMonth(for date : Date) -> Date {
        let calendar = Calendar.current
        // 月初
        let comps = calendar.dateComponents([.year, .month], from: date)
        let firstday : Date = calendar.date(from: comps)!
        return firstday
    }
    
    static func nextMonth(for date : Date) -> Date {
        // 翌月
        let add = DateComponents(month: 1, day: 0)
        return Calendar.current.date(byAdding: add, to: date)!
    }
    static func preMonth(for date : Date) -> Date {
        // 前月
        let add = DateComponents(month: -1, day: 0)
        return Calendar.current.date(byAdding: add, to: date)!
    }

    static func preYear(for date : Date) -> Date {
        // 前年
        let add = DateComponents(month: -12, day: 0)
        return Calendar.current.date(byAdding: add, to: date)!
    }

    static func addTime(for date : Date, second: Int) -> Date {
        let add = DateComponents(second: second)
        return Calendar.current.date(byAdding: add, to: date)!
    }
    
    static func weakDayString(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return calendar.standaloneWeekdaySymbols[weekday - 1]
    }
    
    //  日付の差を取得します
    static func dayInterval(fromDate : Date , toDate: Date) -> Int {
        let from = DateUtils.startOfDay(for: toDate) as NSDate
        let timeInterval = from.timeIntervalSince(DateUtils.startOfDay(for: fromDate) )
        return Int(timeInterval/60/60/24)
    }

    //  1月1日0時0分0秒を返します
    static func startDateOfYear(year: Int) -> Date {
        var comp = DateComponents()
        comp.year = year
        comp.month = 1
        comp.day = 1
        comp.hour = 0
        comp.minute = 0
        comp.second = 0
        return Calendar.current.date(from: comp)!
    }
    // 12月31日23時59分59秒を返します
    static func endDateOfYear(year: Int) -> Date {
        var comp = DateComponents()
        comp.year = year
        comp.month = 12
        comp.day = 31
        comp.hour = 23
        comp.minute = 59
        comp.second = 59
        return Calendar.current.date(from: comp)!
    }
}
