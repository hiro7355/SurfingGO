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
                    
                    if let newName : String = row.value {
                        
                        
                      //  if !SurfPoint.isExist(byName: newName, in: self.surfPointArray) {
                            
                            
                            try! realm.write {
                                
                                
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
                            
                  //      }
                        
                    }
                    
            }
            /*
            //  TODO: 新規のときは表示しないようにすること
            <<< SwitchRow("isPickup") {
                $0.title = "選択対象"
                $0.value = self.surfPoint.isPickup
                }.onChange { row in
                    try! realm.write {
                        self.surfPoint.isPickup = row.value!
                    }
            }
 */
            <<< TextRow("address"){
                $0.title = "住所"
                $0.placeholder = "サーフポイントの住所を入力"
                $0.value = self.surfPoint.address
                }.onChange{row in
                    
                    if let newAddress : String = row.value {
                        
                        try! realm.write {
                            self.surfPoint.address = newAddress
                        }
                        
                    }
            }
            <<< PickerInputRow<String>() {
                $0.options = SurfPoint.directionTexts
                $0.title = "向き"
                $0.value = self.surfPoint.directionText()
                }.onChange{ row in
                    try! self.realm.write {
                        self.surfPoint.setDirectionText(text: row.value!)
                    }
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
    
        
        if  isNewSurfPoint == false {
            form    +++ Section()
                <<< ButtonRow(){
                    $0.title = "削除"
                    $0.cell.tintColor = UIColor.red
                    $0.onCellSelection({ (cell, row) in
                        
                        AlertViewUtils.showConfirmView(forViewController: self as UIViewController, title: "削除の確認", message: "削除してよろしいですか？", doneTitle: "はい", cancelTitle: "キャンセル", doneHandler: { (aa) in
                            
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
                            
                            
                        })
                    })
            }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
