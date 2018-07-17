//
//  Date+Ext.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2018/03/08.
//  Copyright © 2018年 ikaika software. All rights reserved.
//

import Foundation

public extension Date {
    var day: Int? {
        return Calendar.current.dateComponents([Calendar.Component.day], from: self).day
    }
    var year: Int? {
        return Calendar.current.dateComponents([Calendar.Component.year], from: self).year
    }
}
