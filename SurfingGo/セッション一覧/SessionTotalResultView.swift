//
//  SessionTotalResultView.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/25.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import RealmSwift

// プロトコル
protocol SessionTotalResultViewDelegate {
    func selectWave(waveSession : WaveSession, wave : Wave?) -> Void
}


class SessionTotalResultView: UITableViewCell {
    @IBOutlet weak var wavesLabel: UILabel!
    @IBOutlet weak var waveInfoStackView: UIStackView!
    
    @IBOutlet weak var longestDistanceButton: UIButton!
    @IBOutlet weak var topSpeedButton: UIButton!
    @IBOutlet weak var waveCountLabel: UILabel!
    @IBOutlet weak var totalHourLabel: UILabel!
    @IBOutlet weak var totalSessionCountLabel: UILabel!
    
    var delegate : SessionTotalResultViewDelegate?
    var topSpeedWaveSession : WaveSession?
    var longestDistanceWaveSession : WaveSession?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func onTopSpeedTapped(_ sender: Any) {
        // セッション詳細画面を表示
        if let waveSession = self.topSpeedWaveSession {
            delegate?.selectWave(waveSession: waveSession, wave: waveSession.topSpeedWave())
        }

        
    }
    @IBAction func onLongestDistanceTapped(_ sender: Any) {
        // セッション詳細画面を表示
        if let waveSession = self.longestDistanceWaveSession {
            delegate?.selectWave(waveSession: waveSession, wave: waveSession.longestDistanceWave())
        }
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateView(waveSessionsBySections : [Results<WaveSession>]) {
        
        var totalSessionCount : Int = 0
        var totalRidingTime : Double = 0
        var topSpeed : Double = 0
        var longestDistance : Double = 0
        var totalWaveCount : Int = 0
        
        
        for waveSessions in waveSessionsBySections {
            
            totalSessionCount = totalSessionCount + waveSessions.count
            
            for waveSession in waveSessions {
                
                totalRidingTime = totalRidingTime + waveSession.time
                
                
                if waveSession.waves.count > 0 {
                    totalWaveCount = totalWaveCount + waveSession.waves.count
                    //  最長距離を更新します
                    if longestDistance < waveSession.longestDistance {
                        longestDistance = waveSession.longestDistance
                        self.longestDistanceWaveSession = waveSession
                    }
                    //  トップスピードを更新します
                    if topSpeed < waveSession.topSpeed {
                        topSpeed = waveSession.topSpeed
                        self.topSpeedWaveSession = waveSession
                    }
                    
                }
                
            }
        }

        
        self.totalSessionCountLabel.text = String(totalSessionCount)
        self.totalHourLabel.text = String(Int(round(totalRidingTime/3600)))
        
        if totalWaveCount > 0 {
            self.topSpeedButton.setTitle(String(Int(round(NumUtils.kph(fromMps: topSpeed)))), for: UIControlState.normal)
//            self.topSpeedButton.titleLabel?.text = String(Int(round(NumUtils.kph(fromMps: topSpeed))))
            self.longestDistanceButton.setTitle(String(Int(round(NumUtils.value1(forDoubleValue : longestDistance)))), for: UIControlState.normal)
//            self.longestDistanceButton.titleLabel?.text = String(Int(round(NumUtils.value1(forDoubleValue : longestDistance))))
            self.waveCountLabel.text = String(totalWaveCount)
            self.wavesLabel.text = WaveSession.waveCountUnit(forWaveCount: totalWaveCount)
            
            self.waveInfoStackView.isHidden = false
        }  else {
            self.waveInfoStackView.isHidden = true

        }
        
        
        
    }
}
