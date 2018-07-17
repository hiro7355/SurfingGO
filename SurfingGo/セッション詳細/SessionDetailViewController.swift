//
//  SessionDetailViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/24.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import RealmSwift

class SessionDetailViewController: UIViewController {
    var waveSession : WaveSession?
    var indexPath : IndexPath?
    var realm : Realm?
    var specifiedWave : Wave?
    

    @IBOutlet weak var satisfactionLevelLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var waveInfoStackView: UIStackView!
    @IBOutlet weak var waveMapView: WaveMapView!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var startedOnLabel: UILabel!
    @IBOutlet weak var startedAtAndEndedAtLabel: UILabel!
    @IBOutlet weak var pointNameLabel: UILabel!
    @IBOutlet weak var surfboardNameLabel: UILabel!
    @IBOutlet weak var waveConditionLabel: UILabel!
    @IBOutlet weak var waveHeightLabel: UILabel!
    @IBOutlet weak var waveDirectionLabel: UILabel!
    @IBOutlet weak var windDirectionLabel: UILabel!
    @IBOutlet weak var windWeightLabel: UILabel!
    @IBOutlet weak var waveCountLabel: UILabel!
    @IBOutlet weak var longestDistanceLabel: UILabel!
    @IBOutlet weak var topSpeedLabel: UILabel!
    @IBOutlet weak var totalDistanceLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var memoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "セッション詳細"
        
        if self.specifiedWave != nil {
            //  waveが指定されているので、ライディング詳細へ遷移します。
            performSegue(withIdentifier: "showWaveMapVCSegue",sender: nil)
        }
    }

    //  MARK: 編集ボタンタップ
    @IBAction func onEdit(_ sender: Any) {
        let editVC = SessionEditViewController()
        editVC.waveSession = self.waveSession
        editVC.indexPath = self.indexPath
        editVC.delegate = self.sessionTableViewController
        self.show(editVC, sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateView(waveSession: self.waveSession!)
    }

    private func updateView(waveSession : WaveSession) {
        self.satisfactionLevelLabel.text = waveSession.satisfactionLevelSmily()
        //  2017年10月21日 火曜日
        self.startedOnLabel.text = waveSession.startedOnText()
        //  12:00~13:00
        self.startedAtAndEndedAtLabel.text = waveSession.startedAtAndEndedAtText()
        self.pointNameLabel.text = waveSession.surfPoint?.name
        self.surfboardNameLabel.text = waveSession.surfBoard?.name
        self.waveConditionLabel.text = waveSession.conditionLevelText()
        self.waveHeightLabel.text = waveSession.waveHeightText()
        self.waveDirectionLabel.text = waveSession.waveDirectionText()
        self.windDirectionLabel.text = waveSession.windDirectionText()
        self.windWeightLabel.text = waveSession.windWeightText()
        self.memoLabel.text = waveSession.memo
        self.memoLabel.numberOfLines = 0
        
        if !waveSession.isWatch {
            self.waveMapView.isHidden = true
            self.detailButton.isHidden = true
            self.waveCountLabel.isHidden = true
            self.waveInfoStackView.isHidden = true

        } else {
            self.waveMapView.isHidden = false
            self.waveMapView.set(waveSession: waveSession)
            self.waveMapView.showWaves(showWaveLineDelay: 0.0, specifiedWave: self.specifiedWave)
            self.detailButton.isHidden = false
            self.waveCountLabel.isHidden = false
            self.waveInfoStackView.isHidden = false
            self.waveCountLabel.text = waveSession.wavesCountText()
            self.longestDistanceLabel.text = String(Int(round(NumUtils.value1(forDoubleValue : waveSession.longestDistance))))
            self.topSpeedLabel.text = String(Int(round(NumUtils.kph(fromMps: waveSession.topSpeed))))
            self.averageSpeedLabel.text = String(Int(round(NumUtils.kph(fromMps: waveSession.averageSpeed))))
            self.totalDistanceLabel.text = String(Int(round(NumUtils.value1(forDoubleValue : waveSession.totalDistance))))
        }
        
        let contentSize = self.contentStackView.frame.size
        self.contentScrollView.contentSize = contentSize
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    var sessionTableViewController: SessionTableViewController? {
        for vc in (self.navigationController?.viewControllers)! {
            if let viewController = vc as? SessionTableViewController {
                return viewController
            }
        }
        return nil
    }
    
    // Segueで遷移時の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showWaveMapVCSegue") {
            //  ナビゲーションバーの背景にマップビューが表示されるようにします。タブバーの非表示はstoryboardに設定してます。
            segue.destination.extendedLayoutIncludesOpaqueBars = true
            segue.destination.edgesForExtendedLayout = UIRectEdge.all
         
            if let waveMapVC: WaveMapViewController = segue.destination as? WaveMapViewController {
                waveMapVC.waveSession = self.waveSession
                waveMapVC.indexPath = self.indexPath
                waveMapVC.realm = self.realm
                
                if let wave = self.specifiedWave {
                    //  waveが指定されているので、設定します
                    waveMapVC.specifiedWave = wave
                }
            }
         }
    }
}
