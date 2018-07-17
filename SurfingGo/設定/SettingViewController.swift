//
//  SettingViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/21.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import Eureka
import RealmSwift

extension SettingViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("opened url : \(url)")
        
        if let tourl = Realm.Configuration.defaultConfiguration.fileURL {
            if FileManager.default.fileExists(atPath: tourl.path) {
                try! FileManager.default.removeItem(at: tourl)
            }
            try! FileManager.default.copyItem(at: url, to: tourl)
            
            exit(0)
        }
    }
    
    private func documentPickerWasCancelled(controller: UIDocumentPickerViewController!) {
    }
}

class SettingViewController: FormViewController, SurfBoardSettingViewControllerDelegate, SurfPointSettingViewControllerDelegate {
    
    //
    // MARK: SurfPointSettingViewControllerDelegate
    //
    func updated(surfPoint: SurfPoint?, surfPointArray: [SurfPoint], realm: Realm) {
        reloadSurfPoint()
        
        //  セッションテーブル一覧が表示時に更新されるようにします。
        let app : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        app.sessionTableViewController.updated(waveSession: nil, atIndexPath: nil)

    }
    
    //
    // MARK: SurfBoardSettingViewControllerDelegate
    //
    func updated(surfBoard: SurfBoard?, surfBoardArray: [SurfBoard], realm: Realm) {
        reloadSurfBoard()
    }
    
    private func reloadSurfPoint() {
        //  サーフポイント名の配列を作成します
        SurfPoint.updateSurfPoints(realm: self.realm)
        self.surfPointArray =  SurfPoint.surfPointArray
    }

    private func reloadSurfBoard() {
        //  サーフボード名の配列を作成します
        SurfBoard.updateSurfBoards(realm: self.realm)
        self.surfBoardArray =  SurfBoard.surfBoardArray

    }
    let addNewTitle : String = "-- 新規追加 --"
    var surfBoard : SurfBoard!
    var surfBoardArray : [SurfBoard]!
    var surfPoint : SurfPoint!
    var surfPointArray : [SurfPoint]!
    var realm = try! Realm()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "設定"

        reloadSurfBoard()
        
        reloadSurfPoint()
        
        form +++ Section()
            <<< ButtonRow(){
                $0.title = "サーフポイント"
                $0.onCellSelection({ (cell, row) in
                    
                    self.selectValues(title: "サーフポイント", message: "設定するサーフポイントを選択してください", defaultValues: SurfPoint.names(items: self.surfPointArray), handler: { (aa : UIAlertAction) in
                        if let surfPoint = SurfPoint.find(byName: aa.title!, in: self.surfPointArray) {
                            //  設定
                            self.pushSurfPointSettingVC(surfPoint: surfPoint)
                        }
                    }, addNewHandler: { (aaa : UIAlertAction) in
                        //  新規登録
                        self.pushSurfPointSettingVC(surfPoint: SurfPoint())
                    })
                })
            }
            +++ Section()
            <<< ButtonRow(){
                $0.title = "サーフボード"
                $0.onCellSelection({ (cell, row) in
                    self.selectValues(title: "サーフボード", message: "設定するサーフボードを選択してください", defaultValues: SurfBoard.names(items: self.surfBoardArray), handler: { (aa : UIAlertAction) in
                        if let surfBoard = SurfBoard.find(byName: aa.title!, in: self.surfBoardArray) {
                            //  設定
                            self.pushSurfBoardSettingVC(surfBoard: surfBoard)
                        }
                    }, addNewHandler: { (aaa : UIAlertAction) in
                        //  新規登録
                        self.pushSurfBoardSettingVC(surfBoard: SurfBoard())
                    })
                })
            }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func pushSurfPointSettingVC(surfPoint : SurfPoint) {
        let settingVC = SurfPointSettingViewController()
        
        settingVC.surfPoint = surfPoint
        settingVC.surfPointArray = self.surfPointArray
        settingVC.realm = self.realm
        settingVC.delegate = self
        
        // 画面遷移
        self.navigationController?.pushViewController(settingVC as UIViewController, animated: true)
    }

    private func pushSurfBoardSettingVC(surfBoard : SurfBoard) {
        let settingVC = SurfBoardSettingViewController()
        
        settingVC.surfBoard = surfBoard
        settingVC.surfBoardArray = self.surfBoardArray
        settingVC.realm = self.realm
        settingVC.delegate = self
        
        // 画面遷移
        self.navigationController?.pushViewController(settingVC as UIViewController, animated: true)
    }


    private func selectValues(title: String, message: String, defaultValues: [String], handler: ((UIAlertAction) -> Swift.Void)? = nil, addNewHandler: ((UIAlertAction) -> Swift.Void)? = nil) {
        // styleをActionSheetに設定
        let alertSheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)

        //  新規登録
        let action2 = UIAlertAction(title: self.addNewTitle, style: UIAlertActionStyle.destructive, handler: addNewHandler)
        alertSheet.addAction(action2)

        // 自分の選択肢を生成
        for value in defaultValues {
            
            let action = UIAlertAction(title: value, style: UIAlertActionStyle.default, handler: handler)
            // アクションを追加.
            alertSheet.addAction(action)
        }
        
        let action3 = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: nil)
        alertSheet.addAction(action3)

        self.present(alertSheet, animated: true, completion: nil)
    }
}
