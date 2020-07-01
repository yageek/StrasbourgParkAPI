//
//  StrasbourgParkAPITests.swift
//  StrasbourgParkAPITests
//
//  Created by Yannick Heinrich on 03.04.19.
//  Copyright © 2019 Yageek. All rights reserved.
//

import XCTest
@testable import StrasbourgParkAPI

final class StrasbourgParkAPITests: XCTestCase {


    func jsonMock(_ name: String) -> URL {
        return Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "samples")!
    }
    func testLocationLegacyJSON() {

        do {
            let data = try Data(contentsOf: jsonMock("LocationSample"))
            let response = try JSONDecoder().decode(LocationResponse.self, from: data)
            XCTAssertEqual(28, response.locations.count)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testLegacyTimeFormatter() {

        let fmt = LegacyDateTimeFormatter
        var components = DateComponents()
        components.day = 3
        components.month = 4
        components.hour = 08
        components.minute = 0
        components.year = 2019

        // Test Date -> String
        let date = Calendar.current.date(from: components)!
        let stringRepresentation = "mer. 03 avril 2019 à 08:00"
        XCTAssertEqual(stringRepresentation, fmt.string(from: date))

        // Test String -> Date
        guard let computedDate = fmt.date(from: stringRepresentation) else {
            XCTFail("Impossible to parse the time string")
            return
        }
        XCTAssertEqual(date, computedDate)
    }

    func testStatusLegacyJSON() {

        do {
            let data = try Data(contentsOf: jsonMock("StatusResponse"))
            let response = try JSONDecoder().decode(StatusResponse.self, from: data)
            XCTAssertEqual(29, response.states.count)

        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testLocationOpenData() {
        // Load the JSON response

        do {
            let data = try Data(contentsOf: jsonMock("data.strasbourg.eu_locations"))
            _ = try JSONDecoder().decode(OpenDataResponse<LocationOpenData>.self, from: data)

        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testStatusOpenData() {
        // Load the JSON response

        do {
            let data = try Data(contentsOf: jsonMock("data.strasbourg.eu_status"))
            _ = try JSONDecoder().decode(OpenDataResponse<StatusOpenData>.self, from: data)

        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testCall() {
        let client = ParkingAPIClient()

        let exp = expectation(description: "Download pages")

        client.getLocations { (result) in

            defer {
                exp.fulfill()
            }

            do {
                let resp = try result.get()
                print("Resp: \(resp)")
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [exp], timeout: 10.0)
    }

    static var allTests = [
        ("testLocationLegacyJSON", testLocationLegacyJSON),
        ("testLegacyTimeFormatter", testLegacyTimeFormatter),
        ("testStatusLegacyJSON", testStatusLegacyJSON),
        ("testLocationOpenData", testLocationOpenData),
        ("testStatusOpenData", testStatusOpenData),
        ("testCall", testCall)
    ]
}
