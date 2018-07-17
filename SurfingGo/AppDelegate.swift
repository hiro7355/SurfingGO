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
//import rebekka
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var nextWaveSessionId : Int = 1
    var sessionTableViewController : SessionTableViewController!
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
            schemaVersion: 2,
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
                if (oldSchemaVersion < 2) {
                    migration.enumerateObjects(ofType: "WaveSession", { (oldObject, newObject) in
                        newObject!["isWatch"] = true
                        newObject!["firstLongitude"] = 0
                        newObject!["firstLatitude"] = 0
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        self.requestAccessToHealthKit()
        
        self.activateSession()

        Thread.sleep(forTimeInterval: 0.5)
        
        return true
    }
    
    private func activateSession() {
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

    }
    
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
        
        
        if WaveSession.surfPoint(fromLocationCoordinate: waveSession.firstLocationCoordinate, completion: { (surfPoint) in
            
            //  surfpointを取得できた
            waveSession.surfPoint = surfPoint
            //  realmに追加します
            self.add(waveSession: waveSession, toRealm: self.realm)
        }
            ) == false {
            
            //  firstLocationがnilのとき
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
                            HKObjectType.quantityType(forIdentifier: .heartRate)!,
                            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            ])
        
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                print(error?.localizedDescription ?? "")
            }
        }
    }
}

