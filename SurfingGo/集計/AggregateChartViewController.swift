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
            keyName = "surfboard.id"
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
        }
        
        self.title = AggregateSettingViewController.AggregateTypeNamesDict[self.aggregateType]! + "別の集計"
        
        for i in 0..<xLabels.count {
            
            let value = xValues[i]
            
            let count = self.waveSessionResuls.filter("\(keyName) = %@", value).count
            
            dataEntries.append(BarChartDataEntry(x : Double(i), y : Double(count)))
            
        }

        /*
        for (key,value) in WaveSession.waveHeightDic {
            let count = waveSessionResuls.filter("waveHeight = %@", key).count
            
            dataEntries.append(BarChartDataEntry(x : Double(key), y : Double(count)))

        }
        */
        /*
        let keys = Array(WaveSession.waveHeightDic.keys)
        for i in 0..<keys.count {
            
            let key = keys
            let count = waveSessionResuls.filter("waveHeight = %@", keys[i]).count
            
            dataEntries.append(BarChartDataEntry(x : Double(i+1), y : Double(count)))
            
        }
 */
        // チャート情報にラベルとデータを設定
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "セッション数")
        let chartData = BarChartData(dataSet: chartDataSet)
        
        
        var rect = view.bounds
        rect.origin.y += 20
        rect.size.height -= 20
        let barChartView = BarChartView(frame: rect)
        barChartView.xAxis.labelCount = xLabels.count
        barChartView.delegate = self
        barChartView.xAxis.valueFormatter = self as! IAxisValueFormatter
//        barChartView.xAxis.drawLabelsEnabled = true
 //       barChartView.xAxis.drawAxisLineEnabled = true
        // x軸のラベルをボトムに表示
        barChartView.xAxis.labelPosition = .bottom
        // グラフの棒をニョキッとアニメーションさせる
        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        // グラフのタイトル
//        barChartView.chartDescription?.text = ""
        barChartView.drawValueAboveBarEnabled = true
            // 軸のラベル(目盛)のフォント、テキストカラー
   //     barChartView.xAxis.labelFont = UIFont.systemFont(ofSize: 10.0)
   //     barChartView.xAxis.labelTextColor = UIColor.black
        
        // 軸の色、太さ
   //     barChartView.xAxis.axisLineColor = UIColor.gray
   //     barChartView.xAxis.axisLineWidth = CGFloat(0.5)


        // viewにチャートデータを設定
        barChartView.data = chartData
        

        view.addSubview(barChartView)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
        if let dataSet = chartView.data?.dataSets[highlight.dataSetIndex] {
            
            let sliceIndex: Int = dataSet.entryIndex(entry: entry)
            
            let value = self.xValues[sliceIndex]
            
            let results = waveSessionResuls.filter("\(self.keyName) = %@", value)

            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "sessionTableViewControllerId") as! SessionTableViewController
            vc.waveSessionsBySections = WaveSession.loadWaveSessionsBySections(realm: realm, waveSessions : results)
            self.navigationController?.pushViewController(vc as UIViewController, animated: true)

            print("bar index:\(sliceIndex)")
        }
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
