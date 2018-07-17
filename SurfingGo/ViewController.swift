//
//  ViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/09/26.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
//import rebekka
import CoreLocation
import RealmSwift

class ViewController: UIViewController {
  
    var downloadUrl : URL!
    var locations : [CLLocation] = []
    var waveSession : WaveSession = WaveSession()
    var waveSessionId : Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print(getTestFilePath())
    }

    //
    //  FTPサーバーからドキュメントフォルダにダウンロードしたtest.txtファイルを読み込みます
    //
    @IBAction func doLoad(_ sender: Any) {
        let filePath : String = getTestFilePath()
        let dict : NSDictionary  = NSDictionary(contentsOf : URL(fileURLWithPath: filePath))!
        let locationsText : String = dict.object(forKey: "locations") as! String
        var locationArray : [String] = locationsText.components(separatedBy: "\n")

        //  先頭行はタイトルなので削除
        locationArray.removeFirst()
        
        for locationValuesText : String in locationArray {
            let locationValues : [String] = locationValuesText.components(separatedBy: ",")
            let latitudeString : String = locationValues[2]
            let longitudeString: String = locationValues[3]
            let altitudeString: String = locationValues[4]
            let horizontalAccuracyString: String = locationValues[5]
            let verticalAccuracyString: String = locationValues[6]
            let courseString: String = locationValues[7]
            let speedString: String = locationValues[1]
            let timestampString: String = locationValues[8]
            let timestamp : NSDate = DateUtils.dateFromString(string: timestampString, format: "yyyy-MM-dd HH:mm:ss Z")
            let location : CLLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: atof(latitudeString), longitude: atof(longitudeString)), altitude: atof(altitudeString), horizontalAccuracy : atof(horizontalAccuracyString), verticalAccuracy : atof(verticalAccuracyString), course: atof(courseString), speed: atof(speedString), timestamp: timestamp as Date)
            //  位置情報をメンバーの配列に追加します
            self.locations.append(location)
        }

        if locations.count > 0 {
            doReverseGeo(location: locations[0])
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doTouchUpInside(_ sender: Any) {
    }
    
    func getTestFilePath() -> String {
        let fileName = "test.txt"

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        return "\(documentsPath)/\(fileName)"
    }

    func writeTextToiCloudContainer(text : String) {
        DispatchQueue.global().async(execute: {
            
            let manager = FileManager.default
            let containerPath = manager.url(forUbiquityContainerIdentifier: nil)
            
            if containerPath != nil {
                
                let documentPath = containerPath?.appendingPathComponent("Documents")
                let filePath = documentPath?.appendingPathComponent("document.txt")
                print("fileURL: \(String(describing: filePath))")

                do {
                    try text.write(to: filePath!, atomically: true, encoding: .utf8)
                } catch {
                    print("write error")
                }
            }
        })
    }

    @IBAction func doAnalize(_ sender: Any) {
        if self.locations.count > 0 {
            for location in locations {
                self.waveSession.updateLocation(location: location)
            }
            self.waveSession.print()
        }
    }
    
    func doReverseGeo(location : CLLocation) {
        // get address
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(pms, error)->Void in
            if error != nil {
                print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                return
            }
            let placemarks : [CLPlacemark] = pms!
            if placemarks.count > 0 {
                let pm = placemarks[0] as CLPlacemark
                
                print("location=\(self.string(fromPlacemark: pm))")
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }

    // 位置情報表示
    func string(fromPlacemark placemark: CLPlacemark) -> String {
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

