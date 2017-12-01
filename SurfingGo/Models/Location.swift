//
//  Location.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/09.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift

class Location : Object {
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var altitude: Double = 0
    @objc dynamic var horizontalAccuracy: Double = 0
    @objc dynamic var verticalAccuracy: Double = 0
    @objc dynamic var course: Double = 0
    @objc dynamic var speed: Double = 0
    @objc dynamic var timestamp: Date = Date()
    
    func initFrom(CLLocation location : CLLocation) -> Void {
        
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.altitude
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy
        course = location.course
        speed = location.speed
        timestamp = location.timestamp
    }
    
}
