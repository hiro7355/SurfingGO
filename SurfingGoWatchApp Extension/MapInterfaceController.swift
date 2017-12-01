//
//  MapInterfaceController.swift
//  SurfingGoWatchApp Extension
//
//  Created by 野澤 通弘 on 2017/09/27.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import WatchKit
import Foundation


class MapInterfaceController: WKInterfaceController {

    @IBOutlet var mapView: WKInterfaceMap!
    
    var locationData: [String : Double] = [:]
    
    // MARK:- Life Cycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        guard let contextData = context else {
            // 受け取った context が nil だったら前の画面に戻す
            popToRootController()
            return
        }
        self.locationData = contextData as! [String : Double]
        let latValue = locationData["latitude"]
        let lonValue = locationData["longitude"]
        
        let mapLocation = CLLocationCoordinate2DMake(latValue!, lonValue!)
        let coordinateSpan = MKCoordinateSpanMake(0.02, 0.02)
        
        self.mapView.addAnnotation(mapLocation, with: WKInterfaceMapPinColor.red)
        self.mapView.setRegion(MKCoordinateRegionMake(mapLocation, coordinateSpan))
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
