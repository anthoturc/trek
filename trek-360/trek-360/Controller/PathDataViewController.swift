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

class PathDataViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var currDayLbl: UILabel!
    
    private var paths: [[CLLocationCoordinate2D]] = []
    private var currDay: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        updateMap()
        updateUI()
    }
    
    func setLocData(data: [[CLLocationCoordinate2D]]) {
        paths = data
    }
    
    func setCurrDay(to day: String) {
        currDay = day
    }
    
    private func updateUI() {
        mapView.layer.borderWidth = 2
        mapView.layer.borderColor = UIColor.black.cgColor
        
        if currDay == StorageBrain.getWeekDay() {
            currDayLbl.textColor = UIColor.blue
        }
        currDayLbl.text = currDay
    }
    
    private func updateMap() {
        
        if paths.isEmpty { /* require at least two points for line */
            let initialLocation = CLLocation(latitude: 44.0081, longitude: -73.1760)
            mapView.centerToLocation(initialLocation)
            return
        }
        
        var avgLat: Double = 0.0
        var avgLon: Double = 0.0
        
        var minLat: Double = 100000.0
        var maxLat: Double = -100000.0
        var minLon: Double = 100000.0
        var maxLon: Double = -100000.0
        
        var numLocations: Int = 0
        
        for path in paths { // convert all location records into cllocation coordinates
            for loc in path {
                numLocations += 1
                maxLat = Double.maximum(maxLat, loc.latitude)
                minLat = Double.minimum(minLat, loc.latitude)
                
                maxLon = Double.maximum(maxLon, loc.longitude)
                minLon = Double.minimum(minLon, loc.longitude)
                
                avgLat += loc.latitude
                avgLon += loc.longitude
            }
            let geoDesicPolyLine = MKGeodesicPolyline(coordinates: path, count: path.count)
            mapView.addOverlay(geoDesicPolyLine)
        }
        
        avgLat /= Double(numLocations)
        avgLon /= Double(numLocations)
        let initialLocation = CLLocation(latitude: avgLat, longitude: avgLon)
        
        UIView.animate(withDuration: 1.5, animations: { () -> Void in
            let span = MKCoordinateSpan(latitudeDelta: 	fabs(maxLat - minLat), longitudeDelta: fabs(maxLon - minLon))
            let region = MKCoordinateRegion(center: initialLocation.coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
        })
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay is MKPolyline) {
            let pr = MKPolylineRenderer(overlay: overlay)
            pr.strokeColor = UIColor.blue.withAlphaComponent(0.5)
            pr.lineWidth = 2
            return pr
        }
        return MKOverlayRenderer()
    }
}

private extension MKMapView {
    func centerToLocation(
        _ location: CLLocation,
        regionRadius: CLLocationDistance = 100000
    ) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        setRegion(region, animated: true)
        setCameraBoundary(MKMapView.CameraBoundary(coordinateRegion: region), animated: true)
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 100000)
        setCameraZoomRange(zoomRange, animated: true)
    }
}
