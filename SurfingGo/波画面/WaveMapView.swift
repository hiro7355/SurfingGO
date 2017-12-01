//
//  WaveMapView.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/29.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift


class WaveMapView: MKMapView, MKMapViewDelegate {

    var waveSession : WaveSession?
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func set( waveSession: WaveSession){

        
        self.waveSession = waveSession
        
        if self.delegate == nil {
            self.delegate = self
        }
     //   self.setRegion()

        
        /*
        //  まず、最初の波を中心とした日本全体ぐらいの地図を表示します。
        if waveSession.waves.count > 0 {
            if let lc = waveSession.waves[0].locationList.first {
                let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lc.latitude, longitude: lc.longitude)
                self.setCenter(location, animated: false)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    //  波の領域にズームインます
                    self.setRegion()
                }

            }
        }
 */
    }
    
    func showWavesZoomin(specifiedWave: Wave?, doneHandler: ((Bool)->Void)? = nil) {
        
        if let waveSession = self.waveSession {
            
            //  まず、最初の波を中心とした日本全体ぐらいの地図を表示します。
            if waveSession.waves.count > 0 {
                if let lc = waveSession.waves[0].locationList.first {
                    let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lc.latitude, longitude: lc.longitude)
                    self.setCenter(location, animated: false)
                }
            }
            /////////
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                // 0.1秒後に実行したい処理
                // 　サーフポイントにズームインします
                self.showWaves(showWaveLineDelay : 1.0, specifiedWave:specifiedWave, doneHandler:doneHandler)
            })

        
        }

    }
    func showWaves(showWaveLineDelay : Double, specifiedWave: Wave?, doneHandler: ((Bool)->Void)? = nil) -> Void {
        
        if let waveSession = self.waveSession {
            
            let waves = waveSession.waves
            
            if waves.count > 0 {
                
                var maxLat : CLLocationDegrees = -90
                var maxLon : CLLocationDegrees = -180
                var minLat : CLLocationDegrees = 90
                var minLon : CLLocationDegrees = 180
                
                for wave in waves{
                    
                    
                    let locations = wave.locationList
                    
                    for location in locations {
                        if location.latitude > maxLat {
                            
                            maxLat = location.latitude
                        }
                        if location.latitude < minLat {
                            
                            minLat = location.latitude
                        }
                        if location.longitude > maxLon {
                            
                            maxLon = location.longitude
                        }
                        if location.longitude < minLon {
                            
                            minLon = location.longitude
                        }
                        
                    }
                    
                }
                
                let latitude     = (maxLat + minLat) / 2;
                let longitude    = (maxLon + minLon) / 2;
                let latitudeDelta  = (maxLat - minLat) != 0 ? (maxLat - minLat) + 0.0003 : 0.01;
                let longitudeDelta = (maxLon - minLon) != 0 ? (maxLon - minLon) + 0.0003 : 0.01;
                
                let region : MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
                
                //        self.mapView.region = region
                self.setRegion(region, animated: true)
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + showWaveLineDelay) {
                    self.showWaveLines(index: 0, specifiedWave:specifiedWave, doneHandler: doneHandler)
                }
            }


        }
    }
    
    //
    //  波の線を引きます
    //
    private func showWaveLines(index : Int, specifiedWave: Wave?, doneHandler: ((Swift.Bool) -> Swift.Void)? = nil) -> Void {
        
        if index == 0 {
            self.removeOverlays(self.overlays)
        }
        
        if let waveSession = self.waveSession {
            if index < waveSession.waves.count {
                
                let wave = waveSession.waves[index]
                
                let isSpecified = (specifiedWave == wave ? true : false)
                
                self.showWaveLine(waveSession: waveSession, waveIndex: index, locationIndex: 0, lastOverlays: nil, isSelected: index == 0 ? true : false, isSpecified: isSpecified , removeEndCircle:index + 1 == waveSession.waves.count ? false : true, doneHandler: { (result) in
                    print("線をひいた")
                    
                    if index + 1 < waveSession.waves.count {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // 0.1秒後に実行したい処理
                            // 　次の波を表示
                            self.showWaveLines(index: index+1, specifiedWave: specifiedWave,  doneHandler: doneHandler)
                            
                            
                        }
                    } else {
                        
                        //  全部の波をひいた
                        if let completion = doneHandler {
                            completion(true)
                        }
                    }

                })
              }

        }
        
        
    }
    
    func showWaveLine(waveSession: WaveSession, waveIndex:Int,  locationIndex:Int, lastOverlays: [MKOverlay]?,isSelected:Bool,isSpecified:Bool, removeEndCircle:Bool, doneHandler:((Bool)->Void)? = nil) -> Void {

        let wave = waveSession.waves[waveIndex]

        if locationIndex < wave.locationList.count {
            

            var locations : [Location] = []
            
            for i in 0...locationIndex {
                locations.append(wave.locationList[i])
            }
            
            
            let firstLatitude : Double = (locations.first?.latitude)!
            let firstLongitude : Double = (locations.first?.longitude)!
            let lastLatitude : Double = (locations.last?.latitude)!
            let lastLongitude : Double = (locations.last?.longitude)!
            
            var firstLocation : Location!
            
            var coordinates : [CLLocationCoordinate2D] = []
            for location in locations {
                if firstLocation == nil {
                    firstLocation = location
                } else if firstLocation.latitude == location.latitude && firstLocation.longitude == location.longitude {
                    // TODO: ここにくるのはおかしいのでなおすこと
                    print("位置情報の記録がおかしい！！")
                    if let completion = doneHandler {
                        completion(true)
                    }
                    return
                    
                }
                
                coordinates.append(CLLocationCoordinate2D(latitude: location.latitude, longitude : location.longitude))
                
                
            }
            
            // polyline作成.
            let polyLine: RidingPolyline = RidingPolyline(coordinates: coordinates, count: coordinates.count)
            
            polyLine.isSelected = isSelected
            polyLine.isSpecified = isSpecified

            polyLine.waveNumber = waveIndex + 1
            
            /*
            if waveIndex == 0 {
                polyLine.isSelected = true
            }
            */
            //  開始と終了位置をマークします
            let startCircle = MKCircle(center: CLLocationCoordinate2D(latitude : firstLatitude, longitude : firstLongitude), radius: 1)
            let endCircle = MKCircle(center: CLLocationCoordinate2D(latitude : lastLatitude, longitude : lastLongitude), radius: 1)
            
            polyLine.startCircle = startCircle
            polyLine.endCircle = endCircle
            
            let overlays = [polyLine, startCircle, endCircle] as [MKOverlay]
//            let overlays = [polyLine, endCircle] as [MKOverlay]

            if let lastOverlays = lastOverlays {
                self.removeOverlays(lastOverlays)
            }
            self.addOverlays(overlays)
            

            if locationIndex + 1 < wave.locationList.count {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // 0.1秒後に実行したい処理
                    // 　次の位置まで表示
                    self.showWaveLine(waveSession: waveSession, waveIndex: waveIndex, locationIndex:locationIndex+1, lastOverlays: overlays,isSelected: isSelected,isSpecified: isSpecified, removeEndCircle:removeEndCircle, doneHandler: doneHandler)
                }
            } else {
                
                //  全部の位置をひいた
                if let completion = doneHandler {
                    completion(true)
                }
                if removeEndCircle {
                    //  ライディングの終了マークを削除します
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
              //          self.remove(endCircle)
                    }
                }
            }

            
        }

    }
    
    /*
     addOverlayした際に呼ばれるデリゲートメソッド.
     */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let polyline = overlay as? RidingPolyline {
            
            // rendererを生成.
            let myPolyLineRendere: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
            
            // 線の太さを指定.
            myPolyLineRendere.lineWidth = 2
            
            // 線の色を指定.
            if polyline.isSpecified {
                myPolyLineRendere.strokeColor = UIColor.red
            } else if polyline.isSelected {
                myPolyLineRendere.strokeColor = UIColor.cyan
            } else {
                myPolyLineRendere.strokeColor = UIColor.cyan
            }
            
            return myPolyLineRendere
        } else {
            let circleRenderer : MKCircleRenderer = MKCircleRenderer(overlay: overlay);
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.7, alpha: 0.2)
            circleRenderer.lineWidth = 1.0
            return circleRenderer
        }
    }

    
    //  MARK: マップビューが表示されたら呼び出されます
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        print("mapViewregionDidChangeAnimated")
        
    }
      func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        print("mapViewDidSelect")
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView){
        print("mapViewDidDeselect")
    }
    /*
    //  MARK:  描画
    override func draw(_ rect: CGRect) {
        if let waveSession = self.waveSession {
            
            for index in 0..<waveSession.waves.count {
                let wave = waveSession.waves[index]
                
                let locations = wave.locationList
                
                self.draw(rect: rect, locations : locations)
                
            }
        }
    }
    func draw(rect : CGRect, locations : List<Location>){
        
        
        let count = locations.count
        
        if count > 0 {
            if let context = UIGraphicsGetCurrentContext() {
                
                context.setStrokeColor(UIColor.red.cgColor)
                
                context.setFillColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
                
                // ラインの幅を設定
                context.setLineWidth(2.0);
                
                
                for locationIndex in 0..<count {
                    
                    let location = locations[locationIndex]

                    let point = self.convert(CLLocationCoordinate2D(latitude:location.latitude, longitude:location.longitude), toPointTo: self)

                    if locationIndex == 0 {
                        context.move(to: point)
                    } else {
                        context.addLine(to: point)
                    }
                }
                
                context.strokePath()
            }
            
        }
    
    }
    
    */

    
    func removePolyline(polyline: RidingPolyline) {
        
        if let startCircle = polyline.startCircle {
            self.remove(startCircle)
        }
        if let endCircle = polyline.endCircle {
            self.remove(endCircle)
        }
        self.remove(polyline)
    }
}
