//
//  LocationBrain.swift
//  trek-360
//
//  Created by Anthony Turcios on 6/30/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//

import Foundation

import CoreLocation

class LocationBrain : NSObject, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager? = nil
    private var currLocation: CLLocationCoordinate2D? = nil
    private var error: String? = nil
    private var isTracking: Bool = false
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.requestAlwaysAuthorization()
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.delegate = self
    }
    
    // update the current location of the device
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currLocation = locations.last!.coordinate
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error.localizedDescription
    }
    
    func startTracking() {
        locationManager?.startUpdatingLocation()
        locationManager?.requestLocation()
        isTracking = true
    }
    
    func getLocation() -> CLLocationCoordinate2D {
        return currLocation!
    }
    
    func getLocationString() -> String {
        let latStr: String = String(format: "Latitude:\t%0.6f", currLocation?.latitude ?? 0.0)
        let lonStr: String = String(format: "Longitude:\t%0.6f", currLocation?.longitude ?? 0.0)
        return latStr + "\n" + lonStr
    }
    
    func stopTracking() {
        locationManager?.stopUpdatingLocation()
        isTracking = false
    }
    
    func tracking() -> Bool {
        return isTracking
    }
    
    func allowedToLocate() -> Bool {
 
        if !CLLocationManager.locationServicesEnabled() { // location service should be enabled
            return false
        }
        
        let authStatus = CLLocationManager.authorizationStatus() // some form of authorization is needed
        return authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways
    }
}
