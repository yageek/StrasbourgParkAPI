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

    public func getLocation() -> Future<[StrasbourgParkAPI.LocationOpenData], Error> {
        return Future { [unowned self] result in
            self.getLocations { (r) in
                result(r)
            }
        }
    }

    public func getStatus() -> Future<[StrasbourgParkAPI.StatusOpenData], Error> {
        return Future { [unowned self] o in
            self.getStatus { (result) in
                o(result)
            }
        }
    }
}
#endif
