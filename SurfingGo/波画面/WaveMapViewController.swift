//
//  WaveMapViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/11.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class WaveMapViewController: UIViewController,  UIScrollViewDelegate {

 //   @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapView: WaveMapView!
    
    @IBOutlet weak var waveResultScrollView: UIScrollView!
    @IBOutlet weak var waveResultStackView: UIStackView!

    
    var waveSession : WaveSession!
    var indexPath : IndexPath?
    var realm : Realm!
    var specifiedWave : Wave?

    @IBOutlet weak var pageControl: UIPageControl!
    
    private func setNavigationTransparent() {
        // ナビゲーションを透明にする処理
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
    }
    private func resetNavigationTransparent() {
        // 透明にしたナビゲーションを元に戻す処理
        self.navigationController!.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController!.navigationBar.shadowImage = nil
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //  ナビゲーションバーを透明に
        self.setNavigationTransparent()
        //ナビゲーションタイトル文字列の変更
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
    }
    
     override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 透明にしたナビゲーションを元に戻す処理
        self.resetNavigationTransparent()
        //ナビゲーションタイトル文字列の変更(もとに戻す)
        self.navigationController?.navigationBar.titleTextAttributes = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "ライディング詳細"


        waveResultScrollView.delegate = self
        self.pageControl.numberOfPages = self.waveSession.waves.count
        
        
        self.mapView.set(waveSession: waveSession)
        self.mapView.showWavesZoomin(specifiedWave: self.specifiedWave) { (result) in
            var count : Int = 1
            for wave in self.waveSession.waves {
                
                self.addWaveView(wave: wave, count : count)
                count = count + 1
            }
            
            if self.waveSession.waves.count > 0 {
                //  ライディングの線を選択状態にします
                self.selectWave(number : 1)
            }
        }
    }

    func addWaveView(wave : Wave, count : Int) {
        
        let stack : UIStackView = self.waveResultStackView
        //  波結果ビューを生成します
        let waveResultView = WaveResultView.view(wave : wave, count : count, sessionStartedAt : self.waveSession.startedAt)
        
        stack.addArrangedSubview(waveResultView)
        
        //  スクロールビューと同じ幅の制約を設定します
        waveResultView.translatesAutoresizingMaskIntoConstraints = false
        waveResultView.widthAnchor.constraint(equalTo: self.waveResultScrollView.widthAnchor, multiplier: 1.0).isActive = true
        
        //  スクロールさせるには、スタックビューの制約でtop, leading, bottom, trailing のマージン設定を0に設定する必要があります。
    }
    
    //
    //  波情報結果ビューを削除します
    //
    func remove(waveResultView view: WaveResultView) {
        
        if let wave = view.wave {
            
            //  ライディングの線のオーバーレイを地図から削除します
            if let removedIndex = self.removeOverlays(ofWave : wave) {
                
                //  スタックから削除します
                self.removeFromStack(waveResultView : view, waveNumber: removedIndex+1)
                
                //  結果ビューを削除します
                view.removeFromSuperview()
                
                //  waveSessionからwaveを削除します
                self.waveSession.remove(wave: wave, fromRealm: self.realm)

                //  ページコントロールのページ数を調整します。
                self.pageControl.numberOfPages = self.waveSession.waves.count
                if self.waveSession.waves.count > 0 {
                    
                    // ページコントロールに現在のページ番号を調整します。
                    if self.pageControl.currentPage > self.pageControl.numberOfPages {
                        self.pageControl.currentPage = self.pageControl.numberOfPages
                    }
                    //  ライディングの線を選択状態にします
                    selectWave(number : self.pageControl.currentPage + 1)

                }

                if let parentVC = self.sessionTableViewController() {
                    //  テーブル一覧が再描画されるようにします
                    parentVC.updated(waveSession: self.waveSession, atIndexPath: self.indexPath)
                }
            }
        }
    }
    
    
    func sessionTableViewController() -> SessionTableViewController? {
        
        var retVC : SessionTableViewController?
        if let vcList = navigationController?.viewControllers
        {
            for vc in vcList
            {
                if let stvc = vc as? SessionTableViewController {
                    retVC = stvc
                    break
                }
            }
        }
        return retVC
    }
    private func removeFromStack(waveResultView : WaveResultView, waveNumber : Int) {
        let stack : UIStackView = self.waveResultStackView
        
        //  波情報のビューをスタックから削除します
        stack.removeArrangedSubview(view)
        
        
        //  波番号を更新します
        for view in stack.arrangedSubviews {
            
            if let wrView  = view as? WaveResultView {
                
                if wrView.waveNumber > waveNumber {
                    wrView.update(waveNumber: wrView.waveNumber-1)
                }
                
            }
        }

    }
    private func removeOverlays(ofWave wave: Wave) -> Int? {
        var removedIndex : Int?
        
        if let waveIndex = self.waveSession.index(ofWave: wave) {
            
            
            for overlayIndex in 0..<self.mapView.overlays.count {
                
                
                if let polyline = self.mapView.overlays[overlayIndex] as? RidingPolyline {
                    
                    if polyline.waveNumber == (waveIndex + 1) {
                        
                        self.mapView.removePolyline(polyline: polyline)
                        
                        removedIndex = waveIndex
                        
                        break

                    }
                    
                }
            }
            
            if removedIndex != nil {
                
                //  波の番号をカウントダウンします
                for overlayIndex in 0..<self.mapView.overlays.count {
                    
                    if let polyline = self.mapView.overlays[overlayIndex] as? RidingPolyline {
                        
                        if polyline.waveNumber > (waveIndex + 1) {
                            
                            polyline.waveNumber = polyline.waveNumber - 1
                        }
                    }
                }
            }
            
        }
        return removedIndex
        
    }
    private func deleteStackView(sender: UIButton) {
        if let view = sender.superview {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                view.isHidden = true
            }, completion: { (success) -> Void in
                view.removeFromSuperview()
            })
        }
    }
    /*
    //
    //  詳細ボタンタップ
    //
    @objc dynamic func clickEditButton(sender: UIButton){
        
        let detailVC = SessionEditViewController()
        detailVC.waveSession = self.waveSession
        
        // 遷移履歴に追加する形で画面遷移
        self.navigationController?.pushViewController(detailVC as UIViewController, animated: true)
        
    }
 */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
/*
    
    func setRegion() -> Void {
        

        
        var maxLat : CLLocationDegrees = -90
        var maxLon : CLLocationDegrees = -180
        var minLat : CLLocationDegrees = 90
        var minLon : CLLocationDegrees = 180

        let waves = self.waveSession.waves
        
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
        self.mapView.setRegion(region, animated: true)
        
        
        
    }
    //
    //  波の線を引きます
    //
    private func showWaveLines(index : Int, doneHandler: ((Swift.Bool) -> Swift.Void)? = nil) -> Void {
        
        
        if index < self.waveSession.waves.count {
            
            let wave = self.waveSession.waves[index]
            let locations = wave.locationList
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
                    break
                    
                }
                
                coordinates.append(CLLocationCoordinate2D(latitude: location.latitude, longitude : location.longitude))
                
                
            }
            
            // polyline作成.
            let polyLine: RidingPolyline = RidingPolyline(coordinates: coordinates, count: coordinates.count)
            
            polyLine.waveNumber = index + 1
            
            if index == 0 {
                polyLine.isSelected = true
            }
            
            //  開始と終了位置をマークします
            let startCircle = MKCircle(center: CLLocationCoordinate2D(latitude : firstLatitude, longitude : firstLongitude), radius: 1)
            let endCircle = MKCircle(center: CLLocationCoordinate2D(latitude : lastLatitude, longitude : lastLongitude), radius: 1)
            
            polyLine.startCircle = startCircle
            polyLine.endCircle = endCircle
            
            mapView.addOverlays([polyLine, startCircle, endCircle])

            
            if index + 1 < self.waveSession.waves.count {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // 0.1秒後に実行したい処理
                    // 　次の波を表示
                    self.showWaveLines(index: index+1, doneHandler: doneHandler)
                }
            } else {
                
                //  全部の波をひいた
                if let completion = doneHandler {
                    completion(true)
                }
            }
        }
        /*
        var count : Int = 1
        for wave in self.waveSession.waves {
            
            
            let locations = wave.locationList
            let firstLatitude : Double = (locations.first?.latitude)!
            let firstLongitude : Double = (locations.first?.longitude)!
            let lastLatitude : Double = (locations.last?.latitude)!
            let lastLongitude : Double = (locations.last?.longitude)!
            
             var firstLocation : Location!
            
            var coordinates : [CLLocationCoordinate2D] = []
            for location in wave.locationList {
                if firstLocation == nil {
                    firstLocation = location
                } else if firstLocation.latitude == location.latitude && firstLocation.longitude == location.longitude {
                    // TODO: ここにくるのはおかしいのでなおすこと
                    print("位置情報の記録がおかしい！！")
                    break
                    
                }
                
                coordinates.append(CLLocationCoordinate2D(latitude: location.latitude, longitude : location.longitude))
                
                
            }
            
            // polyline作成.
            let polyLine: RidingPolyline = RidingPolyline(coordinates: coordinates, count: coordinates.count)
            
            polyLine.waveNumber = count
            count = count+1
            
             
            //  開始と終了位置をマークします
            let startCircle = MKCircle(center: CLLocationCoordinate2D(latitude : firstLatitude, longitude : firstLongitude), radius: 1)
            let endCircle = MKCircle(center: CLLocationCoordinate2D(latitude : lastLatitude, longitude : lastLongitude), radius: 1)

            polyLine.startCircle = startCircle
            polyLine.endCircle = endCircle

            mapView.addOverlays([polyLine, startCircle, endCircle])

        }
 */

    }
    */
    
    /*
     addOverlayした際に呼ばれるデリゲートメソッド.
     */
    /*
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let polyline = overlay as? RidingPolyline {
            
            // rendererを生成.
            let myPolyLineRendere: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
            
            // 線の太さを指定.
            myPolyLineRendere.lineWidth = 1
            
            // 線の色を指定.
            if polyline.isSelected {
                myPolyLineRendere.strokeColor = UIColor.red
            } else {
                myPolyLineRendere.strokeColor = UIColor.green
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
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        print("mapViewDidSelect")

    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView){
        print("mapViewDidDeselect")
    }
    */
    //  scrollViewDelegate
    //  スクロール停止時に呼び出される
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        //ページコントロールに現在のページ番号を設定する。
        self.pageControl.currentPage = Int(self.waveResultScrollView.contentOffset.x / self.waveResultScrollView.frame.maxX)

        //  ライディングの線を選択状態にします
        selectWave(number : self.pageControl.currentPage + 1)
    }

    //  ページコントローラータップ時に呼び出される
    @IBAction func tapPageControl(_ sender: UIPageControl) {
        //スクロールビューのX座標を更新する。
        scroll(toPage : sender.currentPage)
        
        //  ライディングの線を選択状態にします
        selectWave(number : sender.currentPage + 1)
    }
    
    func scroll(toPage number : Int) {
        //スクロールビューのX座標を更新します
        waveResultScrollView.contentOffset.x = waveResultScrollView.frame.maxX * CGFloat(number)

    }
    
    @IBAction func mapViewDidTap(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.ended {
            
            
            let tapPoint = sender.location(in: mapView)
            let center : CLLocationCoordinate2D = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            let point : MKMapPoint = MKMapPointForCoordinate(center)

            for overlay in mapView.overlays {
                if let polyline = overlay as? RidingPolyline {
                
                    if MKMapRectContainsPoint(polyline.boundingMapRect, point) {

                        //  選択します
                        selectWave(polyline: polyline)
                        
                        //  選択されたライディングの結果のページに移動します
                        scroll(toPage : polyline.waveNumber - 1)

                        break
                    }
                    
                }
            }
            
            
        }
    }
    
    
    /*
    private func waveIndex(fromPolyline : MKPolyline) -> Int? {
        
        var retIndex : Int?
        
        for index in 0..<self.waveSession.waves.count {
        
            let wave = self.waveSession.waves[index]
            
            if wave.mapOverlays.count > 0 {
                
                let polyline = wave.mapOverlays[0] as! MKPolyline
                
                if polyline == fromPolyline {
                    retIndex = index
                }

            }
        }
        return retIndex
    }
    */
    //
    //  wave番号を指定してライディングの線を選択状態にします
    //  これまで選択されていたライディングは非選択状態にします
    //
    private func selectWave( number : Int ) {
        
        for overlay in mapView.overlays {
            if let polyline = overlay as? RidingPolyline {
                
                if polyline.waveNumber == number {
                    selectWave(polyline : polyline)
                }
            }
        }
        
    }
    
    

    //
    //  ライディングの線を選択状態にします
    //  これまで選択されていたライディングは非選択状態にします
    //
    private func selectWave( polyline : RidingPolyline ) {
        
        if polyline.isSelected == false {
            
            //  いままで選択されていたライディングを非選択状態にします
            self.deselectSelectedWave()

            let waveIndex = polyline.waveNumber - 1
            
            self.mapView.removePolyline(polyline: polyline)

            self.mapView.showWaveLine(waveSession: self.waveSession, waveIndex: waveIndex, locationIndex: 0, lastOverlays: nil,isSelected: true, isSpecified:polyline.isSpecified, removeEndCircle:false)

            /*
            
            polyline.isSelected = true
            //  ライディングの線を再描画します
            mapView.remove(polyline)
            mapView.add(polyline)
            */
            
            
        }

    }
    
    //
    //  選択されているライディングを非選択にします
    //
    private func deselectSelectedWave() {
        for overlay in mapView.overlays {
            if let polyline = overlay as? RidingPolyline {
                if polyline.isSelected {
                    polyline.isSelected = false
                    //  ライディングの線を再描画します
                    mapView.remove(overlay)
                    mapView.add(overlay)

                }
            }
        }
    }
    

}
