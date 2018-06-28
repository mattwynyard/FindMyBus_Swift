//
//  Bus.swift
// FindMyBus
//
//  Created by Matthew Wynyard on 21/06/18.
//  Copyright © 2018 Niobium. All rights reserved.
//

import Foundation
import MapKit

class Bus: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    var image: UIImage? = nil
    
    init(title: String, subtitle: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.discipline = discipline
        self.coordinate = coordinate
        //self.image
        super.init()
    }
        
        init(title: String, subtitle: String, discipline: String, image: UIImage, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.discipline = discipline
        self.coordinate = coordinate
            //self.image
        super.init()        
    } //end init
}//end class
