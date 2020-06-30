//
//  ParkAPIOpenData.swift
//  ParkAPI
//
//  Created by Yannick Heinrich on 03.04.19.
//  Copyright © 2019 Yageek. All rights reserved.
//

import Foundation
import CoreLocation

struct Record<T: Decodable>: Decodable {
    let id: String
    let inner: T

    private enum Keys: String, CodingKey {
        case id = "recordid"
        case inner = "fields"
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: Keys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.inner = try container.decode(T.self, forKey: .inner)
    }
}

struct OpenDataResponse<T: Decodable>: Decodable {

    let total: UInt
    let timeZone: TimeZone
    let count: UInt
    let start: UInt
    let records: [Record<T>]

    private struct Parameters: Decodable {
        let timeZone: TimeZone
        let start: UInt
        let count: UInt

        private enum DecodingError: Error {
            case invalidTimeZoneID(String)
        }

        private enum Keys: String, CodingKey {
            case timeZone = "timezone"
            case count = "rows"
            case start = "start"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)

            self.count = try container.decode(UInt.self, forKey: .count)
            self.start = try container.decodeIfPresent(UInt.self, forKey: .start) ?? 0

            let zoneName = try container.decode(String.self, forKey: .timeZone)
            guard let zone = TimeZone(identifier: zoneName) else { throw DecodingError.invalidTimeZoneID(zoneName) }
            self.timeZone = zone

        }
    }

    private enum Keys: String, CodingKey {
        case total = "nhits"
        case records = "records"
        case parameters = "parameters"
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: Keys.self)

        // Total
        self.total = try container.decode(UInt.self, forKey: .total)

        // Inner parameters
        let parameters = try container.decode(Parameters.self, forKey: .parameters)
        self.count = parameters.count
        self.start = parameters.start
        self.timeZone = parameters.timeZone
        self.records = try container.decode([Record<T>].self, forKey: .records)
    }
}

public struct LocationOpenData: Decodable {

    public let id: String
    public let city: String
    public let zipCode: String
    public let street: String
    public let address: String
    public let location: CLLocation

    public let url: URL
    public let name: String
    public let description: String?

    public let deafAccess: Bool
    public let deficientAccess: Bool
    public let elderAccess: Bool
    public let wheelChairAccess: Bool
    public let blindAccess: Bool

    private enum DecodingError: Error {
        case invalidCoordinate([Double])
        case invalidURL(String)
    }

    private enum Keys: String, CodingKey {
        case id = "idsurfs"
        case city = "city"
        case zipCode = "zipcode"
        case street = "street"
        case address = "address"
        case location = "position"

        case url = "friendlyurl"
        case name = "name"

        case deafAccess = "accessfordeaf"
        case deficientAccess = "accessfordeficient"
        case elderAccess = "accessforelder"
        case wheelChairAccess = "accessforwheelchair"
        case blindAccess = "accessforblind"

        case description = "description"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.city = try container.decode(String.self, forKey: .city)
        self.zipCode = try container.decode(String.self, forKey: .zipCode)
        self.street = try container.decode(String.self, forKey: .street)
        self.address = try container.decode(String.self, forKey: .address)

        // Location
        let location = try container.decode([Double].self, forKey: .location)
        guard location.count == 2 else {
            throw DecodingError.invalidCoordinate(location)
        }
        self.location = CLLocation(latitude: location[0], longitude: location[1])

        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.invalidURL(urlString)
        }
        self.url = url

        self.name = try container.decode(String.self, forKey: .name)

        self.deafAccess = try LocationOpenData.parseBoolForKey(.deafAccess, container: container)
        self.deficientAccess = try LocationOpenData.parseBoolForKey(.deficientAccess, container: container)
        self.elderAccess = try LocationOpenData.parseBoolForKey(.elderAccess, container: container)
        self.wheelChairAccess = try LocationOpenData.parseBoolForKey(.wheelChairAccess, container: container)
        self.blindAccess = try LocationOpenData.parseBoolForKey(.blindAccess, container: container)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }

    private static func parseBoolForKey(_ key: Keys, container: KeyedDecodingContainer<LocationOpenData.Keys>) throws -> Bool {
        let intVal = try container.decode(UInt.self, forKey: key)

        if intVal == 1 {
            return true
        }

        return false
    }
}

public struct StatusOpenData: Decodable {
    public let id: String
    public let name: String
    public let etat: Bool
    public let free: UInt
    public let total: UInt
    public let description: String

    private enum Keys: String, CodingKey {
        case id = "idsurfs"
        case name = "nom_parking"
        case etat = "etat"
        case free = "libre"
        case total = "total"
        case description = "etat_descriptif"
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: Keys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.free = try container.decode(UInt.self, forKey: .free)
        self.total = try container.decode(UInt.self, forKey: .total)
        self.description = try container.decode(String.self, forKey: .description)

        let bool = try container.decode(UInt.self, forKey: .etat)
        self.etat = bool > 1
    }
}
