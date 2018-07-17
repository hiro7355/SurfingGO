//
//  Wave.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/07.
//  Copyright © 2017年 ikaika software. All rights reserved.
//
import Foundation
import CoreLocation
import RealmSwift

class Wave : Object {
    
    //  realmに保存
    var locationList : List<Location> = List<Location>()
    @objc dynamic var startedAt : Date = Date()     //  ライディング開始日時
    @objc dynamic var time : TimeInterval = 0       //  ライディング時間（単位秒）
    @objc dynamic var distance : Double = 0         //  ライディング距離（単位メートル）
    @objc dynamic var averageSpeed : Double = 0     //  平均速度（単位秒速メートル）
    @objc dynamic var topSpeed : Double = 0         //  最高速度（単位秒速メートル）

    var cllocations : [CLLocation] = []
    var tempLocations : [CLLocation] = []

    override func isEqual(_ object: Any?) -> Bool {
        let obj = object as! Wave
        if self.startedAt == obj.startedAt && self.time == obj.time && self.distance == obj.distance && self.averageSpeed == obj.averageSpeed && self.topSpeed == obj.topSpeed {
            return true
        } else {
            return false
        }
    }
    
    func addLocation(location : CLLocation) {
        cllocations.append(location)
    }

    func reset() {
        cllocations = []
        tempLocations = []
    }
    
    func addTempLocation(location : CLLocation) {
        tempLocations.append(location)
    }
    
    func commitTempLocations(location : CLLocation) {
        cllocations.append(contentsOf: tempLocations)
        cllocations.append(location)
        tempLocations = []
    }
    
    func commit() {
        if locationList.count == 0 {
            //  Realmように位置情報を変換してリストに追加します
            for cllocation in cllocations {
                // Realmのobjectに変換します
                let location : Location = Location()
                location.initFrom(CLLocation: cllocation)
                //  リストに追加します
                locationList.append(location)
            }
        }
    }
    
    //
    //  realmから取得したロケーション情報を CLLocationの配列に展開します
    //
    func loadToCLLocations() {
        if cllocations.count == 0 && locationList.count > 0 {
            for location in locationList {
                let cllocation : CLLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), altitude: location.altitude, horizontalAccuracy : location.horizontalAccuracy, verticalAccuracy : location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
                cllocations.append(cllocation)
            }
        }
    }
    
    func toString() -> String {
        loadToCLLocations()
        
        if cllocations.count >= 2 {
            let lastLocation : CLLocation = cllocations.last!
            let startLocation : CLLocation = cllocations.first!
            let distance : Double = startLocation.distance(from: lastLocation)
            let time : Double = lastLocation.timestamp.timeIntervalSince1970 - startLocation.timestamp.timeIntervalSince1970
            
            return "距離:\(distance)メートル 時間:\(time)秒 開始日時:\(startLocation.timestamp)"
        } else {
            return "No Ride!"
        }
    }
    
    //
    //  位置情報からライディング開始日時、ライディング時間、距離、平均スピード、トップスピードをもとめます
    //  距離は、スタートから終了まで
    //  平均スピードは、距離/ライディング時間
    //
    func calc() {
        if cllocations.count >= 2 {
        
            let startLocation : CLLocation = cllocations.first!
            let lastLocation : CLLocation = cllocations.last!

            //  ライディング開始日時
            self.startedAt = startLocation.timestamp

            //  ライディング時間
            self.time = lastLocation.timestamp.timeIntervalSince1970 - startLocation.timestamp.timeIntervalSince1970
            

            var preLocation : CLLocation = startLocation
            
            var distance : Double = 0
            var topSpeed : Double = 0

            var firstLocation : CLLocation?
            
            for cllocation in cllocations {

                if firstLocation == nil {
                    firstLocation = cllocation
                } else if firstLocation?.coordinate.latitude == cllocation.coordinate.latitude && firstLocation?.coordinate.longitude == cllocation.coordinate.longitude {
                    // TODO: ここにくるのはおかしいのでなおすこと
                    print("位置情報の記録がおかしい！！")
                    break
                }
                if cllocation != preLocation {
                    //  距離を求めます
                    distance = distance + cllocation.distance(from: preLocation)
                    
                    //  トップスピードを求めめます
                    if cllocation.speed > topSpeed {
                        topSpeed = cllocation.speed
                    }
                }
                //  一つ前のロケーションを更新します
                preLocation = cllocation

            }
            
            self.distance = distance
            self.topSpeed = topSpeed
            self.averageSpeed = distance / self.time
        }
    }
}
