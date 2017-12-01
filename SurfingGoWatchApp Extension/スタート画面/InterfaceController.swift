//
//  InterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/09/26.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController /*, WCSessionDelegate */ {
    @IBOutlet var heatTimeSlider: WKInterfaceSlider!
    
    @IBOutlet var sessionTypeLabel: WKInterfaceLabel!
    
    
    //  ヒート時間スライダーが変更されるとよびだされます
    @IBAction func onChangeHeatTimeSlider(_ value: Float) {
        Settings.setHeatTime(value: Int(value))
        
        self.updateSessionTypeLabel()
    }
    
    //
    //  セッション種別のラベル表示を更新します
    //
    private func updateSessionTypeLabel() {
        
        if Settings.isHeatSession() {
            //  ヒート形式
            self.sessionTypeLabel.setText("\(Settings.heatTime())分ヒート")
        } else {
            //  フリーサーフィン
            self.sessionTypeLabel.setText("フリーサーフィン")
        }
    }
    //  スタートボタンタップ
    @IBAction func doStart() {
        
        let sessionIP = SessionInterfaceParam()
        
        let pages = ["idTimeInterface", "idStopInterface"]
        
        let contexts = [sessionIP,sessionIP]
        
        
        WKInterfaceController.reloadRootPageControllers(withNames: pages, contexts: contexts, orientation: WKPageOrientation.horizontal, pageIndex: 0)
        
    }
    
    private func updateView() {
        
        if Settings.isHeatSession() {
            //  ヒート形式のとき
            // ヒート時間スライダーを表示します
            heatTimeSlider.setHidden(false)
            //  ヒート時間を設定します
            heatTimeSlider.setValue(Float(Settings.heatTime()))
        } else {
            //  フリーサーフィンのとき
            // ヒート時間スライダーを非表示にします
            heatTimeSlider.setHidden(true)
        }
        
        //  セッション種別ラベルを表示更新します
        updateSessionTypeLabel()
        
    }
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let manager = FileManager.default
        do {
            let list = try manager.contentsOfDirectory(atPath: documentsPath)
            for path in list {
                print(path as NSString)
            }

        } catch {
            
        }
        
        // Configure interface objects here.
        /*
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
 */
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        self.updateView()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    /*
    @IBAction func doUpload() {
        uploadFile()
    }
    
    func uploadFile() {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        let fileName = "test.txt"
        
        let path = "\(documentsPath)/\(fileName)"
        /*
         do {
         try text.write(toFile: path, atomically: true, encoding: .utf8)
         } catch {
         print("write error")
         }
         */
        if (WCSession.isSupported()) {
            let session = WCSession.default
            /*
             if session.isReachable {
             // iPhoneと通信可能のとき
             session.sendMessage([:], replyHandler: {(replay) -> Void in
             
             let buttonAction = WKAlertAction(title:"OK", style: .default) { () -> Void in
             }
             self.presentAlert(withTitle: "タイトル", message: replay.description, preferredStyle: .alert, actions: [buttonAction])
             }){(error) -> Void in
             print(error)
             }
             }
             */
            // iPhoneに転送します
            let url = URL(fileURLWithPath: path)
            session.transferFile(url,metadata:nil)
        }
        
        /*
         DispatchQueue.global().async(execute: {
         
         let manager = FileManager.default
         let containerPath = manager.url(forUbiquityContainerIdentifier: nil)
         
         if containerPath != nil {
         
         let documentPath = containerPath?.appendingPathComponent("Documents")
         let filePath = documentPath?.appendingPathComponent("document.txt")
         print("fileURL: \(String(describing: filePath))")
         
         
         do {
         try text.write(to: filePath!, atomically: true, encoding: .utf8)
         } catch {
         print("write error")
         }
         }
         //  iCloudコンテナを指定します。
         let url = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.jp.co.ikaika.SurfingGo")
         if (url != nil)  {
         
         let fileURL = url?.appendingPathComponent("test.txt")
         print("fileURL: \(String(describing: fileURL))")
         
         
         do {
         try text.write(to: fileURL!, atomically: true, encoding: .utf8)
         } catch {
         print("write error")
         }
         }
         })
         */
    }
*/
    /*
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session activationDidCompleteWith: error: \(String(describing: error))")
    }
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if error == nil {
            
            print("\(fileTransfer.file.fileURL.absoluteString)の送信完了")

            //  ファイル削除します
            let manager = FileManager()
            do {
                try manager.removeItem(at: fileTransfer.file.fileURL)
            } catch {
                print("\(fileTransfer.file.fileURL.absoluteString)の削除失敗")

            }

            
        } else {
            print("session didFinish: error: \(String(describing: error))")
        }
    }
 */
}
