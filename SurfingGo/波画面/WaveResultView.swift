//
//  WaveResultView.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/13.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit

class WaveResultView: UIView {
    @IBOutlet weak var waveCountLabel: UILabel!
    @IBOutlet weak var startedAtLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var wave : Wave!
    var waveNumber : Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func view(wave : Wave, count : Int, sessionStartedAt : Date) -> WaveResultView {
        let view : WaveResultView = Bundle.main.loadNibNamed("WaveResultView", owner: nil, options: nil)?.first as! WaveResultView
        view.setup(wave: wave, count : count, sessionStartedAt : sessionStartedAt)
        return view
    }
    
    func setup(wave : Wave, count : Int, sessionStartedAt : Date) {
        self.wave = wave
        self.update(waveNumber: count)
        let timeSinceSessionStartedAt = wave.startedAt.timeIntervalSince1970 - sessionStartedAt.timeIntervalSince1970
        self.startedAtLabel.text = "\(DateUtils.stringFromTimeintervalInEng(timeinterval : timeSinceSessionStartedAt))"
        speedLabel.text = "\(Float(Int(((wave.topSpeed*3600)/1000)*10))/10)"
        distanceLabel.text = "\(Float(Int(wave.distance*10))/10)"
        timeLabel.text = "\(Float(Int(wave.time*10))/10)"
    }
    
    func update(waveNumber : Int) {
        self.waveNumber = waveNumber
        self.waveCountLabel.text = "Wave\(waveNumber)"
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }

    @IBAction func doMenu(_ sender: UIButton) {
        if case let parentVC as WaveMapViewController = self.parentViewController {
            let alertController: UIAlertController = UIAlertController(title: self.waveCountLabel.text! + "を削除します", message: "削除してよろしいですか？", preferredStyle:  UIAlertControllerStyle.actionSheet)
            let okAction: UIAlertAction = UIAlertAction(title: "はい", style: UIAlertActionStyle.destructive, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    parentVC.remove(waveResultView: self)
                }
            })
            // Cancelボタン
            let cancelButton: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler:{
                (action: UIAlertAction!) -> Void in
                print("cancelAction")
            })
            alertController.addAction(okAction)
            alertController.addAction(cancelButton)
            parentVC.present(alertController,animated: true,completion: nil)
        }
    }
}
