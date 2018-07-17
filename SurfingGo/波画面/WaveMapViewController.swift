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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

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
