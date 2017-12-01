//
//  RidingPolyline.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/14.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import MapKit

class RidingPolyline : MKPolyline {
    var isSelected : Bool = false
    var waveNumber : Int = 0
    var startCircle : MKCircle?
    var endCircle : MKCircle?
    var isSpecified : Bool = false  //  最速または最長のwave

}
