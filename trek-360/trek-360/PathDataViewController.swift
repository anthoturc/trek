//
//  PathDataViewController.swift
//  trek-360
//
//  Created by Anthony Turcios on 7/25/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PathDataViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var goBackBtn: UIButton!
    
    private var locData: [LocationRecord] = []
    private var currDay: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let initialLocation = CLLocation(latitude: 44.0081, longitude: -73.1760)
        mapView.centerToLocation(initialLocation)
        
        updateUI()
    }
    
    @IBAction func leavePathDataView(_ sender: Any) {
        mapView.annotations.forEach{mapView.removeAnnotation($0)}
        mapView.delegate = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    func setLocData(data: [LocationRecord]) {
        locData = data
    }
    
    func setCurrDay(day: String) {
        currDay = day
    }
    
    private func updateUI() {
        mapView.layer.borderWidth = 2
        mapView.layer.borderColor = UIColor.black.cgColor
        let radiusVal: CGFloat = 24.0
        goBackBtn.layer.cornerRadius = radiusVal
    }
}

private extension MKMapView {
    func centerToLocation(
        _ location: CLLocation,
        regionRadius: CLLocationDistance = 1000
    ) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        setRegion(region, animated: true)
        setCameraBoundary(MKMapView.CameraBoundary(coordinateRegion: region), animated: true)
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 5000)
        setCameraZoomRange(zoomRange, animated: true)
    }
}
