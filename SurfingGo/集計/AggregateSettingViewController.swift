//
//  AggregateSettingViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/14.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import Eureka
import RealmSwift

enum AggregateType : Int {
    case Point = 0  //  ポイント
    case Surfboard = 1  //  サーフボード
    case WaveHeight = 2  //  サイズ
    case Condition = 3 //  波質
    case SatisfactionLevel = 4  //  満足度
    case WaveDirection = 5  //  うねりの向き
    case WindDirection = 6 //  風向き
    case WindWeight = 7 //  風の強さ
    case Year = 8 //  年度
    case TopSpeed = 9 //  最高速度
    case LongestDistance = 10 //  最長距離
}

class AggregateSettingViewController: FormViewController {

    var startedOn : Date = Date()
    var endedOn : Date = Date()
    var aggregateType : AggregateType = AggregateType.TopSpeed
    
    
    static let AggregateTypeNamesDict : [AggregateType : String] = [AggregateType.Point : "サーフポイント", AggregateType.Surfboard :  "サーフボード", AggregateType.WaveHeight :  "波のサイズ" , AggregateType.Condition : "波質",  AggregateType.SatisfactionLevel : "満足度", AggregateType.WaveDirection : "うねりの向き", AggregateType.WindDirection : "風向き" ,  AggregateType.WindWeight : "風の強さ",  AggregateType.Year : "年度",  AggregateType.TopSpeed : "最高速度",  AggregateType.LongestDistance : "最長距離"]
    static let AggregateTypeNamesArray : [String] = [
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.TopSpeed]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.LongestDistance]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.Point]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.Surfboard]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.WaveHeight]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.Condition]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.SatisfactionLevel]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.WaveDirection]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.WindDirection]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.WindWeight]!,
                                                     AggregateSettingViewController.AggregateTypeNamesDict[AggregateType.Year]!,
                                                     ]

    
    static var dateFormat: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        
        return f
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "集計設定"
        
        // 最初のセッションの日付を開始日に設定します
        let realm = try! Realm()
        if let waveSession = realm.objects(WaveSession.self).first {
            self.startedOn = waveSession.startedAt
        } else {
            self.startedOn = DateUtils.preYear(for: Date())
        }
        
        form +++ Section()
            <<< PickerInputRow<String>(){
                $0.title = "集計対象"
                $0.options = type(of: self).AggregateTypeNamesArray
                $0.value = type(of: self).AggregateTypeNamesDict[self.aggregateType]
                
                }.onChange{ row in
                    let keys = (type(of: self).AggregateTypeNamesDict as NSDictionary).allKeys(for : row.value!)
                    self.aggregateType = keys[0] as! AggregateType
        }

        form +++ Section("集計期間")
            <<< DateRow(){
                $0.title = "開始"
                $0.minimumDate = type(of: self).dateFormat.date(from: "1900/01/01") ?? Date()
                $0.maximumDate = Date()
                $0.value = self.startedOn
                $0.onChange{ [unowned self] row in
                    self.startedOn = row.value ?? Date()
                }
            }
            <<< DateRow(){
                $0.title = "終了"
                $0.minimumDate = type(of: self).dateFormat.date(from: "1900/01/01") ?? Date()
                $0.maximumDate = Date()
                $0.value = self.endedOn
                $0.onChange{ [unowned self] row in
                    self.endedOn = row.value ?? Date()
                }
            }
            +++ Section()
            <<< ButtonRow(){
                $0.title = "集計実行"
                $0.onCellSelection({ (cell, row) in
                    self.pushAggregateVC()
                })
        }

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    //
    //  Doneボタンタップ時の処理
    //
    @objc dynamic func clickDoneButton(){
        
        self.pushAggregateVC()
        
    }
    
    private func pushAggregateVC() {
        let vc = AggregateChartViewController()
        vc.startedOn = self.startedOn
        vc.endedOn = self.endedOn
        vc.aggregateType = self.aggregateType
        vc.hidesBottomBarWhenPushed = true    //  タブバーを非表示にします
        self.navigationController?.pushViewController(vc as UIViewController, animated: true)
    }
}
