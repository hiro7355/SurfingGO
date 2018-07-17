//
//  NumUtils.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/15.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
class NumUtils {
    //
    //  少数第一位までの値にします
    //
    static func value1(forFloatValue : Float) -> Float {
        let value = Int(forFloatValue*10)
        return Float(value / 10)
    }
    static func value1(forDoubleValue : Double) -> Double {
        if forDoubleValue.isNaN {
            return 0
        } else {
            let value = Int(forDoubleValue*10)
            return Double(value / 10)
        }
    }
    
    //
    //  秒速から時速に変換します
    //
    static func kph(fromMps : Double) -> Double {
        return NumUtils.value1(forDoubleValue: (fromMps * 3.6))
    }
    static func mps(fromKph : Double) -> Double {
        return fromKph / 3.6
    }
}
