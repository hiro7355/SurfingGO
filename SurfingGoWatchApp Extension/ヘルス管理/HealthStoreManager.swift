//
//  HealthStoreManager.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/10/17.
//  Copyright © 2017年 ikaika software. All rights reserved.
//
//  Based on
//  See LICENSE.txt for this sample’s licensing information.
//  Manager for reading from and saving data into HealthKit


import WatchKit
import HealthKit
import CoreLocation

class HealthStoreManager: NSObject, CLLocationManagerDelegate {
    
    static let LMLocationUpdateNotification: String = "LMLocationUpdateNotification"
    static let LMLocationInfoKey: String = "LMLocationInfoKey"
    
    // MARK: - Properties
    var workoutEvents = [HKWorkoutEvent]()
    var totalEnergyBurned: Double = 0
    var totalDistance: Double = 0
    private let healthStore = HKHealthStore()
    private var activeDataQueries = [HKQuery]()
    private var workoutRouteBuilder: HKWorkoutRouteBuilder!
    private var locationManager: CLLocationManager!
    
    // MARK: - Health Store Wrappers
    func start(_ workoutSession: HKWorkoutSession) {
        healthStore.start(workoutSession)
    }
    
    func end(_ workoutSession: HKWorkoutSession) {
        healthStore.end(workoutSession)
    }
    
    func pause(_ workoutSession: HKWorkoutSession) {
        healthStore.pause(workoutSession)
    }
    
    func resume(_ workoutSession: HKWorkoutSession) {
        healthStore.resumeWorkoutSession(workoutSession)
    }
    
    func startActiveEnergyBurnedQuery(from startDate: Date, updateHandler: @escaping ([HKQuantitySample]) -> Void) {
        let typeIdentifier = HKQuantityTypeIdentifier.activeEnergyBurned
        startQuery(ofType: typeIdentifier, from: startDate) { _, samples, _, _, error in
            guard let quantitySamples = samples as? [HKQuantitySample] else {
                print("Active energy burned query failed with error: \(String(describing: error))")
                return
            }
            updateHandler(quantitySamples)
        }
    }

    //  心拍数の計測
    func startHeartRateQuery(from startDate: Date, updateHandler: @escaping ([HKQuantitySample]) -> Void) {
        let typeIdentifier = HKQuantityTypeIdentifier.heartRate
        startQuery(ofType: typeIdentifier, from: startDate) { _, samples, _, _, error in
            guard let quantitySamples = samples as? [HKQuantitySample] else {
                print("Heart rate query failed with error: \(String(describing: error))")
                return
            }
            updateHandler(quantitySamples)
        }
    }
    
    func startAccumulatingLocationData() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("User does not have location services enabled")
            return
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        
        // 位置情報認証状態をチェックしてまだ決まってなければアラート出す
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.notDetermined) {
            // Always
            //            if (self.locationManager.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization))) {
            //                self.locationManager.requestAlwaysAuthorization()
            //            }
            // When in Use
            if (self.locationManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization))) {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopAccumulatingData() {
        for query in activeDataQueries {
            healthStore.stop(query)
        }
        activeDataQueries.removeAll()
        
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
    
    private func startQuery(ofType type: HKQuantityTypeIdentifier, from startDate: Date, handler: @escaping
        (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) {
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        let quantityType = HKObjectType.quantityType(forIdentifier: type)!
        
        let query = HKAnchoredObjectQuery(type: quantityType, predicate: queryPredicate, anchor: nil,
                                          limit: HKObjectQueryNoLimit, resultsHandler: handler)
        query.updateHandler = handler
        healthStore.execute(query)
        
        activeDataQueries.append(query)
    }
    
    // MARK: - Saving Data
    func saveWorkout(withSession workoutSession: HKWorkoutSession, from startDate: Date, to endDate: Date) {
        // Create and save a workout sample
        let configuration = workoutSession.workoutConfiguration
        var metadata = [String: Any]()
        metadata[HKMetadataKeyIndoorWorkout] = (configuration.locationType == .indoor)
        
        let workout = HKWorkout(activityType: configuration.activityType,
                                start: startDate,
                                end: endDate,
                                workoutEvents: workoutEvents,
                                totalEnergyBurned: totalEnergyBurnedQuantity(),
                                totalDistance: totalDistanceQuantity(),
                                metadata: metadata)
        
        healthStore.save(workout) { success, _ in
            if success {
                self.addSamples(toWorkout: workout, from: startDate, to: endDate)
            }
        }
    }
    
    private func addSamples(toWorkout workout: HKWorkout, from startDate: Date, to endDate: Date) {
        // Create energy and distance samples
        let totalEnergyBurnedSample = HKQuantitySample(type: HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
                                                       quantity: totalEnergyBurnedQuantity(),
                                                       start: startDate,
                                                       end: endDate)

        // Add samples to workout
        healthStore.add([totalEnergyBurnedSample], to: workout) { (success: Bool, error: Error?) in
            guard success else {
                print("Adding workout subsamples failed with error: \(String(describing: error))")
                return
            }
            
            // Samples have been added
            DispatchQueue.main.async {
                //  スタート画面にもどります
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let filteredLocations = locations.filter { (location: CLLocation) -> Bool in
            location.horizontalAccuracy <= kCLLocationAccuracyNearestTenMeters
        }
        
        guard !filteredLocations.isEmpty else { return }
        
        let locationData = locations.last as CLLocation!
        let locationDataDic = [HealthStoreManager.LMLocationInfoKey : locationData as Any]
        
        // Notice and send location data. | 通知して位置情報を送信
        let center = NotificationCenter.default
        center.post(name: NSNotification.Name(rawValue: HealthStoreManager.LMLocationUpdateNotification), object: self, userInfo: locationDataDic )
    }
    
    // MARK: - Convenience
    func processWalkingRunningSamples(_ samples: [HKQuantitySample]) {
        totalDistance = samples.reduce(totalDistance) { (total, sample) in
            total + sample.quantity.doubleValue(for: .meter())
        }
    }
    
    func processActiveEnergySamples(_ samples: [HKQuantitySample]) {
        totalEnergyBurned = samples.reduce(totalEnergyBurned) { (total, sample) in
            total + sample.quantity.doubleValue(for: .kilocalorie())
        }
    }
    
    private func totalEnergyBurnedQuantity() -> HKQuantity {
        return HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalEnergyBurned)
    }
    
    private func totalDistanceQuantity() -> HKQuantity {
        return HKQuantity(unit: HKUnit.meter(), doubleValue: totalDistance)
    }
    
    //  MARK: ヘルスキット　アクセス許可要求
    func requestAccessToHealthKit() {
        
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
