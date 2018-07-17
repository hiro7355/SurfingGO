//
//  TimeInterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/09/26.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import CloudKit
import CoreMotion
import WatchConnectivity

class TimeInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate /*, WCSessionDelegate */{

    // MARK:- Property
    private var waveSession : WaveSession?
    @IBOutlet var timer: WKInterfaceTimer!
    @IBOutlet var waveCount: WKInterfaceLabel!
    @IBOutlet var lastWaveDistance: WKInterfaceLabel!
    var latValue:Double = 100.0 // Impossible value(-90 to 90)
    var lonValue:Double = 200.0 // Impossible value(-180 to 180)
    private let healthStoreManager = HealthStoreManager()
    var workoutSession:HKWorkoutSession!
    var heartRateQuery:HKQuery?
    let heartRateUnit = HKUnit(from: "count/min")
    var isRunning = false
    var isKeep = true
    
    //  位置情報配列
    var locations : [CLLocation] = []
    var preLocation : CLLocation?
    
    //  心拍情報配列
    var heartRates : [(NSDate, Double)] = []

    //  加速度センサー値配列
    var magunitudes : [(NSDate, Double)] = []

    //  iPhoneに転送するファイル名（位置情報と心拍数情報が保存されている）
    var fileName : String = ""
    
    let motionManager = CMMotionManager()
    var workoutStartedAt : Date!
    var workoutEndedAt : Date!
    var sessionIP : SessionInterfaceParam?
    var isHeatSession : Bool = false
    var intervalTimer: Timer!
    var lastUpdatedLocationTime : Date?

    // MARK:- Life Cycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        print("awake")

        self.isHeatSession = Settings.isHeatSession()
        self.sessionIP = context as? SessionInterfaceParam
        self.sessionIP?.timeIC = self
        self.waveSession = WaveSession()
        
        //HealthKitへのアクセス許可をユーザーへ求める(iPhoneアップでやっているので、ここでは必要ないのかも)
        self.healthStoreManager.requestAccessToHealthKit()
        
        //  MARK: ワークアウト開始
        startSession()
    }

    override func willActivate() {
        super.willActivate()
        print("willActivate")
    }

    override func didDeactivate() {
        super.didDeactivate()
        print("didDeactivate")
    }
    
    //    ワークアウト開始
    func startSession(){
        let configuration = HKWorkoutConfiguration()
        
        configuration.activityType = .surfingSports
        configuration.locationType = .outdoor
        
        do {
            self.workoutSession = try HKWorkoutSession(configuration: configuration)
            
            //   workoutSessionがコールバックされます
            self.workoutSession.delegate = self
            
            // ヘルスストアへのアクセスを開始します
            healthStoreManager.start(self.workoutSession)
        }
        catch let error as NSError {
            fatalError("*** Unable to create the workout session: \(error.localizedDescription) ***")
        }
    }

    //  MARK: ワークアウト終了
    //   healthStoreを終了すると、ワークアウトの終了がコールバックされます
    func stopSession(){
        healthStoreManager.end(workoutSession)
    }
   
    // MARK: - ワークアウトセッションからのコールバック HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workout session did fail with error: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            self.handleWorkoutSessionState(didChangeTo: toState, from: fromState)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        DispatchQueue.main.async {
            print("workout session didGenerate event: \(event)")
            self.healthStoreManager.workoutEvents.append(event)
        }
    }
    
    private func startTimer() {
        self.timer.setTextColor(UIColor.yellow)
        
        if isHeatSession {
            timer.setDate(Date(timeIntervalSinceNow: TimeInterval(Settings.heatTime() * 60)))
        }
        timer.start()
        
        intervalTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimerInterval), userInfo: nil, repeats: true)
        intervalTimer.fire()
    }

    private func stopTimer() {
        intervalTimer.invalidate()  //  タイマーイベントを止めます
        timer.stop()    //　タイマー表示を止めます
    }
    
    private func isLocationUpdating() -> Bool {
        if let lastUpdatedLocationTime = self.lastUpdatedLocationTime {
            if  lastUpdatedLocationTime.timeIntervalSinceNow > -2.0 {
                //  2秒いないに位置情報をうけとっていたら更新されているとします
                return true
            }
        }
        return false
    }

    //
    // MARK: タイマーインターバル(1秒ごと）
    //
    @objc private func updateTimerInterval() {
        let interval = Int( 0 - self.workoutStartedAt.timeIntervalSinceNow )
        
        self.timer.setTextColor(self.isLocationUpdating() ? UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1.0) : UIColor.yellow )

        var isStopped = false
        
        if isHeatSession {
            //  ヒート形式の場合
            let heatTimeMin = Settings.heatTime()

            let last5min = heatTimeMin - 5
            if (interval >= 60*last5min) && interval % 60 == 0 {
                //  終了5分前から1分ごとに通知します
                WKInterfaceDevice().play(.notification)
            }
            
            if interval >= heatTimeMin*60 {
                // 時間になったので、自動でセッションストップします
                self.isKeep = true  //  記録が保存されるように設定します
                self.doStop()
                isStopped = true
            }
        }
        
        if isStopped == false {
            //  バッテリー容量が１％をきったら自動停止します
            let level = WKInterfaceDevice.current().batteryLevel
            if  level >= 0.0 && level <= 0.03 {
                self.doStop()
            }
        }
    }
    
    private func handleWorkoutSessionState(didChangeTo toState: HKWorkoutSessionState,
                                           from fromState: HKWorkoutSessionState) {
        switch (fromState, toState) {
        case (.notStarted, .running):
            self.workoutStartedAt = Date()
            
            if Settings.isAutoLock() {
                //  オートロックの設定なので画面ロックします
                WKExtension.shared().enableWaterLock()
            }
            
            //  タイマー表示開始
            startTimer()
            //  計測開始
            startAccumulatingData()
            
        case (_, .ended):
            print("workoutSession: .ended")
            //  終了時間を設定
            self.workoutEndedAt = Date()
            //  計測停止
            stopAccumulatingData()
            //  タイマー表示停止
            self.stopTimer()
            
            if self.isKeep {
                
                DispatchQueue.main.async {
                    //  ヘルスデータを保存
                    self.healthStoreManager.saveWorkout(withSession: self.workoutSession, from: self.workoutStartedAt, to: self.workoutEndedAt)
                    //  位置情報をファイルに保存
                    self.saveLocations()
                    
                    //  結果を保存します
                    self.waveSession!.calc(withWaveCalc: true)
                    self.waveSession!.calcTime(endedAt: self.workoutEndedAt!)
                    Settings.setLastSession(result: self.waveSession!)
                    
                    //  スタート画面にもどります
                    RootInterfaceController.showStartPages(pageIndex: 0)
                }
            } else {
                //  スタート画面にもどります
                RootInterfaceController.showStartPages(pageIndex: 1)
                self.isKeep = true
            }
        default:
            break
        }
    }
    // MARK: - 計測開始
    private func startAccumulatingData() {
        healthStoreManager.startActiveEnergyBurnedQuery(from: self.workoutStartedAt) { quantitySamples in
            DispatchQueue.main.async {
                self.healthStoreManager.processActiveEnergySamples(quantitySamples)
            }
        }
        healthStoreManager.startAccumulatingLocationData()
        
        // 位置情報のコールバックを設定します
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector:#selector(updateLocation(notification:)),
                           name:NSNotification.Name(rawValue: HealthStoreManager.LMLocationUpdateNotification),
                           object:nil)
        
    }
    
    //  MARK: 計測停止
    private func stopAccumulatingData() {
        healthStoreManager.stopAccumulatingData()
        
        // 位置情報のコールバックを削除します
        NotificationCenter.default.removeObserver(self)
        
        //  ジャイロスコープ検出停止
        stopGyro()
        
        //  加速度センサー停止
        stopMotion()
    }

    // 加速度センサーの取得開始
    func startMotion() {
        if motionManager.isDeviceMotionAvailable {
            
            motionManager.deviceMotionUpdateInterval = 0.1
            
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                
                // ユーザー加速度の測定値を取得
                let user = data?.userAcceleration
                // 重力加速度の測定値を取得
                let gravity = data?.gravity;
                
                
                // ユーザー加速度の大きさを算出
                let magnitude = sqrt(pow((user?.x)!, 2) + pow((user?.y)!, 2) + pow((user?.z)!, 2));
                
                // ユーザー加速度のベクトルと重力加速度のベクトルのなす角θのcosθを算出
                let x1 = ((user?.x)! * (gravity?.x)! + (user?.y)! * (gravity?.y)! + (user?.z)! * (gravity?.z)!)
                let x2 = (pow((user?.x)!, 2) + pow((user?.y)!, 2) + pow((user?.z)!, 2))
                let x3 = (pow((gravity?.x)!, 2) + pow((gravity?.y)!, 2) + pow((gravity?.z)!, 2))
                let cosT = x1 / sqrt(x2 * x3);
                // ユーザー加速度の大きさにcosθを乗算してユーザー加速度の重力方向における大きさを算出し、小数点第3位で丸める
                let gravityDirectionMagnitude = round(magnitude * cosT * 100) / 100
                
                if gravityDirectionMagnitude >= 4.0 || gravityDirectionMagnitude <= -4.0 {
                    print("deviceMotionMagunitude: \(gravityDirectionMagnitude) heading: \((data?.heading)!) timestamp: \((data?.timestamp)!)")
                    
                    //  配列に追加
                    self.magunitudes.append( (NSDate(), gravityDirectionMagnitude) )
                }
                
            })
        }
    }

    // 加速度センサーの検出停止
    func stopMotion() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // ジャイロスコープの取得開始
    func startGyro() {
        if motionManager.isGyroAvailable {
            // 値取得間隔
            motionManager.gyroUpdateInterval = 0.1
            
            // 取得を開始
            motionManager.startGyroUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                print("Gylo:" + data.debugDescription)
            })
        }
    }

    func stopGyro() {
        if motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
        }
    }

    //
    //  デバッグようにtest_ibiiから位置情報取得
    //
    private func debugLocation() {
        let filePath = Bundle.main.path(forResource: "test_1114", ofType: "txt")!
        let dict : NSDictionary  = NSDictionary(contentsOf : URL(fileURLWithPath: filePath))!
        
        let locationsText : String = dict.object(forKey: "locations") as! String
        
        var locationArray : [String] = locationsText.components(separatedBy: "\n")
        
        //  先頭行はタイトルなので削除
        locationArray.removeFirst()
        
        for locationValuesText : String in locationArray {
            
            let locationValues : [String] = locationValuesText.components(separatedBy: ",")
            let latitudeString : String = locationValues[2]
            let longitudeString: String = locationValues[3]
            let altitudeString: String = locationValues[4]
            let horizontalAccuracyString: String = locationValues[5]
            let verticalAccuracyString: String = locationValues[6]
            let courseString: String = locationValues[7]
            let speedString: String = locationValues[1]
            let timestampString: String = locationValues[8]
            let timestamp : NSDate = DateUtils.dateFromString(string: timestampString, format: "yyyy-MM-dd HH:mm:ss Z")
            let location : CLLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: atof(latitudeString), longitude: atof(longitudeString)), altitude: atof(altitudeString), horizontalAccuracy : atof(horizontalAccuracyString), verticalAccuracy : atof(verticalAccuracyString), course: atof(courseString), speed: atof(speedString), timestamp: timestamp as Date)
            let locationDataDic = [HealthStoreManager.LMLocationInfoKey : location]
            let not = Notification(name: NSNotification.Name(rawValue: HealthStoreManager.LMLocationUpdateNotification), object: self, userInfo: locationDataDic)
            self.updateLocation(notification: not)
            
        }
    }
    
    //   MARK: 位置情報更新コールバック
    @objc func updateLocation(notification:Notification) {
        let infoDic: Dictionary = notification.userInfo as Dictionary!
        let location: CLLocation? = infoDic[HealthStoreManager.LMLocationInfoKey] as? CLLocation
        let coordinate = location!.coordinate
        self.latValue = coordinate.latitude
        self.lonValue = coordinate.longitude
        var distance : Double = 0
        var invalid = false
        let horizontalAccuracy : Double = (location?.horizontalAccuracy)!
        if horizontalAccuracy < 0 || horizontalAccuracy > WaveSession.ValidHorizontalAccuracy {
            invalid = true
        } else {
            let timeIntervalSinceNow : Double = (location?.timestamp.timeIntervalSinceNow)!
            if timeIntervalSinceNow > 10.0 {
                invalid = true
            } else {
                if self.preLocation != nil {
                    distance = (location?.distance(from: preLocation!))!
                    if distance == 0.0 {
                        invalid = true
                    }
                }
            }
        }
        
        if invalid == false {
            lastUpdatedLocationTime = Date()
            print("distance: \(distance) latitude: \(latValue) longitude: \(lonValue) horizontalAccuracy: \(horizontalAccuracy)")
            //  位置情報を配列に保存します。
            self.locations.append(location!)
            if let currentWaveCount = self.waveSession?.waves.count {
                //  波にのれたのかチェックします
                self.waveSession?.updateLocation(location: location!)
                
                if currentWaveCount < (self.waveSession?.waves.count)! {
                    //  波に乗れた！
                    //  波情報を更新します
                    self.updateWaveInfo()
                }
            }
        } else {
            //  ライディング中の場合は終了します
            if self.waveSession?.endRiding() ?? false {
                //  波情報を更新します
                self.updateWaveInfo()
            }
        }

        self.preLocation = location
    }
    
    //
    //  波情報を表示します
    //
    private func updateWaveInfo() {
        if let wave = self.waveSession?.waves.last {
            //  本数を表示します
            self.waveCount.setText(String(self.waveSession!.waves.count))
            
            //  最後の波の距離を表示します
            self.lastWaveDistance.setText(String(NumUtils.value1(forDoubleValue: wave.distance)))
        }
    }

    //　心拍数通知ハンドラー
    func updateHeartRate(samples: [HKSample]?){
        //心拍数を取得
        guard let heartRateSamples = samples as?[HKQuantitySample] else {return}
        if let sample = heartRateSamples.first {
            
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            //  配列に追加
            self.heartRates.append( (NSDate(), value) )
            print("心拍数 \(value)")
        }
    }
    
    //
    //   MARK: ストップ
    //
    func doStop() {
        //  停止ページのボタンを無効にします。
        self.sessionIP?.stopIC?.disableButtons()
        
        //  ワークアウト停止
        stopSession()
    }

    func saveLocations() {
        var preLocation : CLLocation?
        var locationTexts : [String] = []
        var firstLocationText : String = ""
        if let location = locations.first {
            firstLocationText = "0,\(location.speed),\(location.coordinate.latitude),\(location.coordinate.longitude),\(location.altitude),\(location.horizontalAccuracy),\(location.verticalAccuracy),\(location.course),\(location.timestamp)"
        }
        
        var wavesLocationTexts : [String] = []
        //  ランディング判別されたロケーション情報のみ転送
        if let waves = self.waveSession?.waves {
            for wave in waves {
                for location in wave.cllocations {
                    var distance : CLLocationDistance = 0
                    if preLocation != nil {
                        distance = location.distance(from: preLocation!)
                    }
                    preLocation = location
                    let locationText = "\(distance),\(location.speed),\(location.coordinate.latitude),\(location.coordinate.longitude),\(location.altitude),\(location.horizontalAccuracy),\(location.verticalAccuracy),\(location.course),\(location.timestamp)"
                    locationTexts.append(locationText)
                    
                }
                wavesLocationTexts.append(locationTexts.joined(separator: "\n"))
                locationTexts = []
            }
        }

        let startedAtText = "\(self.workoutStartedAt!)"
        let endedAtText =  "\(self.workoutEndedAt!)"

        //  iPhoneに転送
        if (WCSession.isSupported()) {
            let session = WCSession.default
            //  心拍数と加速度は転送しない
            session.transferUserInfo(["startedAt": startedAtText,"endedAt": endedAtText, "firstLocationText": firstLocationText, "wavesLocationTexts" : wavesLocationTexts])
        }
    }
}
