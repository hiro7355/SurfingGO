//
//  SessionDetailViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/11.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import RealmSwift
import Eureka
// プロトコル
protocol SessionEditViewControllerDelegate {
    func updated(waveSession : WaveSession?, atIndexPath indexPath : IndexPath?) -> Void
}

class SessionEditViewController: FormViewController, SurfBoardSettingViewControllerDelegate, SurfPointSettingViewControllerDelegate {
    var waveSession : WaveSession!
    var indexPath : IndexPath?
    var delegate : SessionEditViewControllerDelegate!
    var surfBoardArray : [SurfBoard]!
    let addSurfboardButtonName : String = "-- 新規追加 --"
    var surfPointArray : [SurfPoint]!
    var isNewSession : Bool = false
    var isNoWave : Bool = false
    let realm = try! Realm()

    //
    //  サーフボードが新規登録された
    //  MARK: SurfBoardSettingViewControllerDelegate
    //
    func updated(surfBoard: SurfBoard?, surfBoardArray: [SurfBoard], realm: Realm) {
        self.surfBoardArray = surfBoardArray
        self.waveSession.surfBoard = surfBoard      //  サーフボードを更新します（呼び出しもとで、すでにrealmのtry中になっています）
        
        let row : PickerInputRow<String> = self.form.rowBy(tag: "surfBoard")!
        row.options = self.surfBoardNames(fromSurfBoardArray: surfBoardArray)
        row.value = surfBoard?.name  //  この処理により、onChangeが呼び出される点に注意
    }
    
    func surfBoardNames(fromSurfBoardArray surfBoardArray : [SurfBoard]) -> [String] {
        var surfBoardNames : [String] = []
        surfBoardNames.append("")   //  空白を追加
        for surfBoard in surfBoardArray {
            if surfBoard.isPickup {
                //　選択対象のサーフボードのみ追加します
                surfBoardNames.append(surfBoard.name)
            }
        }
        surfBoardNames.append(addSurfboardButtonName)   //  新規追加ボタンを登録
        
        return surfBoardNames
    }

    //
    //  サーフポイントが新規登録された
    //  MARK: SurfPointSettingViewControllerDelegate
    //
    func updated(surfPoint: SurfPoint?, surfPointArray: [SurfPoint], realm: Realm) {
        self.surfPointArray = surfPointArray
        self.waveSession.surfPoint = surfPoint      //  サーフポイントを更新します（呼び出しもとで、すでにrealmのtry中になっています）
        
        let row : PickerInputRow<String> = self.form.rowBy(tag: "surfPoint")!
        row.options = self.surfPointNames(fromSurfPointArray: surfPointArray)
        row.value = surfPoint?.name  //  この処理により、onChangeが呼び出される点に注意
        
        self.addWaveSessionIfNew()
    }

    func addWaveSessionIfNew() {
        if self.isNewSession {
            //  セッションIDを設定します
            let app : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            self.waveSession.id = app.getAndUpdateNextWaveSessionId()
            
            self.realm.add(self.waveSession, update: true)
            
            self.delegate.updated(waveSession: self.waveSession, atIndexPath: nil)
            
            self.isNewSession = false
        }
    }

    func surfPointNames(fromSurfPointArray surfPointArray : [SurfPoint]) -> [String] {
        var names : [String] = []
        names.append("")   //  空白を追加
        for value in surfPointArray {
            if value.isPickup {
                //　選択対象のポイントのみ追加します
                names.append(value.name)
            }
        }
        names.append(addSurfboardButtonName)   //  新規追加ボタンを登録
        
        return names
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.waveSession.id == -1 {
            self.isNewSession = true
        }
        self.isNoWave = self.waveSession.waves.count == 0 ? true : false
        
        self.title = self.isNewSession ? "セッション新規登録" : "セッション編集"

        //  サーフボード名の配列を作成します
        SurfBoard.updateSurfBoards(realm: self.realm)
        self.surfBoardArray =  SurfBoard.surfBoardArray
        let surfBoardNames : [String] = self.surfBoardNames(fromSurfBoardArray : self.surfBoardArray)

        //  サーフポイント名の配列を作成します
        SurfPoint.updateSurfPoints(realm: self.realm)
        self.surfPointArray =  SurfPoint.surfPointArray
        let surfPointNames : [String] = self.surfPointNames(fromSurfPointArray : self.surfPointArray)
        
        self.form +++ Section()
            <<< PickerInputRow<String>("surfPoint"){
                $0.options = surfPointNames
                $0.title = "サーフポイント"
                if let name = self.waveSession.surfPoint?.name {
                    $0.value = name
                }
                }.onChange{ row in
                    let name = row.value!
                    if name == self.addSurfboardButtonName {
                        //  新規サーフポイント
                        let settingVC = SurfPointSettingViewController()
                        
                        settingVC.surfPoint = SurfPoint()
                        settingVC.surfPointArray = self.surfPointArray
                        settingVC.realm = self.realm
                        settingVC.delegate = self
                        
                        // 画面遷移
                        self.navigationController?.pushViewController(settingVC as UIViewController, animated: true)
                        
                        row.value = ""
                        
                    } else if name != "" {
                        
                        if self.waveSession.surfPoint?.name != name {
                            
                            if let surfPoint : SurfPoint = SurfPoint.find(byName : name, in : self.surfPointArray) {
                                
                                try! self.realm.write {
                                    self.waveSession.surfPoint = surfPoint
                                    
                                    self.addWaveSessionIfNew()
                                }
                            }
                            
                        }
                        
                    }
            }
            <<< PickerInputRow<String>("surfBoard"){
                $0.options = surfBoardNames
                $0.title = "サーフボード"
                if let name = self.waveSession.surfBoard?.name {
                    $0.value = name
                }
             }.onChange{ row in
                let name = row.value!
                if name == self.addSurfboardButtonName {
                    //  新規サーフボード
                    let surfboardSettingVC = SurfBoardSettingViewController()

                    surfboardSettingVC.surfBoard = SurfBoard()
                    surfboardSettingVC.surfBoardArray = self.surfBoardArray
                    surfboardSettingVC.realm = self.realm
                    surfboardSettingVC.delegate = self
                    
                    // 画面遷移
                    self.navigationController?.pushViewController(surfboardSettingVC as UIViewController, animated: true)
                    
                    row.value = ""
                    
                } else if name != "" {

                    if self.waveSession.surfBoard?.name != name {
                        
                        if let surfboard : SurfBoard = SurfBoard.find(byName : name, in : self.surfBoardArray) {
                            
                            try! self.realm.write {
                                self.waveSession.surfBoard = surfboard
                            }
                        }
                        
                    }
                    
                }
            }
            <<< PickerInputRow<String>() {
                $0.options = WaveSession.satisfactionLevelSmilyAndTexts()
                $0.title = "満足度"
                $0.value = self.waveSession.satisfactionLevelSmilyAndText()
                }.onChange{ row in
                    try! self.realm.write {
                        self.waveSession.setSatisfactionLevel(fromSmilyAndText: row.value!)
                    }
            }
            <<< PickerInputRow<String>() {
                $0.options = WaveSession.conditionLevelTexts
                $0.title = "波質"
                $0.value = self.waveSession.conditionLevelText()
                }.onChange{ row in
                    try! self.realm.write {
                        self.waveSession.setConditionLevelText(text: row.value!)
                    }
            }
            <<< startedAtRow()!
            <<< timeRow()!

            +++ Section("波")
            <<< PickerInputRow<String>() {
                $0.options = WaveSession.waveHeightTexts
                $0.title = "サイズ"
                $0.value = self.waveSession.waveHeightText()
                }.onChange{ row in
                    try! self.realm.write {
                        self.waveSession.setWaveHeightText(text: row.value!)
                    }
            }
            <<< PickerInputRow<String>() {
                $0.options = WaveSession.waveDirectionTexts
                $0.title = "うねりの向き"
                $0.value = self.waveSession.waveDirectionText()
                }.onChange{ row in
                    try! self.realm.write {
                        self.waveSession.setWaveDirectionText(text: row.value!)
                    }
            }
            +++ Section("風")
            <<< PickerInputRow<String>() {
                $0.options = WaveSession.windDirectionTexts
                $0.title = "風向き"
                $0.value = self.waveSession.windDirectionText()
                }.onChange{ row in
                    try! self.realm.write {
                        self.waveSession.setWindDirectionText(text: row.value!)
                    }
            }
            <<< PickerInputRow<String>() {
                $0.options = WaveSession.windWeightTexts
                $0.title = "強さ"
                $0.value = self.waveSession.windWeightText()
                }.onChange{ row in
                    try! self.realm.write {
                        self.waveSession.setWindWeightText(text: row.value!)
                    }
            }
            +++ Section("メモ")
            <<< TextAreaRow("memo"){
                $0.title = "メモ"
                $0.placeholder = "メモ"
                $0.value = self.waveSession.memo
                $0.textAreaHeight = TextAreaHeight.dynamic(initialTextViewHeight: 100)
                }.onChange{row in
                    if row.value != nil {
                        try! self.realm.write {
                            self.waveSession.memo = row.value!
                        }
                    }
            }

        //  波に一本以上乗っている場合は、ライディングセクションを追加します
        self.insertRidingResultSection()
    }
    
    func startedAtRow() -> BaseRow? {
        if isNewSession || !self.waveSession.isWatch {
            let row =  DateTimeRow("startedAt"){
                $0.title = "開始日時"
                //$0.dateFormatter = type(of: self).dateFormat
                $0.maximumDate = Date()
                $0.value = self.waveSession.startedAt
                $0.onChange{ [unowned self] row in
                     try! self.realm.write {
                        self.waveSession.startedAt = row.value!
                    }
                }
            }
            return row

        } else {
            
            let row =  LabelRow("startedAt"){
                $0.title = "開始日時"
                $0.value = self.waveSession.startedAtText()
            }
            return row
        }
    }

    func timeRow() -> BaseRow? {
        if isNewSession  || !self.waveSession.isWatch {
            let row = PickerInputRow<String>() {
                let unit : String = "分"
                for value in [30,60,90,120,150,180,210,240,270,300] {
                
                    $0.options.append( "\(value)\(unit)" )
                }
                $0.title = "時間"
                $0.value = String(Int(self.waveSession.time/60)) + unit
                $0.onChange{ [unowned self] row in
                    let value : String = row.value!
                    let minString = value.replacingOccurrences(of: unit, with: "")
                    
                    try! self.realm.write {
                        self.waveSession.time = Double(Int(minString)! * 60)
                    }
                }
            }
            return row
        } else {
            let row = LabelRow("time"){
                $0.title = "時間"
                $0.value = self.waveSession.timeText()
            }
            return row
        }
    }
    
    private func insertRidingResultSection() -> Void {
        if isNewSession  || isNoWave {
        } else {
            let section = Section("ライディング")
                <<< LabelRow("count"){
                    $0.title = "本数"
                    $0.value = self.waveSession.wavesCountText()
                }
                <<< LabelRow("totalDistance"){
                    $0.title = "総距離"
                    $0.value = self.waveSession.totalDistanceText()
                }
                <<< LabelRow("averageSpeed"){
                    $0.title = "平均速度"
                    $0.value = self.waveSession.averageSpeedText()
                }
                <<< LabelRow("longestDistance"){
                    $0.title = "最長"
                    $0.value = self.waveSession.longestDistanceText()
                }
                <<< LabelRow("topSpeed"){
                    $0.title = "最高速度"
                    $0.value = self.waveSession.topSpeedText()
            }
            
            self.form.insert(section, at:1)

        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.indexPath != nil {
            //  新規のとき以外は、更新通知します
            self.delegate.updated(waveSession: self.waveSession, atIndexPath: self.indexPath)
        }
    }
}
