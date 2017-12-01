//
//  SurfBoard.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/11.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
import RealmSwift

class SurfBoard : Object  {
    
    //  realmに保存
    @objc dynamic var id : Int = -1                        //  セッションID
    @objc dynamic var name : String = ""            //  ボード名
    @objc dynamic var length : Float = 0            //  長さ（単位フィート）
    @objc dynamic var width : Float = 0             //  幅（単位インチ）
    @objc dynamic var thickness : Float = 0         //  厚さ（単位インチ）
    @objc dynamic var volume : Float = 0            //  ボリューム（単位リットル）
    @objc dynamic var memo : String = ""            //  メモ
    @objc dynamic var isPickup : Bool = true        //  選択対象からはずす場合はfalse
    //
    static var surfBoards : Results<SurfBoard>!
    static var nextSurfboardId : Int = 1
    static var surfBoardArray : [SurfBoard] = []

    static func updateSurfBoards(realm : Realm) -> Void {
        //  realmからデータを取得します
        SurfBoard.surfBoards = realm.objects(SurfBoard.self)
        if SurfBoard.surfBoards.count > 0 {
            SurfBoard.nextSurfboardId = (SurfBoard.surfBoards.last?.id)! + 1
        }
        
        SurfBoard.surfBoardArray.removeAll()
        for surfBoard in SurfBoard.surfBoards {
            SurfBoard.surfBoardArray.append(surfBoard)
        }
    }

    
    //　プライマリーキーの設定
    override static func primaryKey() -> String? {
        return "id"
    }


    //
    //  サーフボード名一覧をもどします
    //
    static func names(items : [SurfBoard]) -> [String] {
        var values : [String] = []
        for item in items {
            values.append(item.name)
        }
        return values
    }
    
    static func ids(items : [SurfBoard]) -> [Int] {
        var values : [Int] = []
        for item in items {
            values.append(item.id)
        }
        return values

    }
    
    //
    //  名前の一致するサーフボードを見つけます
    //
    static func find(byName name : String, in surfBoards : [SurfBoard] ) -> SurfBoard? {
        
        var result : SurfBoard? = nil
        
        for surfBoard in surfBoards {
            if name == surfBoard.name {
                result = surfBoard
                break
            }
        }
        
        return result
    }
    static func isExist(byName name : String, in surfBoards : [SurfBoard] ) -> Bool {
        
        return SurfBoard.find(byName: name, in: surfBoards) != nil ? true : false
    }

    static func getAndUpdateNextSurfboardId() -> Int {
        let result = SurfBoard.nextSurfboardId
        SurfBoard.nextSurfboardId = SurfBoard.nextSurfboardId + 1
        return result
    }

}
