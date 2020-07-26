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
    @IBOutlet weak var goBackBtn: UIButton!
    
    private var locData: [LocationRecord] = []
    private var currDay: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        updateMap()
        updateUI()
    }
    
    @IBAction func leavePathDataView(_ sender: Any) {
        mapView.removeOverlays(mapView.overlays)
        mapView.annotations.forEach{mapView.removeAnnotation($0)}
        mapView.delegate = nil
        mapView.removeFromSuperview()
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
    
    private func updateMap() {
        
        if locData.isEmpty {
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
        
        var locations: [CLLocationCoordinate2D] = []
        
        for loc in locData {
            
            maxLat = Double.maximum(maxLat, loc.latitude)
            minLat = Double.minimum(minLat, loc.latitude)
            
            maxLon = Double.maximum(maxLon, loc.longitude)
            minLon = Double.minimum(minLon, loc.longitude)
            
            avgLat += loc.latitude
            avgLon += loc.longitude
            locations.append(
                CLLocationCoordinate2D(
                    latitude: loc.latitude, longitude: loc.longitude
                )
            )
        }
        
        avgLat /= Double(locData.count)
        avgLon /= Double(locData.count)
        let initialLocation = CLLocation(latitude: avgLat, longitude: avgLon)
        let geoDesicPolyLine = MKGeodesicPolyline(coordinates: locations, count: locations.count)
        mapView.addOverlay(geoDesicPolyLine, level: .aboveLabels)
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
