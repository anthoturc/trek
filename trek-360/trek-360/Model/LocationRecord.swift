//
//  LocationRecord.swift
//  trek-360
//
//  Created by Anthony Turcios on 7/24/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//

import Foundation
import MapKit

struct LocationRecord {
    
    var id: Int32
    var pathNum: Int32
    var loc: CLLocationCoordinate2D
    
    var description: String { return "\(id) - \(loc.latitude), \(loc.longitude)" }
}
