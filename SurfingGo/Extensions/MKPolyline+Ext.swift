//
//  MKPolyline+Ext.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/14.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import MapKit
public extension MKPolyline {
    
    public var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: self.pointCount)
        
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        
        return coords
    }
}
