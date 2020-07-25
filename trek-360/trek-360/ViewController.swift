//
//  ViewController.swift
//  trek-360
//
//  Created by Anthony Turcios on 6/30/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//

import UIKit

import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var locationLbl: UILabel!
    
    @IBOutlet weak var startLocatingBtn: UIButton!
    @IBOutlet weak var getLocationBtn: UIButton!
    @IBOutlet weak var stopLocatingBtn: UIButton!
    
    var locServices: LocationBrain!
    var dbServices: StorageBrain!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationLbl.textColor = UIColor.black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locServices = LocationBrain()
        dbServices = StorageBrain()
        super.viewDidAppear(animated)
        if !locServices.allowedToLocate() {
            disableUI()
            sendAlert(
                withTitle: "Location services are required.",
                withMessage: "Please enable location services in Settings to run the app."
            )
            updateUI(newLblText: "Please enable location services to use this app's functionality")
        } else {
            /* only setup database if we are able to get locations */
            enableUI()
            updateUI(newLblText: "Press 'Start Locating' to display your current location!")
        }
    }
    
    @IBAction func takeLocationPressed(_ sender: UIButton) {
        var newText: String = "To get location press 'Start Locating'."
        if locServices.tracking() {
            let loc: CLLocationCoordinate2D = locServices.getLocation()
            dbServices.addRecord(latitude: Double(loc.latitude), longitude: Double(loc.longitude))
            newText = locServices.getLocationString()
        }
        updateUI(newLblText: newText)
    }
    
    @IBAction func startLocationPressed(_ sender: UIButton) {
        locServices.startTracking()
        dbServices.start()
        updateUI(newLblText: "Press 'Get Location' to find coordinates")
    }
    

    @IBAction func stopLocatingPressed(_ sender: UIButton) {
        var newText: String = "Your location is no longer being tracked!"
        if locServices.tracking() {
            locServices.stopTracking()
            
            // TODO: have the locations be sent to a server/db off the phone
            // let locations: [LocationRecord] = dbServices.getRecords()
            dbServices.clear()
            dbServices.stop()
        } else {
            newText = "Your location is not currently being tracked!"
        }
        updateUI(newLblText: newText)
    }
    
    func sendAlert(withTitle title: String, withMessage msg: String) {
        let alert: UIAlertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func updateUI(newLblText: String) {
        locationLbl.text = newLblText
    }
    
    func enableUI() {
        startLocatingBtn.isEnabled = true
        getLocationBtn.isEnabled = true
        stopLocatingBtn.isEnabled = true
    }
    
    func disableUI() {
        startLocatingBtn.isEnabled = false
        getLocationBtn.isEnabled = false
        stopLocatingBtn.isEnabled = false
    }
}
