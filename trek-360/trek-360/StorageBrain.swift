//
//  StorageBrain.swift
//  trek-360
//
//  Created by Anthony Turcios on 7/24/20.
//  Copyright © 2020 Anthony Turcios. All rights reserved.
//

import Foundation
import SQLite3

class StorageBrain {
    
    private let tableName: String = "Locations"
    
    private var db: OpaquePointer?
    init() {
        
    }
    
    private func createTable() {
        let createCMD: String = """
CREATE TABLE IF NOT EXISTS \(tableName) \
(id INTEGER PRIMARY KEY AUTOINCREMENT, lat REAL, lon REAL)
"""
        
        if sqlite3_exec(db, createCMD, nil, nil, nil) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db!))
            print("error creating table: \(err)")
        }
    }
    
    func start() {
        let dbName: String = "locations.db"
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) .appendingPathComponent(dbName)
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error openning db")
            sqlite3_close(db)
            return
        }
        
        createTable()
    }
    
    func stop() {
        sqlite3_close(db)
    }
    
    func addRecord(latitude: Double, longitude: Double) {
        
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
    
    func getAllRecords() -> [LocationRecord] {
        var locations: [LocationRecord] = []
        
        /* prepare selection query */
        let queryString = "SELECT * FROM \(tableName)"
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
}
