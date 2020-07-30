//
//  StorageBrain.swift
//  trek-360
//
//  Created by Anthony Turcios on 7/24/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//
//  The purpose of the StorageBrain is to store the *current*
//  trek on the user's phone. The alternative would be to constantly
//  send put requests to the server after a location update
//
//  This approach allows us to submit "chunks" of data to the server
//  and decreases the usage of the network


import Foundation
import SQLite3
import MapKit

class StorageBrain {
    
    private var db: OpaquePointer?
    private var currLat: Double
    private var currLon: Double
    private var currPathNum: Int32
    
    private let DEFAULT_PATHS_DATA: PathsData = PathsData(
        paths: [],
        avgLat: 0.0,
        avgLon: 0.0,
        maxLat: 0.0,
        minLat: 0.0,
        maxLon: 0.0,
        minLon: 0.0
    )
    
    init() {
        /* default loc is midd */
        currLat = 44.0081
        currLon = -73.1760
        currPathNum = 0
        
        let dbName: String = "locations.db"
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) .appendingPathComponent(dbName)
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error openning db")
            sqlite3_close(db)
            return
        }
        
        /* ensure all days exist */
        for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"] {
            createTable(tableName: day)
        }
        
        currPathNum = getNextPathNum(for: StorageBrain.getWeekDay())
    }
    
    func incrementPathNum() {
        currPathNum += 1
    }
    
    private func createTable(tableName: String) {
        let createCMD: String = """
CREATE TABLE IF NOT EXISTS \(tableName) \
(id INTEGER PRIMARY KEY AUTOINCREMENT, lat REAL, lon REAL, pathNum INTEGER)
"""
        
        if sqlite3_exec(db, createCMD, nil, nil, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
        }
    }
    
    func addRecord(latitude: Double, longitude: Double) {
        /* do not add location if it is the same as the previous (6 digits of precision) */
        if Double.equal(currLat, latitude, precise: 6) && Double.equal(currLon, longitude, precise: 6) {
            return
        }
        currLat = latitude
        currLon = longitude
        
        /* only add a record to the current day */
        let tableName: String = StorageBrain.getWeekDay()
        /* prepare the insert query */
        let queryString: String = "INSERT INTO \(tableName) (lat, lon, pathNUM) VALUES (?,?,?)"
        var stmt: OpaquePointer?
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error preparing 'INSERT INTO \(tableName) (lat, lon, pathNum) VALUES (?,?,?)': \(err)")
            return
        }
        
        /* bind the parameters */
        if sqlite3_bind_double(stmt, 1, latitude) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error binding latitude: \(err)")
            return
        }
        
        if sqlite3_bind_double(stmt, 2, longitude) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error setting longitude: \(err)")
            return
        }
        
        if sqlite3_bind_int(stmt, 3, currPathNum) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error binding path number: \(err)")
            return
        }
        
        /* execute query */
        if sqlite3_step(stmt) != SQLITE_DONE {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error executing statement: \(err)")
            return
        }
    }
    
    func getRecords(for dayName: String) -> PathsData {
        var paths: [[CLLocationCoordinate2D]] = []
        
        /* prepare selection query */
        let queryString = "SELECT * FROM \(dayName)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error preparing 'SELECT * FROM \(dayName)' string: \(err)")
            return DEFAULT_PATHS_DATA
        }
        
        var pathNum: Int32 = 0
        
        var avgLat: Double = 0.0
        var avgLon: Double = 0.0
        var nPoints: Int = 0
        var minLat: Double = 100000.0
        var maxLat: Double = -100000.0
        var minLon: Double = 100000.0
        var maxLon: Double = -100000.0
        
        var currPath: [CLLocationCoordinate2D] = []
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            let lat = sqlite3_column_double(stmt, 1)
            let lon = sqlite3_column_double(stmt, 2)
            let currRecordPathNum: Int32 = sqlite3_column_int(stmt, 3)
            
            avgLat += lat
            avgLon += lon
            
            if currRecordPathNum != pathNum {
                if currPath.count > 1 { /* only add paths that have more than one point */
                    paths.append(currPath)
                }
                pathNum = currRecordPathNum
                currPath = []
            } else {
                currPath.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            
            nPoints += 1
            
            maxLat = Double.maximum(maxLat, lat)
            minLat = Double.minimum(minLat, lat)
            
            maxLon = Double.maximum(maxLon, lon)
            minLon = Double.minimum(minLon, lon)
        }
        if currPath.count > 1 { // last path needs to be added if valid path
            paths.append(currPath)
        }
        
        if nPoints > 0 {
            avgLon /= Double(nPoints)
            avgLat /= Double(nPoints)
        }
        
        return PathsData(
            paths: paths,
            avgLat: avgLat,
            avgLon: avgLon,
            maxLat: maxLat,
            minLat: minLat,
            maxLon: maxLon,
            minLon: minLon
        )
    }
    
    func clear(tableName: String) {
        
        /* prepare deletion query */
        let queryString = "DELETE FROM \(tableName)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error preparing 'DELETE FROM \(tableName)': \(err)")
            return
        }
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("failed to delete rows")
        }
        
        sqlite3_finalize(stmt)
    }
    
    private func getNextPathNum(for tableName: String) -> Int32 {
        let queryString: String = "SELECT MAX(pathNum) FROM \(tableName)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error preparing 'SELECT MAX(pathNum) FROM \(tableName)': \(err)")
            return 0
        }
        
        if sqlite3_step(stmt) ==  SQLITE_ROW {
            let lastPathNum: Int32 = sqlite3_column_int(stmt, 0)
            return lastPathNum + 1
        }
        
        return 0
    }
    
    static func getWeekDay() -> String {
        let weekDayNameFromatter = DateFormatter()
        weekDayNameFromatter.dateFormat = "EEEE"
        let weekDayName = weekDayNameFromatter.string(from: Date())
        return weekDayName
    }
}


extension Double {
    func precised(_ value: Int = 1) -> Double {
        let offset = pow(10, Double(value))
        return (self * offset).rounded() / offset
    }

    static func equal(_ lhs: Double, _ rhs: Double, precise value: Int? = nil) -> Bool {
        guard let value = value else {
            return lhs == rhs
        }

        return lhs.precised(value) == rhs.precised(value)
    }
}
