//
//  PathsData.swift
//  trek-360
//
//  Created by Anthony Turcios on 7/29/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//

import Foundation
import CoreLocation

struct PathsData {
    var paths: [[CLLocationCoordinate2D]]
    var avgLat: Double
    var avgLon: Double
    var maxLat: Double
    var minLat: Double
    var maxLon: Double
    var minLon: Double
}
