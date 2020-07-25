//
//  LocationRecord.swift
//  trek-360
//
//  Created by Anthony Turcios on 7/24/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//

import Foundation

struct LocationRecord {
    var id: Int32
    var latitude: Double
    var longitude: Double
    
    var description: String { return "\(id) - \(latitude), \(longitude)" }
}
