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
    
    init(title: String, subtitle: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.discipline = discipline
        self.coordinate = coordinate
        
        super.init()
    } //end init
}//end class
