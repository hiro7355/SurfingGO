//
//  SurfPointSettingViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/16.
//  Copyright © 2017年 ikaika software. All rights reserved.
//


import UIKit
import Eureka
import RealmSwift
// プロトコル
protocol SurfPointSettingViewControllerDelegate {
    func updated(surfPoint : SurfPoint?, surfPointArray : [SurfPoint], realm : Realm) -> Void
}
class SurfPointSettingViewController: FormViewController {
    
    var surfPoint : SurfPoint!
    var surfPointArray : [SurfPoint]!
    var delegate : SurfPointSettingViewControllerDelegate!
    var realm : Realm!
    var isNewSurfPoint : Bool = false
    var newName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if surfPoint.id == -1 {
            self.isNewSurfPoint = true
        }
        self.title = self.isNewSurfPoint ? "サーフポイントの新規登録" : "サーフポイントの設定"
        
        let realm : Realm = self.realm!
        
        form +++ Section()
            <<< TextRow("name"){
                $0.title = "ポイント"
                $0.placeholder = "ポイント名を入力"
                $0.value = self.surfPoint.name
                }.onChange{row in
                    
                    self.newName = row.value
            }
            +++ Section("メモ")
            <<< TextAreaRow("memo"){
                $0.title = "メモ"
                $0.placeholder = "メモを入力"
                $0.value = self.surfPoint.memo
                $0.textAreaHeight = TextAreaHeight.dynamic(initialTextViewHeight: 100)
                }.onChange{row in
                    if let newMemo = row.value {
                        try! realm.write {
                            self.surfPoint.memo = newMemo
                        }
                    }
                    
            }
    
            +++ Section()
            <<< ButtonRow(){
                $0.title =  "完了"
                $0.onCellSelection({ (cell, row) in
                    if let newName : String = self.newName {
                        
                        try! realm.write {
                            
                            if let findSurfPoint = SurfPoint.find(byName: newName, in: self.surfPointArray) {
                                //  存在している場合は、既存のサーフポイントを設定します
                                self.delegate.updated(surfPoint: findSurfPoint, surfPointArray: self.surfPointArray, realm: realm)
                            } else {
                                self.surfPoint.name = newName
                                
                                if self.isNewSurfPoint {
                                    //  IDを設定します
                                    self.surfPoint.id = SurfPoint.getAndUpdateNextSurfboardId()
                                    
                                    realm.add(self.surfPoint, update: true)
                                    
                                    self.surfPointArray.append(self.surfPoint)
                                    
                                    
                                    self.isNewSurfPoint = false
                                }
                                
                                self.delegate.updated(surfPoint: self.surfPoint, surfPointArray: self.surfPointArray, realm: realm)
                            }
                        }
                    }
                    self.navigationController?.popViewController(animated: true)
                })
        }
            +++ Section()
            <<< ButtonRow(){
                $0.title =  "キャンセル"
                //                    $0.cell.tintColor = UIColor.red
                $0.onCellSelection({ (cell, row) in
                    self.navigationController?.popViewController(animated: true)
                })
        }

        if  isNewSurfPoint == false {
            form
                +++ Section()
                <<< ButtonRow(){
                    $0.title = "削除"
                    $0.cell.tintColor = UIColor.red
                    $0.onCellSelection({ (cell, row) in
                        
                        AlertViewUtils.showConfirmView(forViewController: self as UIViewController, title: "削除の確認", message: "削除してよろしいですか？", doneTitle: "はい", cancelTitle: "キャンセル", doneHandler: { (aa) in
                            
                            //  セッションに割当があるか確認します
                            if WaveSession.loadWaveSessions(realm: self.realm).filter("surfPoint.id=\(self.surfPoint.id)").count != 0 {
                                AlertViewUtils.showConfirmView(forViewController: self as UIViewController, title: "\(self.surfPoint.name)の削除", message: "このサーフポイントはセッションに割当があります。削除するとセッションのサーフポイント名が空白になります。削除してよろしいですか？", doneTitle: "はい", cancelTitle: "キャンセル", doneHandler: { (aa) in
                                    
                                    //  ポイント削除
                                    self.deleteSurfpoint()
                                    
                                })

                                
                            } else {
                                //  割当がないのですぐに削除
                                self.deleteSurfpoint()
                            }
                        })
                    })
            }
        }

    }
    
    private func deleteSurfpoint() {
        //  削除します
        try! realm.write {
            self.realm.delete(self.surfPoint)
        }
        
        //  削除したことを通知します
        self.delegate.updated(surfPoint: nil, surfPointArray: self.surfPointArray, realm: self.realm)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //  画面閉じます
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
