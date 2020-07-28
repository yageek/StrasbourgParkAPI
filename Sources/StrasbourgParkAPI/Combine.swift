//
//  File.swift
//  
//
//  Created by Yannick Heinrich on 01.07.20.
//

import Foundation
#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension ParkingAPIClient {

    /// FRP version of `getLocation`
    /// - Returns: A `Future` with `[StrasbourgParkAPI.LocationOpenData]` as content
    public func getLocation() -> Future<[StrasbourgParkAPI.LocationOpenData], Error> {
        return Future { [unowned self] result in
            self.getLocations { (r) in
                result(r)
            }
        }
    }
    
    /// FRP version of `getStatus`
    /// - Returns: A `Future` with `[StrasbourgParkAPI.StatusOpenData]` as content
    public func getStatus() -> Future<[StrasbourgParkAPI.StatusOpenData], Error> {
        return Future { [unowned self] o in
            self.getStatus { (result) in
                o(result)
            }
        }
    }
}
#endif
