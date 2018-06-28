//
//  ViewController.swift
//  FindMyBus
//
//  Created by Matthew Wynyard on 21/06/18.
//  Copyright © 2018 Niobium. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, APIRequestDelegate { //, UIGestureRecognizerDelegate

    private var busArr: [MKAnnotation] = []
    private var stopArr: [MKAnnotation] = []
    private var locationManager: CLLocationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D!
    private let routeURL = "http://192.168.1.4:3000/positions/"
    private let stopURL = "http://192.168.1.4:3000/stops/"
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var timer: Timer?
    private let runLoop = RunLoop.current
    var connection: APIRequest?
    weak var delegate: APIRequestDelegate?
    private var annotationView: MKAnnotationView?
    private var heading: Double = 0
    private let imageArr = [UIImage(named: "arrow16px.png"), UIImage(named: "arrow32px.png")]
    private let stopImageArr = [UIImage(named: "bus_stop12px.png"), nil]
    private var stopImage = UIImage(named: "bus_stop12px.png")
    private var imageZoom = UIImage(named: "arrow16px.png")!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textBus: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set references and delegates
        connection = APIRequest()
        connection?.delegate = self
        textBus?.delegate = self
        
        appDelegate.vc = ViewController()
        
        //do mapview setup
        self.mapView.showsCompass = true
        self.mapView.showsScale = true
        self.mapView.showsUserLocation = true
        self.mapView.isRotateEnabled = false
        self.mapView.isPitchEnabled = false
        self.mapView.delegate = self
        enableLocationSeervices()
        connection?.requestData(url: stopURL)
        
    }
    
    func enableLocationSeervices() {
        self.locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break

        case .restricted, .denied:
            // Disable location features
            break

        case .authorizedWhenInUse, .authorizedAlways:
             //Enable location features
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            self.currentLocation = locationManager.location!.coordinate
            self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(currentLocation, 10000, 10000), animated: true)
            break
        }
    }
    
    /**
     Creates a new timer and adds it to the runloop
     - parameter timeInterval: The repeat interval in seconds the timer will be fired
     **/
    func startTimer(timeInterval: Int) {
        self.timer = Timer(timeInterval: TimeInterval(timeInterval), target: self, selector: #selector(self.sendRequest), userInfo: nil, repeats: true)
        self.runLoop.add(self.timer!, forMode: RunLoopMode.commonModes)
    }
    
    /**
     Removes timer from the run loop and sets refrence to nil. So timer can be cleaned up
    **/
    func killTimer() {
        timer?.invalidate()
        timer = nil
    }
        
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            print("All finished")
        }
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textBus?.resignFirstResponder()
        mapView.removeAnnotations(busArr)
        killTimer()
        startTimer(timeInterval: 4)
        sendRequest()
        return true
    }
    
     /**
     Sends the url and query from the textbox to the APIRequest class for processing for a URLRequest
     **/
    @objc func sendRequest() {
        self.connection?.requestData(url: self.routeURL, query: (self.textBus?.text!)!)
        //print("timer fired")
    }
    
    func getStops(data: Data) {
        DispatchQueue.main.async { //remove annotations and build annotations on the main thread
            self.mapView.removeAnnotations(self.stopArr)
            self.stopArr = []
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                if let response = jsonDict.value(forKey: "message") as? NSArray {
                    for i in 0..<response.count {
                        let json = response.object(at: i) as! NSDictionary
                        //let id = json.value(forKey: "stop_id")
                        let name = json.value(forKey: "stop_name")
                        let code = json.value(forKey: "stop_code")
                        let latitude = json.value(forKey: "latitude") as! Double
                        let longitude = json.value(forKey: "longitude") as! Double
                        let marker = Bus(title: code as! String, subtitle: name as! String, discipline: "stop", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        
                        marker.image = self.stopImage
                        self.stopArr.append(marker)
                        //self.mapView.addAnnotations(self.stopArr)
                    }
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        } //end do
            //self.mapView.addAnnotations(self.stopArr)
        }
        
    }
    
    func getData(data: Data) {
        DispatchQueue.main.async { //remove annotations and build annotations on the main thread
            self.mapView.removeAnnotations(self.busArr)
            self.busArr = []
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                if let response = jsonDict.value(forKey: "message") as? NSArray {
                    for i in 0..<response.count {
                        let json = response.object(at: i) as! NSDictionary
                        let bus = json.value(forKey: "bus")
                        let id = json.value(forKey: "vehicle_id")
                        let latitude = json.value(forKey: "latitude") as! Double
                        let longitude = json.value(forKey: "longitude") as! Double
                        var bearing = json.value(forKey: "bearing")
                        let marker = Bus(title: bus as! String, subtitle: id as! String, discipline: "bus", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))

                      if bearing is NSNull {
                            bearing = 0 as Double
                        self.heading = bearing as! Double
                        } else {
                        self.heading = bearing as! Double
                        }
                        let image = self.imageZoom
                        let newImage = image.imageRotatedByDegrees(degrees: CGFloat(self.heading), image: image)
                        marker.image = newImage
                        self.busArr.append(marker)
                        
                    }
                }
            }
            } catch let error as NSError {
            print(error.localizedDescription)
        } //end do
        self.mapView.addAnnotations(self.busArr)
        }
    } //end func
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
    }
    
    /**
     Tells the mapview delegate the mapview visible region was changed. The window size is checked then
     the correct icon size is displayed on the map.
     - parameter mapView: The map view whose visible region changed.
     - parameter animated: If true, the change to the new region was animated.
     */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

        let zoomWidth = mapView.visibleMapRect.size.width
        print(zoomWidth)
        if Int(zoomWidth) < 15000  {
            self.mapView.addAnnotations(self.stopArr)
        } else if Int(zoomWidth) >= 15000 && Int(zoomWidth) < 20000 {
            imageZoom = imageArr[0]! //16px
            self.mapView.addAnnotations(self.stopArr)
        } else {
            imageZoom = imageArr[0]! //16px
            self.mapView.removeAnnotations(self.stopArr)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Bus {
            let identifier = "bus"
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.image = annotation.image
            annotationView?.canShowCallout = true
            annotationView?.calloutOffset = CGPoint(x: -5, y: 5)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            return annotationView
        }
    return nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            case .restricted, .denied:
                let alert = UIAlertController(title: "Enable Location Services", message: "Location services should be enabled when using this app.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                    if let url = URL(string: "App-Prefs:root=Privacy&path=LOCATION") {
                        UIApplication.shared.open(url, options: [:], completionHandler: {
                            (success) in
                            self.enableLocationSeervices()
                        })
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                    manager.stopUpdatingLocation()
                }))
                self.present(alert, animated: true, completion: nil)
            break
            case .authorizedWhenInUse:
                manager.startUpdatingLocation()
            break
            case .authorizedAlways:
            break            
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            break
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        killTimer()
    }
} //end class

extension UIImage {
    
    public func imageRotatedByDegrees(degrees: CGFloat, image: UIImage) -> UIImage {

        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(Double.pi)
        }
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
        
        //   // Rotate the image context
        bitmap?.rotate(by: degreesToRadians(degrees))

        bitmap?.draw(image.cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: image.size.width, height: image.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}


