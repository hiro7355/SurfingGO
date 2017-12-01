//
//  SessionCell.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/15.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit

class SessionCell: UITableViewCell {
    @IBOutlet weak var satisfactionLevelLabel: UILabel!
    
    @IBOutlet weak var pointNameLabel: UILabel!
    @IBOutlet weak var waveConditionAndSizeLabel: UILabel!
    @IBOutlet weak var windDirectionLabel: UILabel!
    @IBOutlet weak var startedAtLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var waveCountLabel: UILabel!
    @IBOutlet weak var longestDistanceLabel: UILabel!
    @IBOutlet weak var topSpeedLabel: UILabel!
    
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var ridingStackView: UIStackView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupControls(waveSession : WaveSession) {
        
        pointNameLabel.text = waveSession.surfPoint?.name
        waveConditionAndSizeLabel.text = waveSession.conditionLevelText() + waveSession.waveHeightText()
        windDirectionLabel.text = waveSession.windDirectionText()
        self.startedAtLabel.text = waveSession.startedAtText()
        self.timeLabel.text = waveSession.timeText()
        
      //  self.ridingStackView.isHidden = waveSession.waves.count == 0 ? true : false
        
        self.waveCountLabel.text = waveSession.wavesCountText()
        self.longestDistanceLabel.text = waveSession.longestDistanceText2()
        self.topSpeedLabel.text =  waveSession.topSpeedText2()
        
        self.memoLabel.text = waveSession.memo

        self.satisfactionLevelLabel.text = waveSession.satisfactionLevelSmily()

        
    }
}
