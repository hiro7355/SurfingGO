//
//  SurfBoardSettingViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/12.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import Eureka
import RealmSwift
// プロトコル
protocol SurfBoardSettingViewControllerDelegate {
    func updated(surfBoard : SurfBoard?, surfBoardArray : [SurfBoard], realm : Realm) -> Void
}
class SurfBoardSettingViewController: FormViewController {

    var surfBoard : SurfBoard!
    var surfBoardArray : [SurfBoard]!
    var delegate : SurfBoardSettingViewControllerDelegate!
    var realm : Realm!

    var isNewSurfboard : Bool = false
    var newName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if surfBoard.id == -1 {
            self.isNewSurfboard = true
        }
        self.title = self.isNewSurfboard ? "サーフボードの新規登録" : "サーフボードの設定"
        
        let realm : Realm = self.realm!

        form +++ Section()
            <<< TextRow("name"){
                $0.title = "ボード名"
                $0.placeholder = ""
                $0.value = self.surfBoard.name
                }.onChange{row in
                    self.newName = row.value
            }
            +++ Section("メモ")
            <<< TextAreaRow("memo"){
                $0.title = "メモ"
                $0.placeholder = "メモ"
                $0.value = self.surfBoard?.memo
                $0.textAreaHeight = TextAreaHeight.dynamic(initialTextViewHeight: 100)
                }.onChange{row in
                    if row.value != nil {
                        try! realm.write {
                            self.surfBoard.memo = row.value!
                        }
                    }
        }
            +++ Section()
            <<< ButtonRow(){
                $0.title =  "完了"
                $0.onCellSelection({ (cell, row) in
                    if let newName : String = self.newName {
                        
                        try! realm.write {
                            if let findSurfboard = SurfBoard.find(byName: newName, in: self.surfBoardArray) {
                                //  存在している場合は、既存のサーフボードを設定します
                                self.delegate.updated(surfBoard: findSurfboard, surfBoardArray: self.surfBoardArray, realm: realm)
                            } else {
                                self.surfBoard.name = newName
                                
                                if self.isNewSurfboard {
                                    
                                    //  サーフボードIDを設定します
                                    self.surfBoard.id = SurfBoard.getAndUpdateNextSurfboardId()
                                    
                                    realm.add(self.surfBoard, update: true)
                                    
                                    self.surfBoardArray.append(self.surfBoard)
                                    
                                    self.isNewSurfboard = false
                                }
                                self.delegate.updated(surfBoard: self.surfBoard, surfBoardArray: self.surfBoardArray, realm: realm)
                            }
                        }
                    }
                    self.navigationController?.popViewController(animated: true)
                })
            }
            +++ Section()
            <<< ButtonRow(){
                $0.title =  "キャンセル"
                $0.onCellSelection({ (cell, row) in
                    self.navigationController?.popViewController(animated: true)
                })
        }
        if  isNewSurfboard == false {
            form +++ Section()
            <<< ButtonRow(){
                $0.title = "削除"
                $0.cell.tintColor = UIColor.red
                $0.onCellSelection({ (cell, row) in
                    AlertViewUtils.showConfirmView(forViewController: self as UIViewController, title: "削除の確認", message: "削除してよろしいですか？", doneTitle: "はい", cancelTitle: "キャンセル", doneHandler: { (aa) in
                        //  セッションに割当があるか確認します
                        if WaveSession.loadWaveSessions(realm: self.realm).filter("surfBoard.id=\(self.surfBoard.id)").count != 0 {
                            AlertViewUtils.showConfirmView(forViewController: self as UIViewController, title: "\(self.surfBoard.name)の削除", message: "このサーフボードはセッションに割当があります。削除するとセッションのサーフボード名が空白になります。削除してよろしいですか？", doneTitle: "はい", cancelTitle: "キャンセル", doneHandler: { (aa) in
                                //  削除
                                self.deleteSurfboard()
                            })
                        } else {
                            //  割当がないのですぐに削除
                            self.deleteSurfboard()
                        }
                    })
                })
            }
        }
    }
    
    private func deleteSurfboard() {
        //  削除します
        try! realm.write {
            self.realm.delete(self.surfBoard)
        }
        
        //  削除したことを通知します
        self.delegate.updated(surfBoard: nil, surfBoardArray: self.surfBoardArray, realm: self.realm)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //  画面閉じます
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
