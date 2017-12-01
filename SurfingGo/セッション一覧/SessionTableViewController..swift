//
//  SessionTableViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/09.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import RealmSwift
import CSV


class SessionTableViewController: UITableViewController, SessionEditViewControllerDelegate,SessionTotalResultViewDelegate, UIDocumentPickerDelegate {
    
    

//    var waveSessions : Results<WaveSession>!
    var waveSessionsBySections : [Results<WaveSession>]!

    var realm = try! Realm()
    var isUpdated : Bool = false
    var selectedWave : Wave?
    var selectedWaveSession : WaveSession?
    var selectedIndexPath : IndexPath?
    

    //
    //  CSV形式で保存します
    //  MARK: CSV
    //
    @IBAction func onSaveToCSV(_ sender: Any) {
        
        let fileName = "SurfinGO_" + DateUtils.stringFromDate(date: NSDate(), format: "YYYYMMdd_HHmmss") + ".csv"
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = "\(documentsPath)/\(fileName)"
        
        //  TODO: debug
        print(path)
        
        do {
//            let stream = OutputStream(toFileAtPath: path, append: false)!
            let stream = OutputStream(toMemory: ())
            let csv = try CSVWriter(stream: stream)
    
            try csv.write(row: ["id", "本数", "セッション開始日時", "ポイント名", "時間(秒)", "総距離(メートル)", "平均速度(km/h)", "最長距離(メートル)", "最高速度(km/h)", "満足度", "コンディション", "波のサイズ", "うねりの向き", "風の強さ", "風向き", "サーフボード", "メモ" ])

            for waveSessions in self.waveSessionsBySections {
                for waveSession in waveSessions {
                    
                    let waveCountString : String = String(waveSession.waves.count)
                    let averageSpeedString : String  = String(Int(NumUtils.kph(fromMps: waveSession.averageSpeed)))
                    let topSpeedString : String = String(Int(NumUtils.kph(fromMps: waveSession.topSpeed)))
                    
                    try csv.write(row: [String(waveSession.id)
                        , waveCountString
                        ,DateUtils.stringFromDate(date: waveSession.startedAt as NSDate, format: "yyyy/MM/dd HH:mm")
                        , waveSession.surfPointName()
                        , String(waveSession.time)
                        , String(NumUtils.value1(forDoubleValue: waveSession.totalDistance))
                        , averageSpeedString
                        , String(NumUtils.value1(forDoubleValue: waveSession.longestDistance))
                        , topSpeedString
                        , waveSession.satisfactionLevelText()
                        , waveSession.conditionLevelText()
                        , waveSession.waveHeightText()
                        , waveSession.waveDirectionText()
                        , waveSession.windWeightText()
                        , waveSession.waveDirectionText()
                        , waveSession.surfBoardName()
                        , "\"" + waveSession.memo + "\""
                        ])
                    
                    
                }
            }
            
            
            csv.stream.close()

            
           
            // Get a String
            let csvData = stream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData

            /*
            let csvString = String(data: Data(referencing: csvData), encoding: .utf8)!
            try csvString.write(to: URL(fileURLWithPath: path), atomically: true, encoding: String.Encoding.shiftJIS)
            let documentPicker = UIDocumentPickerViewController(url: URL(fileURLWithPath: path), in: .exportToService)
            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
*/
            
            Data(referencing: csvData).withUnsafeBytes({ (ptr: UnsafePointer<UInt8>) in

                let fileStream = OutputStream(toFileAtPath: path, append: false)!
                fileStream.open()

                let BOM : [UInt8] = [0xEF, 0xBB, 0xBF]
                fileStream.write(BOM, maxLength: BOM.count )

                fileStream.write(ptr, maxLength: csvData.length)

                let documentPicker = UIDocumentPickerViewController(url: URL(fileURLWithPath: path), in: .exportToService)
                documentPicker.delegate = self
                self.present(documentPicker, animated: true, completion: nil)

            })
            
            
            

        } catch {
            //エラー処理
        }
    }
    
    /*
    required init?(coder aDecoder: NSCoder) {
        
        let app : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        self.waveSessions = app.loadWaveSessions(realm: self.realm)

        super.init(coder: aDecoder)
        
        app.sessionTableViewController = self   //  更新通知をうけとれるように自分を設定します
    }
    */
    override func viewWillAppear(_ animated: Bool) {
        if self.isUpdated {
            
            self.reloadWaveSessionData()
            
            self.isUpdated = false
        }

    }
    private func reloadWaveSessionData() {
        let app : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        self.waveSessionsBySections = app.loadWaveSessionsBySection(realm: self.realm)
        
        
        self.tableView.reloadData()

    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        self.title = "セッション一覧"
/*
        //xibの生成
        let celxib = UINib(nibName: "main", bundle: nil)
        //再利用するための準備
        tableView.register(celxib, forHeaderFooterViewReuseIdentifier: "waveSessionCell")

        //xibの生成
        let xib = UINib(nibName: "SessionTotalResultView", bundle: nil)
        //再利用するための準備
        tableView.register(xib, forHeaderFooterViewReuseIdentifier: "SessionTotalResultView")
*/
        let xib = UINib(nibName: "SessionTotalResultView", bundle: nil)
        //再利用するための準備
        tableView.register(xib, forCellReuseIdentifier: "SessionTotalResultView")

        // 保存ボタン作成
        let saveButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(SessionTableViewController.onSaveToCSV))

        //  集計からの遷移の場合は、waveSessionsBySectionsに値が設定されています。
        if self.waveSessionsBySections == nil {
            
           self.isUpdated = true //  表示前にwaveSessionsBySectionsがロードされるようにします
            
            let app : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            app.sessionTableViewController = self   //  更新通知をうけとれるように自分を設定します

            // 追加ボタン作成
            let editButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(SessionTableViewController.clickAddButton))

            //ナビゲーションバーの右側にボタン付与
            self.navigationItem.setRightBarButtonItems([editButton,saveButton], animated: true)
        } else {
            //ナビゲーションバーの右側にボタン付与（保存のみ）
            self.navigationItem.setRightBarButtonItems([saveButton], animated: true)

        }
    }

    //
    //  追加ボタンタップ時の処理
    //
    @objc dynamic func clickAddButton(){
        
        let detailVC = SessionEditViewController()
        detailVC.waveSession = WaveSession()    //  新規セッション
        detailVC.delegate = self
        detailVC.hidesBottomBarWhenPushed = true    //  タブバーを非表示にします
        self.navigationController?.pushViewController(detailVC as UIViewController, animated: true)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return waveSessionsBySections.count + 1
    }
    //  セクションヘッダー
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        } else {
            //  xibからロード
            let view : SessionSectionHeaderView = Bundle.main.loadNibNamed("SessionSectionHeaderView", owner: nil, options: nil)?.first as! SessionSectionHeaderView

            
            let waveSessions = self.waveSessionsBySections[section-1]
            
            let waveSession = waveSessions[0]
            
            let totalWaveCount = WaveSession.totalWaveCount(inWaveSessions: waveSessions)
            
            let yearMonthText =  DateUtils.stringFromDate(date: waveSession.startedAt as NSDate, format: "YYYY年MM月")
            let sessionCountText = "\(waveSessions.count)セッション \(self.totalRidingHour(for : waveSessions))時間 " + WaveSession.wavesCountText(forWaveCount : totalWaveCount)
            
            view.yearMonthLabel.text = yearMonthText
            view.sessionCountLabel.text = sessionCountText
            
            return view
        }
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        } else {
            return 60
        }
    }
    
    
    private func totalRidingHour(for waveSessions : Results<WaveSession>) -> Int {
        var totalRidingTime : Double = 0
        
        for waveSession in waveSessions {
            
            totalRidingTime = totalRidingTime + waveSession.time
        }
        
        return Int(round(totalRidingTime/3600))
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 1
        } else {
            
            return self.waveSessionsBySections[section - 1].count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        
        if section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "SessionTotalResultView", for: indexPath) as! SessionTotalResultView
            // Configure the cell...
            
            cell.delegate = self
            
            cell.updateView(waveSessionsBySections: self.waveSessionsBySections)
            
            return cell
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "waveSessionCell", for: indexPath) as! SessionCell
            // Configure the cell...
            
            let waveSessions = self.waveSessionsBySections[indexPath.section-1]
            let waveSession = waveSessions[indexPath.row]
            
            
            cell.setupControls(waveSession: waveSession)
            
            return cell
        }
        
    }
    
    //
    //  セル選択時
    //
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section != 0 {
            
            let section : Int = (self.tableView.indexPathForSelectedRow?.section)!
            let row : Int = (self.tableView.indexPathForSelectedRow?.row)!
            let waveSessions = self.waveSessionsBySections[section-1]
            let waveSession = waveSessions[row]

            self.selectedWaveSession = waveSession
            self.selectedWave = nil
            self.selectedIndexPath = self.tableView.indexPathForSelectedRow
            

            // セッション詳細画面を表示
            performSegue(withIdentifier: "showSessionDetailVCSegue",sender: nil)
        }

        
        
    }

    // Segueで遷移時の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if (segue.identifier == "showSessionDetailVCSegue") {
            
            
            if let vc: SessionDetailViewController = segue.destination as? SessionDetailViewController {
                
  /*
                let section : Int = (self.tableView.indexPathForSelectedRow?.section)!
                let row : Int = (self.tableView.indexPathForSelectedRow?.row)!
                let waveSessions = self.waveSessionsBySections[section-1]
                let waveSession = waveSessions[row]
                vc.waveSession = waveSession
                vc.indexPath = self.tableView.indexPathForSelectedRow
*/
                vc.waveSession = self.selectedWaveSession
                vc.specifiedWave = self.selectedWave
                vc.indexPath = self.selectedIndexPath

                vc.realm = self.realm
                vc.hidesBottomBarWhenPushed = true    //  タブバーを非表示にします
            }
            
            
        }

        /*
        if (segue.identifier == "showWaveMapSegue") {
            
            //  ナビゲーションバーの背景にマップビューが表示されるようにします。タブバーの非表示はstoryboardに設定してます。
            segue.destination.extendedLayoutIncludesOpaqueBars = true
            segue.destination.edgesForExtendedLayout = UIRectEdge.all

            let waveMapVC: WaveMapViewController = (segue.destination as? WaveMapViewController)!

            let section : Int = (self.tableView.indexPathForSelectedRow?.section)!
            let row : Int = (self.tableView.indexPathForSelectedRow?.row)!
            let waveSessions = self.waveSessionsBySections[section]
            let waveSession = waveSessions[row]
            waveMapVC.waveSession = waveSession
            waveMapVC.realm = self.realm
            
        }
 */
    }
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return indexPath.section != 0 ? true : false
    }
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            
            if editingStyle == .delete {
                // Delete the row from the data source
                //            tableView.deleteRows(at: [indexPath], with: .fade)
                
                let alertController: UIAlertController = UIAlertController(title: "セッションを削除します", message: "削除してよろしいですか？", preferredStyle:  UIAlertControllerStyle.actionSheet)
                
                let okAction: UIAlertAction = UIAlertAction(title: "はい", style: UIAlertActionStyle.destructive, handler:{
                    // ボタンが押された時の処理を書く（クロージャ実装）
                    (action: UIAlertAction!) -> Void in
                    self.removeSession(atIndexPath: indexPath)
                })
                // Cancelボタン
                let cancelButton: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler:{
                    (action: UIAlertAction!) -> Void in
                    print("cancelAction")
                })
                alertController.addAction(okAction)
                alertController.addAction(cancelButton)
                present(alertController,animated: true,completion: nil)
                
            } else if editingStyle == .insert {
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 250
        } else {
            return 100
        }
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //
    // MARK: SessionEditViewControllerDelegate
    // セッション更新で呼び出されます
    //  atIndexPathがnilのときは新規にセッション追加されたとき
    //
    //
    func updated(waveSession: WaveSession?, atIndexPath indexPath : IndexPath?) {


        if indexPath != nil {
            //  更新時
            let top = IndexPath(row: 0, section: 0)
            self.tableView.reloadRows(at: [top,indexPath!], with: UITableViewRowAnimation.none)
            
        } else {
            //  新規登録時
            
            if UIViewController.topViewController() == self {
                //  自分が最前面だった場合は、このばで再表示
                self.reloadWaveSessionData()

            } else {
                //  表示時に再度データを読み直します
                self.isUpdated = true

            }
        }

    }

    //
    //  waevSessionを削除します
    //
    private func removeSession(atIndexPath indexPath : IndexPath) {
        
        let waveSessions : Results<WaveSession> = self.waveSessionsBySections[indexPath.section-1]
        let waveSession = waveSessions[indexPath.row]
        
        try! self.realm.write() {
            self.realm.delete(waveSession)
        }

        self.reloadWaveSessionData()

        
    }


    //  MARK: SessionTotalResultViewDelegate
    func selectWave(waveSession : WaveSession, wave : Wave?) -> Void {
        
        self.selectedWaveSession = waveSession
        self.selectedWave = wave
        self.selectedIndexPath = self.indexPath(ofWaveSession: waveSession)
        
        // セッション詳細画面を表示
        performSegue(withIdentifier: "showSessionDetailVCSegue",sender: nil)

    }

    private func indexPath(ofWaveSession : WaveSession) -> IndexPath? {
    
        var retIndexPath : IndexPath?
        
        for section in 0..<waveSessionsBySections.count {
            
            let waveSessions = waveSessionsBySections[section]
            
            for row in 0..<waveSessions.count {
                
                let waveSession = waveSessions[row]
                
                if ofWaveSession.isEqual(waveSession) {
                    retIndexPath = IndexPath(row: row, section: section + 1)
                    break
                }
            }
            
            if retIndexPath != nil {
                break
            }
        }
        return retIndexPath
    }
    

    
}
