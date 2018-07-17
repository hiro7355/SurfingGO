//
//  AggregateChartViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/14.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import Charts
import RealmSwift

class AggregateChartViewController: UIViewController, ChartViewDelegate, IAxisValueFormatter {

    let realm = try! Realm()
    var startedOn : Date!
    var endedOn : Date!
    var aggregateType : AggregateType!
    var dic = [String : Results<WaveSession>]()
    var xLabels : [String] = []
    var keyName : String = ""
    var xValues : [Int] = []
    var waveSessionResuls : Results<WaveSession>!

    func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String
    {
        return xLabels[Int(value)]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let startedAt : Date = self.startedOn
        let endedAt : Date = Date(timeInterval: 24*3600, since: self.endedOn)
        self.waveSessionResuls = realm.objects(WaveSession.self).filter("startedAt >= %@ AND startedAt <= %@", startedAt, endedAt)
        var dataEntries : [BarChartDataEntry] = []

        switch self.aggregateType! {
        case .Point:  //  ポイント
            xLabels = SurfPoint.names(items: SurfPoint.surfPointArray)
            xValues = SurfPoint.ids(items: SurfPoint.surfPointArray)
            keyName = "surfPoint.id"
        case .Surfboard:  //  サーフボード
            xLabels = SurfBoard.names(items: SurfBoard.surfBoardArray)
            xValues = SurfBoard.ids(items: SurfBoard.surfBoardArray)
            keyName = "surfBoard.id"
        case .WaveHeight:  //  サイズ
            xLabels = WaveSession.waveHeightTexts
            xValues = WaveSession.waveHeightValues
            keyName = "waveHeight"
        case .Condition: //  波質
            xLabels = WaveSession.conditionLevelTexts
            xValues = WaveSession.conditionLevelValues
            keyName = "conditionLevel"
        case .SatisfactionLevel:  //  満足度
            xLabels = WaveSession.satisfactionLevelTexts
            xValues = WaveSession.satisfactionLevelValues
            keyName = "satisfactionLevel"
        case .WaveDirection:  //  うねりの向き
            xLabels = WaveSession.waveDirectionTexts
            xValues = WaveSession.waveDirectionValues
            keyName = "waveDirection"
        case .WindDirection:  //  風向き
            xLabels = WaveSession.windDirectionTexts
            xValues = WaveSession.windDirectionValues
            keyName = "windDirection"
        case .WindWeight:  //  風の強さ
            xLabels = WaveSession.windWeightTexts
            xValues = WaveSession.windWeightValues
            keyName = "windWeight"
        case .Year:  //  年度
            xValues = self.years(from: self.startedOn, to: self.endedOn)
            xLabels = ArrayUtils.intToStringArray(intValues: xValues)
            keyName = "startedAt"
        case .TopSpeed:  //  最高速度
            xLabels = WaveSession.topSpeedTexts
            xValues = WaveSession.topSpeedValues
            keyName = "topSpeed"
        case .LongestDistance:  //  最長距離
            xLabels = WaveSession.longestDistanceTexts
            xValues = WaveSession.longestDistanceValues
            keyName = "longestDistance"
        }
        
        self.title = AggregateSettingViewController.AggregateTypeNamesDict[self.aggregateType]!
        
        for i in 0..<xLabels.count {
            let count = self.filterredResults(xIndex: i).count
            dataEntries.append(BarChartDataEntry(x : Double(i), y : Double(count)))
        }

        // チャート情報にラベルとデータを設定
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "セッション数")
        let chartData = BarChartData(dataSet: chartDataSet)
        
        
        var rect = view.bounds
        rect.origin.y += 20
        rect.size.height -= 20
        let barChartView = BarChartView(frame: rect)
        barChartView.xAxis.labelCount = xLabels.count
        barChartView.delegate = self
        barChartView.xAxis.valueFormatter = self as IAxisValueFormatter
        // x軸のラベルをボトムに表示
        barChartView.xAxis.labelPosition = .bottom
        // グラフの棒をニョキッとアニメーションさせる
        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        // グラフのタイトル
        barChartView.drawValueAboveBarEnabled = true
        // viewにチャートデータを設定
        barChartView.data = chartData

        view.addSubview(barChartView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //  棒グラフの一つを選択した時
    //   セッション一覧画面を開きます
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        if let dataSet = chartView.data?.dataSets[highlight.dataSetIndex] {
            let sliceIndex: Int = dataSet.entryIndex(entry: entry)
            let results = self.filterredResults(xIndex: sliceIndex)
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "sessionTableViewControllerId") as! SessionTableViewController
            vc.waveSessionsBySections = WaveSession.loadWaveSessionsBySections(waveSessions : results)
            vc.title = self.xLabels[sliceIndex]     //  セッション一覧画面のタイトルがサーフポイント名などX軸タイトルになるように設定します
            self.navigationController?.pushViewController(vc as UIViewController, animated: true)

            print("bar index:\(sliceIndex)")
        }
    }

    private func filterredResults(xIndex: Int) -> RealmSwift.Results<WaveSession> {
        let value = self.xValues[xIndex]
        if self.aggregateType == .Year {
            return waveSessionResuls.filter("\(self.keyName) >= %@ AND \(self.keyName) <= %@", DateUtils.startDateOfYear(year: value), DateUtils.endDateOfYear(year: value))
        } else if self.aggregateType == .TopSpeed  {
            if xIndex >= (self.xValues.count - 1) {
                return waveSessionResuls.filter("\(self.keyName) >= %@", NumUtils.mps(fromKph: Double(value)))
            } else {
                let nextValue = self.xValues[xIndex+1]
                return waveSessionResuls.filter("\(self.keyName) >= %@ AND \(self.keyName) < %@", NumUtils.mps(fromKph: Double(value)), NumUtils.mps(fromKph: Double(nextValue)))
            }
        } else if self.aggregateType == .LongestDistance {
            if xIndex >= (self.xValues.count - 1) {
                return waveSessionResuls.filter("\(self.keyName) >= %@", value)
            } else {
                let nextValue = self.xValues[xIndex+1]
                return waveSessionResuls.filter("\(self.keyName) >= %@ AND \(self.keyName) < %@", value, nextValue)
            }
        } else {
            return waveSessionResuls.filter("\(self.keyName) = %@", value)
        }
    }
    
    private func years(from: Date, to: Date) -> [Int] {
        var years: [Int] = []
        
        if let startYear = from.year, let endYear = to.year {
            
            var year = startYear
            while(year <= endYear) {
                years.append(year)
                year += 1
            }
        }
        return years
    }
}
