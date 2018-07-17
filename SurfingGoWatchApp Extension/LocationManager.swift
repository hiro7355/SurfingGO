//
//  LocationManager.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/09/27.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

let LMLocationUpdateNotification: String = "LMLocationUpdateNotification"
let LMLocationInfoKey: String = "LMLocationInfoKey"

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    private var currentLocation: CLLocation!
    
    // Singleton
    struct Singleton {
        static let sharedInstance = LocationManager()
    }
    
    // MARK:- Initialized
    override init() {
        
        locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        
        // 位置情報認証状態をチェックしてまだ決まってなければアラート出す
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.notDetermined) {
            // When in Use
            if (self.locationManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization))) {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
        
        // 位置情報をバックグラウンドで取得する際に必要
        // バックグラウンドのトグル入れる
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
    }
    
    // MARK: - CLLocationManagerDelegate Method
    //  位置情報取得を開始
    func startUpdatingLocation()
    {
        self.locationManager.startUpdatingLocation()
    }
    func stopUpdatingLocation()
    {
        self.locationManager.stopUpdatingLocation()
    }

    //  位置情報取得失敗時に呼ばれる
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    // 位置情報取得成功したときに呼ばれる
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        let locationData = locations.last as CLLocation!
        self.currentLocation = locationData
        let locationDataDic = [LMLocationInfoKey : self.currentLocation as Any]
        let center = NotificationCenter.default
        center.post(name: NSNotification.Name(rawValue: LMLocationUpdateNotification), object: self, userInfo: locationDataDic )
    }
    
    //  位置情報の認証ステータスの変更時に呼ばれる
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        if (status == .notDetermined) {
            if (self.locationManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization))) {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
}
