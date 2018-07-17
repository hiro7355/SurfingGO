//
//  SurfPoint.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/16.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
import RealmSwift

class SurfPoint : Object  {
    
    //  realmに保存
    @objc dynamic var id : Int = -1                   //  ID
    @objc dynamic var name : String = ""              //  ポイント名（ユーザー入力）
    @objc dynamic var address : String = ""           //  住所（ユーザー入力）
    @objc dynamic var direction : Int = 0             //  向き（0:北、90:東、180:南、270:西）
    @objc dynamic var memo : String = ""            //  メモ
    @objc dynamic var isPickup : Bool = true        //  選択対象からはずす場合はfalse
    @objc dynamic var addressKey : String = ""        //  住所（システム設定）
    @objc dynamic var isAddressByLocation : Bool = false             //  位置情報から住所を取得した場合true(住所変更不可）
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0

    static var surfPoints : Results<SurfPoint>!
    static var nextSurfPointId : Int = 1
    static var surfPointArray : [SurfPoint] = []

    static let directionTexts : [String] = ["北", "北北東", "北東", "東北東", "東","東南東", "南東", "南南東", "南", "南南西", "南西", "西南西", "西", "西北西", "北西", "北北西"]
    static let directionValues : [Int] = [0, 23, 45, 68, 90, 113, 135, 158, 180, 203, 225, 248, 270, 293, 315, 338]

    static func newSurfPoint(name : String, addressKey : String, latitude : Double, longitude : Double ) -> SurfPoint {
        let surfPoint = SurfPoint()
        surfPoint.id = SurfPoint.getAndUpdateNextSurfboardId()
        surfPoint.name = name
        surfPoint.address = addressKey
        surfPoint.addressKey = addressKey

        surfPoint.latitude = latitude
        surfPoint.longitude = longitude
        surfPoint.isAddressByLocation = true
        
        return surfPoint
    }
    
    //　プライマリーキーの設定
    override static func primaryKey() -> String? {
        return "id"
    }

    //
    //  サーフボード一覧をRealmから取得します
    //
    static func updateSurfPoints(realm : Realm) -> Void {
        //  realmからデータを取得します
        SurfPoint.surfPoints = realm.objects(SurfPoint.self).sorted(byKeyPath: "id")
        if SurfPoint.surfPoints.count > 0 {
            SurfPoint.nextSurfPointId = (SurfPoint.surfPoints.last?.id)! + 1
        }
        
        SurfPoint.surfPointArray.removeAll()
        for surfPoint in SurfPoint.surfPoints {
            SurfPoint.surfPointArray.append(surfPoint)
        }
    }
    
    //
    //  サーフポイント名一覧をもどします
    //
    static func names(items : [SurfPoint]) -> [String] {
        var values : [String] = []
        for item in items {
            values.append(item.name)
        }
        return values
    }
    
    static func ids(items : [SurfPoint]) -> [Int] {
        var values : [Int] = []
        for item in items {
            values.append(item.id)
        }
        return values
    }
    
    //
    //  名前の一致するサーフポイントを見つけます
    //
    static func find(byName name : String, in surfPoints : [SurfPoint] ) -> SurfPoint? {
        var result : SurfPoint? = nil
        
        for surfPoint in surfPoints {
            if name == surfPoint.name {
                result = surfPoint
                break
            }
        }
        return result
    }

    static func isExist(byName name : String, in surfPoints : [SurfPoint] ) -> Bool {
        return SurfPoint.find(byName: name, in: surfPoints) != nil ? true : false
    }
    //
    //  アドレスの一致するサーフポイントを見つけます
    //
    static func find(byAddressKey addressKey : String, in surfPoints : [SurfPoint] ) -> SurfPoint? {
        var result : SurfPoint? = nil
        
        for surfPoint in surfPoints {
            if addressKey == surfPoint.addressKey {
                result = surfPoint
                break
            }
        }
        return result
    }

    static func getAndUpdateNextSurfboardId() -> Int {
        let result = SurfPoint.nextSurfPointId
        SurfPoint.nextSurfPointId = SurfPoint.nextSurfPointId + 1
        return result
    }
    
    // 向き
    static func direction(fromLabel label : String) -> Int {
        for index in 0..<SurfPoint.directionTexts.count {
            if label == SurfPoint.directionTexts[index] {
                return SurfPoint.directionValues[index]
            }
        }
        return -1
    }
    static func directionLabel(fromValue value : Int) -> String {
        for index in 0..<SurfPoint.directionValues.count {
            if value == SurfPoint.directionValues[index] {
                return SurfPoint.directionTexts[index]
            }
        }
        return ""
    }
    // 向き
    func directionText() -> String {
        return SurfPoint.directionLabel(fromValue : self.direction)
    }
    func setDirectionText(text : String) -> Void {
        self.direction = SurfPoint.direction(fromLabel: text)
    }
}
