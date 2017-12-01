//
//  ViewController.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/09/26.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit
import rebekka
import CoreLocation
import RealmSwift

class ViewController: UIViewController {
  
    let kFtpHostName = "ftp://sv122.wadax.ne.jp"
    let kFtpUploadDir = "/public_html/iphone/debugdata/surfinggo/"
    let kFtpUsername = "ikaika-co-jp"
    let kFtpPassword = "innomessage"
    
    var session: Session!
    
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
        
//        print(locations )
        
        if locations.count > 0 {
            
            doReverseGeo(location: locations[0])
        }
        
        
        
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doTouchUpInside(_ sender: Any) {
        //writeTextToiCloudContainer(text: "1,2,3,4")
        createFtpSession()

 //       doUploadFtp(text: "x,y,z")
        
        testDownload()
    }
    
    
    func createFtpSession() {
        var configuration = SessionConfiguration()
        configuration.host = kFtpHostName
        configuration.username = kFtpUsername
        configuration.password = kFtpPassword
        self.session = Session(configuration: configuration)
    }
    
    
    func getTestFilePath() -> String {
        let fileName = "test.txt"

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        return "\(documentsPath)/\(fileName)"
        
    }
    
    func doUploadFtp(text : String) {
        
        let filePath = getTestFilePath()
        
        do {
            try text.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("write error")
        }
        let url = URL(fileURLWithPath : filePath)
        
        let path = kFtpUploadDir + "test.txt"
        self.session.upload(url, path: path) {
            (result, error) -> Void in
            print("Upload file with result:\n\(result), error: \(String(describing: error))\n\n")
        }
    }
    
    func testDownload() {
        self.session.download("/public_html/iphone/debugdata/surfinggo/test.txt") {
            (fileURL, error) -> Void in
            print("Download file with result:\n\(String(describing: fileURL)), error: \(String(describing: error))\n\n")
            
            if error == nil {
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let path = "\(documentsPath)/test.txt"
                print(path)
                
                do {
                    try FileManager.default.copyItem(	atPath: (fileURL?.path)!, toPath: path)
                } catch {
                    print("copy error")
                }

            }
            
        }
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
            /*
             //  iCloudコンテナを指定します。
             let url = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.jp.co.ikaika.SurfingGo")
             if (url != nil)  {
             
             let fileURL = url?.appendingPathComponent("test.txt")
             print("fileURL: \(String(describing: fileURL))")
             
             
             do {
             try text.write(to: fileURL!, atomically: true, encoding: .utf8)
             } catch {
             print("write error")
             }
             }
             */
        })
    }
    //
    //  
    //
    @IBAction func doAnalize(_ sender: Any) {
        if self.locations.count > 0 {
            

            for location in locations {
                
                self.waveSession.updateLocation(location: location)
            }
            
            
            
            self.waveSession.print()
            
            
            
        }
    }
    
    @IBAction func doSaveToRealm(_ sender: Any) {
        
        let filePath : String = getTestFilePath()

        let app : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            app.createNewWaveSessionAndAddToRealm(fromFilePath: filePath)
        }
        

        
        /*
        
        self.waveSession.id = self.waveSessionId
        self.waveSessionId = self.waveSessionId + 1
        
        self.waveSession.commit()
        
        // Get the default Realm
        let realm = try! Realm()
        
        // Persist your data easily
        try! realm.write {
            realm.add(self.waveSession, update: true)
        }

        self.waveSession = WaveSession()
        
        */
        
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

