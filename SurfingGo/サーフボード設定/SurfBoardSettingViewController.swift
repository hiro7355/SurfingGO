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
                    
                    if row.value != nil {
                        
                        let newName : String = row.value!
                        
                        if !SurfBoard.isExist(byName: newName, in: self.surfBoardArray) {
                            
                            
                            try! realm.write {
                                
                                
                                self.surfBoard.name = row.value!
                                
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
                    
            }
            /*
            //  TODO: 新規のときは表示しないようにすること
            <<< SwitchRow("isPickup") {
                $0.title = "選択対象"
                $0.value = self.surfBoard.isPickup
                }.onChange { row in
                    try! realm.write {
                        self.surfBoard.isPickup = row.value!
                    }
            }
            */
            /*
            <<< PickerInputRow<String>(){
                $0.options = ["5.8", "5.9", "6.0", "6.1", "6.2", "6.3"]
                $0.title = "長さ"
                $0.value = String(describing: self.surfBoard?.length)
                }.onChange{ row in
                    let value : Float = Float(row.value!)!
                    try! realm.write {
                        self.surfBoard.length = value
                    }
            }
            <<< PickerInputRow<String>(){
                $0.options = ["18", "18.5", "19", "20"]
                $0.title = "幅"
                $0.value = String(describing: self.surfBoard?.width)
                }.onChange{ row in
                    let value : Float = Float(row.value!)!
                    try! realm.write {
                        self.surfBoard.width = value
                    }
            }
            <<< PickerInputRow<String>(){
                $0.options = ["1", "2", "3"]
                $0.title = "厚さ"
                $0.value = String(describing: self.surfBoard?.thickness)
                }.onChange{ row in
                    let value : Float = Float(row.value!)!
                    try! realm.write {
                        self.surfBoard.thickness = value
                    }
            }
            <<< PickerInlineRow<String>(){
                $0.options = ["20", "25", "30"]
                $0.title = "ボリューム"
                $0.value = String(describing: self.surfBoard?.volume)
                }.onChange{ row in
                    let value : Float = Float(row.value!)!
                    try! realm.write {
                        self.surfBoard.volume = value
                    }
            }
            */
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
        if  isNewSurfboard == false {
            form +++ Section()
            <<< ButtonRow(){
                $0.title = "削除"
                $0.cell.tintColor = UIColor.red
                $0.onCellSelection({ (cell, row) in
                    
                    AlertViewUtils.showConfirmView(forViewController: self as UIViewController, title: "削除の確認", message: "削除してよろしいですか？", doneTitle: "はい", cancelTitle: "キャンセル", doneHandler: { (aa) in
                        
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
