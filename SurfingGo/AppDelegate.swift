//
//  AppDelegate.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/09/26.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity
import rebekka
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {


    
//    var waveSessions : Results<WaveSession>!
    var nextWaveSessionId : Int = 1
    


    var sessionTableViewController : SessionTableViewController!
    
    let kFtpHostName = "ftp://sv122.wadax.ne.jp"
    let kFtpUploadDir = "/public_html/iphone/debugdata/surfinggo/"
    let kFtpUsername = "ikaika-co-jp"
    let kFtpPassword = "innomessage"
    
    var session: Session!

    var window: UIWindow?
    let healthStore = HKHealthStore()
    
    
    var realm  : Realm!

    override init() {
     
        super.init()
        
        //  realmのマイグレーション
        self.migrateForRealm()
        
        self.realm = try! Realm()
        
        //  ポイントマスターをロードします。
        SurfPoint.updateSurfPoints(realm: realm)

        //  サーフボードマスターをロードします
        SurfBoard.updateSurfBoards(realm: realm)
    }
    // マイグレーション処理
    private func migrateForRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                    migration.enumerateObjects(ofType: "WaveSession", { (oldObject, newObject) in
                        let startedAt = oldObject!["stardedAt"] as! Date
                        newObject!["startedAt"] = startedAt
                    })
                    migration.enumerateObjects(ofType: "Wave", { (oldObject, newObject) in
                        let startedAt = oldObject!["stardedAt"] as! Date
                        newObject!["startedAt"] = startedAt
                    })
                }
        })
        Realm.Configuration.defaultConfiguration = config
    }
    
    func loadWaveSessionsBySection(realm : Realm) -> [Results<WaveSession>] {
        
        self.nextWaveSessionId = (realm.objects(WaveSession.self).sorted(byKeyPath: "id").last?.id ?? 0) + 1

        return WaveSession.loadWaveSessionsBySections(realm: realm)

    }
    func getAndUpdateNextWaveSessionId() -> Int {
        let result = self.nextWaveSessionId
        self.nextWaveSessionId = self.nextWaveSessionId + 1
        return result
    }

    //  iOS側のAppDelegateに、HealthKitへのアクセス許可リクエストを受け取るメソッドを追記
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        self.healthStore.handleAuthorizationForExtension { success, error in
            print("applicationShouldRequestHealthAuthorization: \(success)")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.requestAccessToHealthKit()
        
        self.activateSession()

        self.createFtpSession()

        return true
    }
    
    private func activateSession() {
        
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

    }
    
    func createFtpSession() {
        var configuration = SessionConfiguration()
        configuration.host = kFtpHostName
        configuration.username = kFtpUsername
        configuration.password = kFtpPassword
        self.session = Session(configuration: configuration)
    }
    /*
    func doUploadFtp(text : String) {
        let fileName = "text.txt"
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        let filePath = "\(documentsPath)/\(fileName)"
        
        do {
            try text.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("write error")
        }
        let url = URL(fileURLWithPath : filePath)
        
        let path = kFtpUploadDir + "test.txt"
        self.session.upload(url, path: path) {
            (result, error) -> Void in
            print("Upload file with result:\n\(result), error: \(String(describing: error))\n\n")
        }
    }
 */

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print( "session activationDidCompleteWith error: \(String(describing: error))")
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print( "sessionDidBecomeInactive")
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print( "sessionDidDeactivate")
        

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.activateSession()
        }
    }
    //  MARK: アップルウォッチかuserInfo受信
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

            self.createNewWaveSessionAndAddToRealm(fromWavesLocationTexts: userInfo["wavesLocationTexts"] as? [String], andFirstLocationText: userInfo["firstLocationText"] as? String, andStartedAtText: userInfo["startedAt"] as? String, andEndedAtText: userInfo["endedAt"] as? String)

//            self.createNewWaveSessionAndAddToRealm(fromLocationsText: userInfo["locations"] as? String, andStartedAtText: userInfo["startedAt"] as? String, andEndedAtText: userInfo["endedAt"] as? String)
/*
            //  TODO:  デバッグようにFTPでファイル転送。後で削除すること
            let dic: NSMutableDictionary = ["startedAt": userInfo["startedAt"] as! String,"endedAt": userInfo["endedAt"] as! String, "locations": userInfo["locations"] as! String]
            
            let fileName = DateUtils.stringFromDate(date: NSDate(), format: "YYYYMMdd_HHmmss_SSS") + ".txt"
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let path = "\(documentsPath)/\(fileName)"
            dic.write(toFile: path, atomically: true)
            //  ftpで転送します
            let ftpPath = self.kFtpUploadDir + DateUtils.stringFromDate(date: NSDate(), format: "YYYYMMdd_HHmmss_SSS") + ".txt"
            self.session.upload(URL(fileURLWithPath: path), path: ftpPath) {
                (result, error) -> Void in
                print("Upload file with result:\n\(result), error: \(String(describing: error))\n\n")
                
                self.removeFile(path: path)
            }
 */
        }
    }

    //  MARK: アップルウォッチからファイル受信
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        let path = file.fileURL.path
        print( "session didReceive path \(path)")

        self.createNewWaveSessionAndAddToRealm(fromFilePath: path)
        
      
        /*
        
         print( "session didReceive url \(file.fileURL.absoluteString)")
        let absoluteString = NSString(string: file.fileURL.absoluteString)

        let fileName = absoluteString.lastPathComponent
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let toPath = "\(documentsPath)/\(DateUtils().stringFromDate(date: NSDate(), format: "YYYYMMdd_HHmmSS_") + fileName)"
        let manager = FileManager()
        
        do {
            
            try manager.copyItem(atPath: absoluteString as String, toPath: toPath)
            
            self.createNewWaveSessionAndAddToRealm(fromFilePath: toPath as String)
            
            self.sessionTableViewController.updted(waveSession: nil)
            
            try manager.removeItem(atPath: toPath)
            
        } catch {
            
        }
        */

        //  TODO:  デバッグようにFTPでファイル転送。後で削除すること
        //  ftpで転送します
        let isFtp = true
        let ftpPath = kFtpUploadDir + DateUtils.stringFromDate(date: NSDate(), format: "YYYYMMdd_HHmmss_SSS") + ".txt"
        self.session.upload(file.fileURL, path: ftpPath) {
            (result, error) -> Void in
            print("Upload file with result:\n\(result), error: \(String(describing: error))\n\n")
            
            self.removeFile(path: path)
        }

        if isFtp == false {
            
            removeFile(path: path)
        }

        
        
    }
    
    func removeFile(path: String) {
        //  ファイル削除します
        let manager = FileManager()
        do {
            try manager.removeItem(atPath : path )
        } catch {
            
        }

    }
    

    //
    //  apple watchで収集したロケーション情報ファイルからwaveセッションを生成して、realmに新規登録します
    //
    func createNewWaveSessionAndAddToRealm(fromFilePath: String) {

        //  ファイルからwaveセッションを生成します
        let waveSession : WaveSession = WaveSession.Create(fromFilePath: fromFilePath)
        
        self.createNewWaveSessionAndAddToRealm(fromWaveSession: waveSession)
    }
    
    //  MARK: apple watchで収集したロケーション情報からwaveセッションを生成して、realmに新規登録します
    func createNewWaveSessionAndAddToRealm(fromLocationsText locationsText : String?, andStartedAtText startedAtText : String?, andEndedAtText endedAtText : String?) {
        
        //  データからwaveセッションを生成します
        let waveSession : WaveSession = WaveSession.Create(fromLocationsText: locationsText, andStartedAtText: startedAtText, andEndedAtText: endedAtText)
        
        self.createNewWaveSessionAndAddToRealm(fromWaveSession: waveSession)
    }

    //  MARK: apple watchで収集したロケーション情報からwaveセッションを生成して、realmに新規登録します
    func createNewWaveSessionAndAddToRealm(fromWavesLocationTexts wavesLocationTexts : [String]?,
                                           andFirstLocationText firstLocationText : String?,                                            andStartedAtText startedAtText : String?, andEndedAtText endedAtText : String?) {
        
        //  データからwaveセッションを生成します
        let waveSession : WaveSession = WaveSession.Create(fromWavesLocationTexts: wavesLocationTexts, andFirstLocationText: firstLocationText, andStartedAtText: startedAtText, andEndedAtText: endedAtText)
        
        self.createNewWaveSessionAndAddToRealm(fromWaveSession: waveSession)
    }

    private func createNewWaveSessionAndAddToRealm(fromWaveSession waveSession: WaveSession) {
        //  realm用に位置情報を変換します
        waveSession.commit()
        //  idを設定します
        waveSession.id = self.getAndUpdateNextWaveSessionId()

        var isGettingAddress = false
        
        //  TODO:  位置情報を波とは別にスタート地点の情報にすること
//        if let wave : Wave = waveSession.waves.first {
            
//            if let location = wave.locationList.first {
  
        if let location = waveSession.firstLocation {

                isGettingAddress = true
                //  位置情報から住所を取得します
                GeoUtils.address(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { (address, placemark) in

                    if address != nil && placemark != nil {
                        
                        //  住所が一覧に存在するか調べます
                        if let surfPoint = SurfPoint.find(byAddressKey: address!, in: SurfPoint.surfPointArray) {
                            
                            waveSession.surfPoint = surfPoint
                            
                        } else {
                            
                            //  住所が一覧に存在しないのであらたに登録します
                            let name : String = (placemark!.subLocality != nil ? placemark!.subLocality : placemark!.locality!)!
                            waveSession.surfPoint = SurfPoint.newSurfPoint(name: name, addressKey: address!, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            
                        }
                    } else {
                        //  TODO:  住所取得に失敗した場合の処理をいれること
                    }
                    
                    //  realmに追加します
                    self.add(waveSession: waveSession, toRealm: self.realm)
                    
                    
                }
//            }
        }
        
        if isGettingAddress == false {
            
            // TODO: 位置情報がとれていない場合の対策が必要
            //  realmに追加します
            self.add(waveSession: waveSession, toRealm: self.realm)
        }
    }
    
    func add(waveSession : WaveSession, toRealm : Realm) {
        
        dispatch_sync_main {
            //  realmに追加します
            try! realm.write {
                realm.add(waveSession, update: true)
            }
            
            
            //  更新通知します
            if self.sessionTableViewController != nil {
                self.sessionTableViewController.updated(waveSession: waveSession, atIndexPath: nil)
            }
        }
    }


    
    //  MARK: ヘルスキット　アクセス許可要求
    private func requestAccessToHealthKit() {
        let healthStore = HKHealthStore()
        
        let allTypes = Set([HKObjectType.workoutType(),
//                            HKSeriesType.workoutRoute(),
                            HKObjectType.quantityType(forIdentifier: .heartRate)!,
  //                          HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
//                            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
                            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
//                            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
            ])
        
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                print(error?.localizedDescription ?? "")
            }
        }
    }
    

}

