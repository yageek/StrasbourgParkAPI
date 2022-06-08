//
//  ParkAPIOpenData.swift
//  ParkAPI
//
//  Created by Yannick Heinrich on 03.04.19.
//  Copyright © 2019 Yageek. All rights reserved.
//

import Foundation
import CoreLocation

@propertyWrapper struct FailableDecodable<T: Decodable>: Decodable {
    let wrappedValue: T?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try? container.decode(T.self)
    }
}

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

    let total: Int
    let timeZone: TimeZone
    let count: Int
    let start: Int
    let records: [Record<T>]

    private struct Parameters: Decodable {
        let timeZone: TimeZone
        let start: Int
        let count: Int

        private enum DecodingError: Error {
            case invalidTimeZoneID(String)
        }

        private enum Keys: String, CodingKey {
            case timeZone = "timezone"
            case count = "rows"
            case start = "start"
        }
        ///:nodoc:
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)

            self.count = try container.decode(Int.self, forKey: .count)
            self.start = try container.decodeIfPresent(Int.self, forKey: .start) ?? 0

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
        self.total = try container.decode(Int.self, forKey: .total)

        // Inner parameters
        let parameters = try container.decode(Parameters.self, forKey: .parameters)
        self.count = parameters.count
        self.start = parameters.start
        self.timeZone = parameters.timeZone
        let records = try container.decode([FailableDecodable<Record<T>>].self, forKey: .records)
        self.records = records.compactMap { $0.wrappedValue }
    }
}

/// The location of the parking
public struct LocationOpenData: Decodable {

    /// The reference of the parking on the API
    public let id: String
    /// The city where the parking is located
    public let city: String
    /// The zip code of the city where the parking is located
    public let zipCode: String
    /// The street part of the address of the parking
    public let street: String
    /// The complete address of the parking location
    public let address: String
    
    /// The location of the parking on a map
    public let location: CLLocation

    /// The URL of the web page provided by the Strasbourg server
    public let url: URL
    
    /// The name of the parking:
    public let name: String
    
    /// The description of the parking
    public let description: String?
    /// Whether or not the location has improved accessibility for non hearing people
    public let deafAccess: Bool
    
    /// Whether or not the location has improved accessibility for people suffering from deficiency
    public let deficientAccess: Bool
    
    /// Whether or not the location has improved accessibility for elder people
    public let elderAccess: Bool
    
    /// Whether or not the location has improved accessibility for people using a wheel chair
    public let wheelChairAccess: Bool
    
    /// Whether or not the location has improved accessibility for non seeing people
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
    ///:nodoc:
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


/// An either enum to handle to possibility of deserialisation
public enum Either<L, R>: Decodable where L: Decodable, R: Decodable {
    ///:nodoc:
    case left(L)
    ///:nodoc:
    case right(R)

    ///:nodoc:
    public init(from decoder: Decoder) throws {

        let container = try decoder.singleValueContainer()
        if let left = try? container.decode(L.self) {
            self = .left(left)
        } else if let right = try? container.decode(R.self) {
            self = .right(right)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode \(L.self) or \(R.self)")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

/// The status of the parking
public struct StatusOpenData: Decodable {

    /// The reference of the resource on the server
    public let id: String
    /// The name of the parking
    public let name: String
    /// The state of the parking
    public let etat: Int
    /// The total of available free slots
    public let free: UInt
    /// The total capacity of the parking
    public let total: UInt
    /// Some description on the parking
    public let description: String
    /// Some information available to the users
    public let usersInfo: Either<String, Int>?

    private enum Keys: String, CodingKey {
        case id = "idsurfs"
        case name = "nom_parking"
        case etat = "etat"
        case free = "libre"
        case total = "total"
        case description = "etat_descriptif"
        case usersInfo = "infousager"
    }

    ///:nodoc:
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: Keys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.free = try container.decode(UInt.self, forKey: .free)
        self.total = try container.decode(UInt.self, forKey: .total)
        self.description = try container.decode(String.self, forKey: .description)
        self.etat = try container.decode(Int.self, forKey: .etat)
        self.usersInfo = try container.decodeIfPresent(Either<String, Int>.self, forKey: .usersInfo)
    }
}
