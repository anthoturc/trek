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

    
    @IBOutlet weak var daysStackView: UIStackView!
    @IBOutlet weak var locationLbl: UILabel!
    
    @IBOutlet weak var startLocatingBtn: UIButton!
    @IBOutlet weak var stopLocatingBtn: UIButton!
    
    var locServices: LocationBrain!
    var dbServices: StorageBrain!
    
    var locationTimer: Timer?
    
    private let updateLocTimeInterval: Double = 5
    
    var counter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationLbl.textColor = UIColor.black
        
        /* enable the day labels to be clicked */
        initDayLabels()
        initControlUI()
        
        locServices = LocationBrain()
        dbServices = StorageBrain()
        
        updateUI(newLblText: "Press 'Start Locating'.")
    }
    
    @objc
    private func recordCurrentLocation() {
        if locServices.tracking() {
            let loc: CLLocationCoordinate2D = locServices.getLocation()
            dbServices.addRecord(latitude: Double(loc.latitude), longitude: Double(loc.longitude))
        }
        print("getting app state \(counter)")
        counter += 1
        let appState = UIApplication.shared.applicationState
        if appState == .active {
            print("active")
        } else if appState == .inactive {
            print("inactive")
        } else if appState == .background {
            print("background")
        }
    }
    
    @IBAction func startLocationPressed(_ sender: UIButton) {
        
        if !locServices.allowedToLocate() {
            disableUI()
            sendAlert(
                withTitle: "Location services are required.",
                withMessage: "Please enable location services in Settings to run the app."
            )
            updateUI(newLblText: "Please enable location services to use this app's functionality")
            return
        }
        
        if !locServices.tracking() {
            locServices.startTracking()
            locationTimer?.invalidate()
            locationTimer = Timer.scheduledTimer(timeInterval: updateLocTimeInterval, target: self, selector: #selector(recordCurrentLocation), userInfo: nil, repeats: true)
        }
        
        updateUI(newLblText: "Recording location.")
    }
    

    @IBAction func stopLocatingPressed(_ sender: UIButton) {
        let newText: String = "Press 'Start Locating'."
        locationTimer?.invalidate()
        if locServices.tracking() {
            locServices.stopTracking()
            
            // TODO: have the locations be sent to a server/db off the phone
            
            // TODO: determine when the database should be cleared
            // could check if current day has a table and when it was created..
        }
        updateUI(newLblText: newText)
    }
    
    private func sendAlert(withTitle title: String, withMessage msg: String) {
        let alert: UIAlertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    private func initDayLabels() {
        let n = daysStackView.subviews.count - 1
        /* the first and last label are not days of the week */
        let daysOfWeek = daysStackView.subviews[1..<n]
        let currDay = StorageBrain.getWeekDay()
        /* add tap gesture to weekday labels */
        for view in daysOfWeek {
            let lbl: UILabel = view as! UILabel
            if lbl.text! == currDay {
                lbl.textColor = UIColor.blue
            }
            lbl.isUserInteractionEnabled = true
            lbl.addGestureRecognizer(setGesture())
        }
    }
    
    // TODO: this function name doesn't really
    // make sense anymore (update it)
    private func updateUI(newLblText: String) {
        locationLbl.text = newLblText
    }
    
    private func enableUI() {
        startLocatingBtn.isEnabled = true
        stopLocatingBtn.isEnabled = true
    }
    
    private func disableUI() {
        startLocatingBtn.isEnabled = false
        stopLocatingBtn.isEnabled = false
    }
    
    private func setGesture() -> UITapGestureRecognizer {
        let myRecognizer = UITapGestureRecognizer(target: self, action: #selector(getDaysData))
        return myRecognizer
    }
    
    @objc
    private func getDaysData(sender: UITapGestureRecognizer) {
        let dayLabel: UILabel = sender.view as! UILabel
        let currDayName: String = dayLabel.text!
        let dataForChosenDay: [LocationRecord] = dbServices.getRecords(for: currDayName)
        
        let pathDataView: PathDataViewController = self.storyboard?.instantiateViewController(withIdentifier: "PathDataView") as! PathDataViewController
        pathDataView.modalPresentationStyle = .fullScreen
        pathDataView.setLocData(data: dataForChosenDay)
        present(pathDataView, animated: true, completion: nil)
    }
    
    private func initControlUI() {
        let radiusVal: CGFloat = 24.0
        startLocatingBtn.layer.cornerRadius = radiusVal
        stopLocatingBtn.layer.cornerRadius = radiusVal
    }
}
