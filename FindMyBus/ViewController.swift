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

    private var busArr: [MKAnnotation] = []
    private var locationManager: CLLocationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D!
    private let routeURL = "http://192.168.1.4:3000/positions/"
    var timer: Timer?
    let runLoop = RunLoop.current
    var connection: APIRequest?
    weak var delegate: APIRequestDelegate?
    var annotationView: MKAnnotationView?
    var heading: Double = 0
    //let image: UIimage()?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textBus: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        //mapView.mapType = .hybrid
        self.mapView.showsCompass = true
        self.mapView.showsScale = true
        self.mapView.showsUserLocation = true
        self.mapView.isRotateEnabled = false
        self.mapView.isPitchEnabled = false
        self.mapView.delegate = self

        connection = APIRequest()
        connection?.delegate = self
        textBus?.delegate = self
        
        if CLLocationManager.locationServicesEnabled()  == true {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            self.currentLocation = locationManager.location!.coordinate
            self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(currentLocation, 10000, 10000), animated: true)
            //locationManager.requestWhenInUseAuthorization()
        }
    }
        
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            print("All finished")
        }
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textBus?.resignFirstResponder()
        mapView.removeAnnotations(busArr)
        timer?.invalidate()
        self.timer = Timer(timeInterval: 2, target: self, selector: #selector(self.sendRequest), userInfo: nil, repeats: true)
            self.runLoop.add(self.timer!, forMode: RunLoopMode.commonModes)
        sendRequest()
        return true
    }
    
    @objc func sendRequest() {
        self.connection?.sendRoutes(url: self.routeURL, query: (self.textBus?.text!)!)
        print("timer fired")
    }
    
    func getData(data: Data) {
        DispatchQueue.main.async { //remove annotations and build annotations on the main thread
            self.mapView.removeAnnotations(self.busArr)
            self.busArr = []
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                //print(jsonDict)
                if let response = jsonDict.value(forKey: "message") as? NSArray {
                    //print(response)
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
                        let image = UIImage(named: "arrow16px.png")
                        let newImage = image?.imageRotatedByDegrees(degrees: CGFloat(self.heading), image: image!)
                        //self.mapView.selectAnnotation(self.mapView.annotations[i], animated: true)
                        marker.image = newImage
                        self.busArr.append(marker)
                        self.mapView.addAnnotations(self.busArr)
                    }
                }
            }
            } catch let error as NSError {
            print(error.localizedDescription)
        } //end do
        }
    } //end func
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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


