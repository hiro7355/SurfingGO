//
//  ArrayUtils.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2018/03/08.
//  Copyright © 2018年 ikaika software. All rights reserved.
//

import Foundation
class ArrayUtils {

    /// int配列をString配列に変換
    static func intToStringArray(intValues: [Int]) -> [String] {
        return intValues.map { (String($0)) }
    }
}
