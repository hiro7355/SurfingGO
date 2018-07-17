//
//  GeoUtils.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/16.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import Foundation
import CoreLocation

extension CLPlacemark {

    func pointName() -> String? {
        return validName([self.subLocality, self.locality])
    }
    
    func validName(_ names: [String?]) -> String? {
        for name in names {
            if name != nil {
                return name
            }
        }
        return nil
    }
}

class GeoUtils {

    static func address(latitude : Double, longitude : Double,  completion: ((String?, CLPlacemark?) -> Void)?) -> Void {
        let location : CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        GeoUtils.address(fromLocation: location, completion: completion)
    }

    
    static func address(fromLocation location : CLLocation, completion: ((String?, CLPlacemark?) -> Void)?) -> Void {
        // 住所取得
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(pms, error)->Void in
            if error != nil {
                print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                if let completion = completion {
                    completion(nil, nil)
                }
            } else {
                
                let placemarks : [CLPlacemark] = pms!
                if placemarks.count > 0 {
                    let pm = placemarks[0] as CLPlacemark
                    
                    if let completion = completion {
                        completion(GeoUtils.adress(fromPlacemark: pm), pm)
                    }
                } else {
                    print("Problem with the data received from geocoder")
                    if let completion = completion {
                        completion(nil, nil)
                    }
                }
            }
        })
    }
    
    // 住所文字列生成
    static func adress(fromPlacemark placemark: CLPlacemark) -> String {
        var address: String = ""
        
        let lang : String = NSLocale.preferredLanguages.first!
        if lang.starts(with: "ja") {
            
            address = placemark.administrativeArea != nil ? placemark.administrativeArea! : ""
            address += placemark.locality != nil ? placemark.locality! : ""
            address += placemark.subLocality != nil ? placemark.subLocality! : ""
            
        } else {
            
            address = placemark.subLocality != nil ? placemark.subLocality! + " " : ""
            address = placemark.locality != nil ? placemark.locality! : ""
            address += ","
            address += placemark.administrativeArea != nil ? placemark.administrativeArea! : ""
            address += ","
            address += placemark.postalCode != nil ? placemark.postalCode! : ""
            address += ","
            address += placemark.country != nil ? placemark.country! : ""
        }
        return address
    }
}
