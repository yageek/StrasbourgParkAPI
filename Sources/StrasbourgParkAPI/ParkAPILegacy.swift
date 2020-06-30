//
//  ParkAPI.swift
//  ParkAPI
//
//  Created by Yannick Heinrich on 03.04.19.
//  Copyright © 2019 Yageek. All rights reserved.
//

import Foundation
import CoreLocation

//swiftlint:disable identifier_name
let LegacyDateTimeFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "fr_FR")
    fmt.dateFormat = "eee dd MMMM yyyy 'à' HH:mm"
    return fmt
}()
//swiftlint:enable identifier_name

// MARK: - Location Response
/// The response from the API asking for the parkings
/// location
public struct LocationResponse: Decodable {

    private enum ContainerKeys: String, CodingKey {
        case source = "s"
    }

    /// The parking locations
    public let locations: [ParkingLocation]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerKeys.self)
        self.locations = try container.decode([ParkingLocation].self, forKey: .source)
    }
}

// MARK: - Parking Location

/// The description of a parkign location
public struct ParkingLocation: Decodable {

    /// The API id of thre parking
    public let id: String

    /// The geographical coordinate of the parking
    public let location: CLLocation

    /// Information about the the society managing the parking
    public let manager: Manager

    /// A description of the prices indexed by the language ID.
    /// For example, "fr" key gives, if it exists, the price in french
    public let prices: [String: String]

    // MARK: - Manager ID management
    /// A society managing parking
    ///
    /// - cts: The CTS
    /// - vinci: Vinci parking
    /// - parcus: Parcus
    /// - unknown: Unkown societry with the provided names
    public enum Manager: RawRepresentable {
        case cts
        case vinci
        case parcus
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "CTS":
                self = .cts
            case "vinci":
                self = .vinci
            case "parcus":
                self = .parcus
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .cts:
                return "CTS"
            case .vinci:
                return "vinci"
            case .parcus:
                return "parcus"
            case .unknown(let val):
                return val
            }
        }
    }

    fileprivate struct Keys: CodingKey {
        fileprivate enum RawKeys: String {
            case id = "id"
            case managerId = "gest_id"
            case location = "go"
            case name = "ln"
        }

        // Unused here
        var intValue: Int? {
            return nil
        }

        init?(intValue: Int) {
            return nil
        }
        init?(stringValue: String) {
            return nil
        }
        var stringValue: String

        init(_ key: RawKeys) {
            self.stringValue = key.rawValue
        }

        init(priceLang lang: String) {
            self.stringValue = "price_\(lang)"
        }

    }

    private struct InnerLocation: Decodable {
        let x: Double
        let y: Double
    }

    private static let ExpectedLang: [String] = ["fr", "de", "en"]

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: Keys.self)

        // ID
        self.id = try container.decode(String.self, forKey: Keys(.id))

        // Manager
        let managerId = try container.decode(String.self, forKey: Keys(.managerId))
        self.manager = Manager(rawValue: managerId)

        // Location
        let innerLocation = try container.decode(InnerLocation.self, forKey: Keys(.location))
        self.location = CLLocation(latitude: innerLocation.y, longitude: innerLocation.x)

        // Locales
        let keys = ParkingLocation.ExpectedLang.map { Keys(priceLang: $0) }
        self.prices = keys.reduce(into: [String: String](), { (dict, key) in
            if let value = try? container.decode(String.self, forKey: key) {
                dict[key.stringValue] = value
            }
        })
    }
}

public struct ParkingState: Decodable {

    public let id: String
    public let free: UInt
    public let total: UInt
    public let status: Status

    public enum Status {
        case open, full, notAvailable, closed

        init(stringServerValue val: String) {
            switch val {
            case "status_1":
                self = .open
            case "status_2":
                self = .full
            case "status_3":
                self = .notAvailable
            case "status_4":
                self = .closed
            default:
                self = .notAvailable
            }
        }
    }

    private enum DecodingError: Error {
        case invalidIntString(String)
    }

    private enum Keys: String, CodingKey {
        case id = "id"
        case free = "df"
        case total = "dt"
        case status = "ds"
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: Keys.self)

        self.id = try container.decode(String.self, forKey: .id)

        let freeStr = try container.decode(String.self, forKey: .free)
        guard let free = UInt(freeStr) else {
            throw DecodingError.invalidIntString(freeStr)
        }
        self.free = free

        let totalStr  = try container.decode(String.self, forKey: .total)

        guard let total = UInt(totalStr) else {
            throw DecodingError.invalidIntString(totalStr)
        }

        self.total = total

        let statusRaw = try container.decode(String.self, forKey: .status)
        self.status = Status(stringServerValue: statusRaw)
    }
}

public struct StatusResponse: Decodable {

    let states: [ParkingState]
    let date: Date

    private enum DecodingError: Error {
        case invalidDateFormat(String)
    }

    private enum ContainerKeys: String, CodingKey {
        case s
        case date = "datatime"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerKeys.self)
        // States
        self.states = try container.decode([ParkingState].self, forKey: .s)

        // Date
        let dateString = try container.decode(String.self, forKey: .date)
        guard let date = LegacyDateTimeFormatter.date(from: dateString) else {
            throw DecodingError.invalidDateFormat(dateString)
        }
        self.date = date
    }

}
