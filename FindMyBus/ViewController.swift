//
//  ViewController.swift
//  FindMyBus
//
//  Created by Matthew Wynyard on 21/06/18.
//  Copyright © 2018 Niobium. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, APIRequestDelegate {
    
    private var routes: [String] = []
    private var trips: [String] = []
    
    @IBOutlet weak var mapView: MKMapView!
    
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocationCoordinate2D!
    private let routeURL = "http://192.168.1.3:3000/positions/"
    private let query = "112"
    
    var connection: APIRequest?

    override func viewDidLoad() {
        super.viewDidLoad()
        //mapView.mapType = .hybrid
        self.mapView.showsCompass = true
        self.mapView.showsScale = true
        self.mapView.showsUserLocation = true
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
            self.currentLocation = locationManager.location!.coordinate
            self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(currentLocation, 10000, 10000), animated: true)
        }
        
        connection = APIRequest()
        connection?.delegate = self
        connection?.sendRoutes(url: routeURL, query: self.query)
        
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            print("All finished")
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func getData(data: Data) {
        print("Hello")
        //var arr: [String] = []
        //var key: String!
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                print(jsonDict)
                if let response = jsonDict.value(forKey: "message") as? NSArray {
                    print(response)
                    for i in 0..<response.count {
                        let json = response.object(at: i) as! NSDictionary
                        let bus = json.value(forKey: "bus")
                        let id = json.value(forKey: "vehicle_id")
                        let latitude = json.value(forKey: "latitude") as! Double
                        let longitude = json.value(forKey: "longitude") as! Double
                        let bearing = json.value(forKey: "bearing")
                        let marker = Bus(title: bus as! String, subtitle: id as! String, discipline: "bus", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude) )
                        mapView.addAnnotation(marker)
                        
                        
                        
                    }
                }
            }
            
            } catch let error as NSError {
            print(error.localizedDescription)
        } //end do
        //print(arr)
    
    } //end func
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        //print(location)
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
    }
    
//    func enableLocationServices() {
//        locationManager.delegate = self
//        
//        switch CLLocationManager.authorizationStatus() {
//        case .notDetermined:
//            // Request when-in-use authorization initially
//            locationManager.requestWhenInUseAuthorization()
//            break
//            
//        case .restricted, .denied:
//            // Disable location features
//            disableMyLocationBasedFeatures()
//            break
//            
//        case .authorizedWhenInUse:
//            // Enable basic location features
//            enableMyWhenInUseFeatures()
//            break
//            
//        case .authorizedAlways:
//            // Enable any of your app's location features
//            enableMyAlwaysFeatures()
//            break
//        }
//    }
//}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

