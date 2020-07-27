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

class StorageBrain {
    
    private var db: OpaquePointer?
    
    init() {
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
    }
    
    private func createTable(tableName: String) {
        let createCMD: String = """
CREATE TABLE IF NOT EXISTS \(tableName) \
(id INTEGER PRIMARY KEY AUTOINCREMENT, lat REAL, lon REAL)
"""
        
        if sqlite3_exec(db, createCMD, nil, nil, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
        }
    }
    
    func addRecord(latitude: Double, longitude: Double) {
        /* only add a record to the current day */
        let tableName: String = StorageBrain.getWeekDay()
        /* prepare the insert query */
        let queryString: String = "INSERT INTO \(tableName) (lat, lon) VALUES (?,?)"
        var stmt: OpaquePointer?
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
            return
        }
        
        /* bind the parameters */
        if sqlite3_bind_double(stmt, 1, latitude) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
            return
        }
        
        if sqlite3_bind_double(stmt, 2, longitude) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
            return
        }
        
        /* execute query */
        if sqlite3_step(stmt) != SQLITE_DONE {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
            return
        }
    }
    
    func getRecords(for dayName: String) -> [LocationRecord] {
        var locations: [LocationRecord] = []
        
        /* prepare selection query */
        let queryString = "SELECT * FROM \(dayName)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
            return locations
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            let id = sqlite3_column_int(stmt, 0)
            let lat = sqlite3_column_double(stmt, 1)
            let long = sqlite3_column_double(stmt, 2)
            
            locations.append(LocationRecord(id: id, latitude: lat, longitude: long))
        }
        
        return locations
    }
    
    func clear(tableName: String) {
        
        /* prepare deletion query */
        let queryString = "DELETE FROM \(tableName)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
            return
        }
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("failed to delete rows")
        }
        
        sqlite3_finalize(stmt)
    }
    
    static func getWeekDay() -> String {
        let weekDayNameFromatter = DateFormatter()
        weekDayNameFromatter.dateFormat = "EEEE"
        let weekDayName = weekDayNameFromatter.string(from: Date())
        return weekDayName
    }
}
