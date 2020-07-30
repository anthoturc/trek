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
    
    private var pathData: PathsData? = nil
    private var currDay: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        updateMap()
        updateUI()
    }
    
    func setLocData(data: PathsData) {
        pathData = data
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
        
        let paths: [[CLLocationCoordinate2D]] = pathData!.paths
        
        if paths.isEmpty { /* require at least two points for line */
            let initialLocation = CLLocation(latitude: 44.0081, longitude: -73.1760)
            mapView.centerToLocation(initialLocation)
            return
        }
        
        // convert all location records into cllocation coordinates
        for path in paths {
            let geoDesicPolyLine = MKGeodesicPolyline(coordinates: path, count: path.count)
            mapView.addOverlay(geoDesicPolyLine)
        }
        
        let avgLat: Double = pathData!.avgLat
        let avgLon: Double = pathData!.avgLon
        let maxLon: Double = pathData!.maxLon
        let minLon: Double = pathData!.minLon
        let maxLat: Double = pathData!.maxLat
        let minLat: Double = pathData!.minLat
        
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
            var randomColor: UIColor { // color the overlays differently (randomly :b)
                let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
                let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
                let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
                return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
            }
            pr.strokeColor = randomColor
            pr.lineWidth = 4
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
