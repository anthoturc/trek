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
    @IBOutlet weak var locationTrackingBtn: UIButton!
    
    private var locServices: LocationBrain!
    private var dbServices: StorageBrain!
    private var locationTimer: Timer?
    private let updateLocTimeInterval: Double = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationLbl.textColor = UIColor.black
        /* enable the day labels to be clicked */
        initDayLabels()
        initControlUI()
        /* there should only be one instance of these two services */
        locServices = LocationBrain()
        dbServices = StorageBrain()
        updateLog(newLblText: "Press 'Start Locating'.")
    }
    
    @objc
    private func recordCurrentLocation() {
        if locServices.tracking() {
            let loc: CLLocationCoordinate2D = locServices.getLocation()
            dbServices.addRecord(latitude: Double(loc.latitude), longitude: Double(loc.longitude))
        }
    }
    
    @IBAction func locationTrackingBtnPressed(_ sender: Any) {
        if !locServices.allowedToLocate() {
            sendAlert(
                withTitle: "Location services are required.",
                withMessage: "Please enable location services in Settings to run the app."
            )
            return
        }
        
        locationTimer?.invalidate()
        if !locServices.tracking() { /* not currently tracking */
            locationTrackingBtn.setTitle("Stop Locating", for: .normal)
            locServices.startTracking()
            locationTimer = Timer.scheduledTimer(timeInterval: updateLocTimeInterval, target: self, selector: #selector(recordCurrentLocation), userInfo: nil, repeats: true)
            updateLog(newLblText: "Recording location.")
        } else { /* currently tracking */
            locationTrackingBtn.setTitle("Start Locating", for: .normal)
            locServices.stopTracking()
            /* the next time the user decides to start a path
             the dbService will need to have a different path number associated with
             that path.
             
             this is done to allow drawing of separate paths */
            dbServices.incrementPathNum()
            // TODO: have the locations be sent to a server/db off the phone
            // TODO: determine when the database should be cleared
            // could check if current day has a table and when it was created..
            updateLog(newLblText: "Press 'Start Locating'.")
        }
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
                lbl.textAlignment = .center
            } else {
                lbl.textAlignment = .left
            }
            
            lbl.isUserInteractionEnabled = true
            lbl.addGestureRecognizer(setGesture())
        }
    }
    
    private func updateLog(newLblText: String) {
        locationLbl.text = newLblText
    }
    
    private func setGesture() -> UITapGestureRecognizer {
        let myRecognizer = UITapGestureRecognizer(target: self, action: #selector(getDaysData))
        return myRecognizer
    }
    
    @objc
    private func getDaysData(sender: UITapGestureRecognizer) {
        let dayLabel: UILabel = sender.view as! UILabel
        
        let currDayName: String = dayLabel.text!
        let dataForChosenDay: PathsData = dbServices.getRecords(for: currDayName)
        let pathDataView: PathDataViewController = self.storyboard?.instantiateViewController(withIdentifier: "PathDataView") as! PathDataViewController
        
        pathDataView.modalPresentationStyle = .popover
        pathDataView.setLocData(data: dataForChosenDay)
        pathDataView.setCurrDay(to: currDayName)
        present(pathDataView, animated: true, completion: nil)
    }
    
    private func initControlUI() {
        let radiusVal: CGFloat = 24.0
        locationTrackingBtn.layer.cornerRadius = radiusVal
    }
}
