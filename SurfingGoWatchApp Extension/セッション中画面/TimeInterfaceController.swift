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
    
    
    //  TODO: 削除すること
   // private let healthStore = HKHealthStore()

    @IBOutlet var timer: WKInterfaceTimer!
    
    @IBOutlet var waveCount: WKInterfaceLabel!
    @IBOutlet var lastWaveDistance: WKInterfaceLabel!
    var latValue:Double = 100.0 // Impossible value(-90 to 90)
    var lonValue:Double = 200.0 // Impossible value(-180 to 180)

//    let healthStore = HKHealthStore()
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
        
        // Configure interface objects here.
        self.sessionIP = context as? SessionInterfaceParam
        self.sessionIP?.timeIC = self

        
        self.waveSession = WaveSession()
        
        //HealthKitへのアクセス許可をユーザーへ求める(iPhoneアップでやっているので、ここでは必要ないのかも)
        self.healthStoreManager.requestAccessToHealthKit()
        
        /*
        if HKHealthStore.isHealthDataAvailable() != true {
            print("not available")
            return
        }
        let typesToRead = Set([
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.swimmingStrokeCount)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
            ])
        
        //HealthKitへのアクセス許可をユーザーへ求める
        self.healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            print("requestAuthorizationToShareTypes: \(success) error: \(String(describing: error))")
        }
        */

        //  MARK: ワークアウト開始
        startSession()
        //            workoutStarted(date: Date())
        

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        print("willActivate")
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        print("didDeactivate")
    }
    // MARK:- Private Method
    
    ///    ワークアウト開始
    func startSession(){
        let configuration = HKWorkoutConfiguration()
        
        configuration.activityType = .surfingSports
//        configuration.activityType = .walking
        configuration.locationType = .outdoor
        
        do {
            self.workoutSession = try HKWorkoutSession(configuration: configuration)
            
            //   workoutSessionがコールバックされます
            self.workoutSession.delegate = self
            
            // ヘルスストアへのアクセスを開始します
            healthStoreManager.start(self.workoutSession)

            
        }
        catch let error as NSError {
            // Perform proper error handling here...
            fatalError("*** Unable to create the workout session: \(error.localizedDescription) ***")
        }
            
     
    }
    ///  MARK: ワークアウト終了
    //   healthStoreを終了すると、ワークアウトの終了がコールバックされます
    func stopSession(){
     //   healthStore.end(workoutSession!)
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
          //  print("batteryLevel:\(level)")  //  TODO: コメントアウトすること
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
        /*
         バッテリーの消費がはげしいので、心拍計測をやめる

        healthStoreManager.startHeartRateQuery(from: self.workoutStartedAt) { quantitySamples in
            DispatchQueue.main.async {
                self.updateHeartRate(samples: quantitySamples)
            }
        }
*/
        
        healthStoreManager.startAccumulatingLocationData()
        
        
        // 位置情報のコールバックを設定します
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector:#selector(updateLocation(notification:)),
                           name:NSNotification.Name(rawValue: HealthStoreManager.LMLocationUpdateNotification),
                           object:nil)
        
        //  加速度センサー検出開始
   //     startMotion()
        
        //  ジャイロスコープ検出開始
   //     startGyro()
        
        

    }
    
    //  MARK: 計測停止
    private func stopAccumulatingData() {
        healthStoreManager.stopAccumulatingData()
        
        //  ジャイロスコープ検出停止
        stopGyro()
        
        //  加速度センサー停止
        stopMotion()

    }

    /*
    /// ワークアウトステータス通知
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        //開始
        case .running:
            print("workoutSession: .Running")
            
            DispatchQueue.main.sync {() -> Void in
                
                workoutStarted(date: date)
                
            }

        //終了
        case .ended:
            print("workoutSession: .Ended")
            
            DispatchQueue.main.sync {() -> Void in
                
                workoutStopped()
                
            }
        default:
            print("Unexpected workout session state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workoutSession didFailWithError \(error)")
    }
 */
    
    
 
 /*
    func workoutStarted(date: Date) {
        
        //  ワークアウト開始日時を設定します
        self.workoutStartedAt = date
        
        
        //  心拍数の計測開始
        self.heartRateQuery = createHeartRateStreamingQuery(workoutStartDate: date as NSDate)
        self.healthStore.execute(self.heartRateQuery!)
        
        //  距離の測定開始
        // queryDistance()
        
        //  位置情報の測定開始
        startLocation()
        
        //  加速度センサー検出開始
        startMotion()

        //  ジャイロスコープ検出開始
        startGyro()

        //  タイマー表示開始
        timer.start()
        
        self.isRunning = true

    }
    func workoutStopped() {

        //  ワークアウト停止日時を設定します
        self.workoutEndedAt = Date()

        //  ジャイロスコープ検出停止
        stopGyro()
        
        //  加速度センサー停止
        stopMotion()
        
        //  位置情報の取得停止
        stopLocation()
        
        //  心拍数の取得停止
        self.healthStore.stop(self.heartRateQuery!)
        
        //  タイマー表示停止
        timer.stop()
        
        self.isRunning = false
        
        if self.isKeep {
            
            
            //  位置情報をファイルに保存
            saveLocations()
            
            self.isKeep = false
        }

        //  スタート画面にもどります
        RootInterfaceController.showStartPages()

        
    }
    /// 位置情報の測定開始
    func startLocation() {
        // Access Location Service
        LocationManager.Singleton.sharedInstance.startUpdatingLocation()
        
        // Set NSNotification
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector:#selector(updateLocation(notification:)),
                           name:NSNotification.Name(rawValue: LMLocationUpdateNotification),
                           object:nil)
        
    }
    
    func stopLocation() {
        
        LocationManager.Singleton.sharedInstance.stopUpdatingLocation()

        let center = NotificationCenter.default
        center.removeObserver(self);
        

    }
    */
    // 加速度センサーの取得開始
    func startMotion() {
        if motionManager.isDeviceMotionAvailable {
            
            motionManager.deviceMotionUpdateInterval = 0.1
            
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
             //   print("deviceMotionUpdated:" + data.debugDescription)
                
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
                /*
                let cosT = (user?.x * gravity?.x + user?.y * gravity?.y + user?.z * gravity?.z) /
                    sqrt((pow(user?.x, 2) + pow(user?.y, 2) + pow(user?.z, 2)) *
                        (pow(gravity?.x, 2) + pow(gravity?.y, 2) + pow(gravity?.z, 2)));
                */
                // ユーザー加速度の大きさにcosθを乗算してユーザー加速度の重力方向における大きさを算出し、小数点第3位で丸める
                let gravityDirectionMagnitude = round(magnitude * cosT * 100) / 100
                
                if gravityDirectionMagnitude >= 4.0 || gravityDirectionMagnitude <= -4.0 {
//                    print("deviceMotionMagunitude: \(gravityDirectionMagnitude) heading: \((data?.heading)!) magneticField: \((data?.magneticField)!) attitude: \((data?.attitude)!) rotationRate: \((data?.rotationRate)!)")
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
//        let filePath = Bundle.main.path(forResource: "test_ibii", ofType: "txt")!
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
        if horizontalAccuracy < 0 || horizontalAccuracy > 50 {
            invalid = true
        } else {
            
            let timeIntervalSinceNow : Double = (location?.timestamp.timeIntervalSinceNow)!
            if timeIntervalSinceNow > 10.0 {
                invalid = true
            } else {
                
                if self.preLocation != nil {
                    distance = (location?.distance(from: preLocation!))!
                }
                
                if distance == 0.0 {
                    invalid = true
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
                    self.waveSession?.waves.last?.calc() //  速度など計算します
                    
                    //  波情報を更新します
                    self.updateWaveInfo()
                    
                }
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
/*
    //　心拍数測定用のクエリーを作成
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) ->HKQuery{
        let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        let heartRateQuery = HKAnchoredObjectQuery(type: sampleType!, predicate: nil, anchor: nil, limit: 0) { (query, sampleObjects, DelObjects, newAnchor, error) -> Void in
        }
        //アップデートハンドラーを設定
        //心拍数情報が更新されると呼ばれる
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.updateHeartRate(samples: samples)
        }
        
        return heartRateQuery
    }
    
    
    ///  ランニング距離取得用のクエリー
    func queryDistance() {
        guard let type = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            fatalError("Something went wrong retriebing quantity type distanceWalkingRunning")
        }
        let date = NSDate() as Date
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
        
        let predicate = HKQuery.predicateForSamples(withStart: newDate as Date, end: NSDate() as Date, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: [.cumulativeSum]) { (query, statistics, error) in
            var value: Double = 0
            
            if error != nil {
                print("something went wrong")
            } else if let quantity = statistics?.sumQuantity() {
                value = quantity.doubleValue(for: HKUnit.meter())
            }
            
            DispatchQueue.main.async {
                self.updateDistance(value: value)
            }
        }
        healthStore.execute(query)
    }
    
    */
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
    /*
    func updateDistance(value: Double ){
        print("距離 \(value)")
    }
      ///   緯度と経度を遷移先のマップ画面に渡す
    @IBAction func doMap() {
        guard self.latValue != 100.0 && self.lonValue != 200.0 else {
            return // 値が取れなかったとき
        }
        let locationData: [String : Double] = ["latitude": self.latValue, "longitude" : self.lonValue]
        
        self.presentController(withName: "idMapInterface", context: locationData)
    }
    */
    
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
        
        
        //  TODO: for debug
   //    self.debugLocation()
        //
        
        //locationTexts.append("distance,speed,latitude,longitude,altitude,horizontalAccuracy,veticalAccuracy,course,timestamp")
        
        /*
        //  全ロケーション情報を転送
        for location in locations {

            var distance : CLLocationDistance = 0
            if preLocation != nil {
                distance = location.distance(from: preLocation!)
            }
            preLocation = location
            
            let locationText = "\(distance),\(location.speed),\(location.coordinate.latitude),\(location.coordinate.longitude),\(location.altitude),\(location.horizontalAccuracy),\(location.verticalAccuracy),\(location.course),\(location.timestamp)"
            
            locationTexts.append(locationText)
        }
        */
        
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
                
                /*
                for location in wave.tempLocations {
                    let distance = location.distance(from: preLocation!)
                    preLocation = location
                    let locationText = "\(distance),\(location.speed),\(location.coordinate.latitude),\(location.coordinate.longitude),\(location.altitude),\(location.horizontalAccuracy),\(location.verticalAccuracy),\(location.course),\(location.timestamp)"
                    locationTexts.append(locationText)
                }
*/
            }
        }

        /*
        var heartRateTexts : [String] = []
        heartRateTexts.append("timestamp,heartRate")

        for heartRate in heartRates {
            let date : NSDate = heartRate.0
            
            let heartRateText = "\(date),\(heartRate.1)"
            
            heartRateTexts.append(heartRateText)
        }

        var magunitudeTexts : [String] = []
        
        magunitudeTexts.append("timestamp,magunitude")
        
        for magunitude in magunitudes {
            let date : NSDate = magunitude.0
            
            let magunitudeText = "\(date),\(magunitude.1)"
            
            magunitudeTexts.append(magunitudeText)
        }
*/
        
        let startedAtText = "\(self.workoutStartedAt!)"
        let endedAtText =  "\(self.workoutEndedAt!)"
        

        //  iPhoneに転送
        if (WCSession.isSupported()) {
            let session = WCSession.default
//            session.transferUserInfo(["startedAt": startedAtText,"endedAt": endedAtText, "locations": locationTexts.joined(separator: "\n"), "heartRates": heartRateTexts.joined(separator: "\n"), "magunitudes": magunitudeTexts.joined(separator: "\n")])
            //  心拍数と加速度は転送しない
//            session.transferUserInfo(["startedAt": startedAtText,"endedAt": endedAtText, "locations": locationTexts.joined(separator: "\n")])

            session.transferUserInfo(["startedAt": startedAtText,"endedAt": endedAtText, "firstLocationText": firstLocationText, "wavesLocationTexts" : wavesLocationTexts])

        }


        /*  ファイル転送する場合は以下
         let dic: NSMutableDictionary = ["startedAt": startedAtText,"endedAt": endedAtText, "locations": locationTexts.joined(separator: "\n"), "heartRates": heartRateTexts.joined(separator: "\n"), "magunitudes": magunitudeTexts.joined(separator: "\n")]

        self.fileName = DateUtils.stringFromDate(date: NSDate(), format: "YYYYMMdd_HHmmSS") +  ".txt"

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = "\(documentsPath)/\(self.fileName)"
        dic.write(toFile: path, atomically: true)
        
        
        if (WCSession.isSupported()) {
            let session = WCSession.default
            // iPhoneに転送します
            let url = URL(fileURLWithPath: path)
            session.transferFile(url,metadata:nil)
        }
 */
        
    }
    
}
