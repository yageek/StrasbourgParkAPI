//
//  APIClient.swift
//  ParkAPI
//
//  Created by Yannick Heinrich on 03.04.19.
//  Copyright © 2019 Yageek. All rights reserved.
//

import Foundation

/// The returned error type
public enum ParkingAPIClientError: Error {
    /// An error due  tp the network
    case network(Error)
    /// An error due to decoding error
    case decodable(Error)
}

/// An http client to query
/// data from the server
public final class ParkingAPIClient: NSObject, URLSessionDelegate {

    private var session: URLSession!
    private let workingQueue: OperationQueue

    /// Default initializer
    /// - Parameter configuration: The `URLSessionConfiguration` to use
    public init(configuration: URLSessionConfiguration = .default) {

        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.name = "net.yageek.strasbourgpark.apiclient"
        self.workingQueue = queue

        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // MARK: URLSessionTaskDelegate
    ///:nodoc:
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // This i
        #if DEBUG
        guard let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.rejectProtectionSpace, nil)
            return
        }
        let credential = URLCredential(trust: trust)
        completionHandler(.useCredential, credential)
        #else
        completionHandler(.performDefaultHandling, challenge.proposedCredential)
        #endif
    }

    // MARK: - Legacy APIs

    /// Retrieve the parkings' locations with the legacy endpoints
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
    @discardableResult public func getLegacyLocation(completion: @escaping(Result<LocationResponse, ParkingAPIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadOperation(session: self.session, endpoint: .legacyLocation, completion: completion)
        workingQueue.addOperation(op)
        return op
    }

    /// Retreive the parkings' with the legacy API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
   @discardableResult public func getLegacyStatus(completion: @escaping(Result<StatusResponse, ParkingAPIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadOperation(session: self.session, endpoint: .legacyLocation, completion: completion)
        workingQueue.addOperation(op)
        return op
    }

    // MARK: - Open Data APIS
    /// Retrieve the parkings' locations
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
    @discardableResult public func getLocations(completion: @escaping(Result<[LocationOpenData], Error>) -> Void) -> CancelableRequest {
        let op = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: 10, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }

    // MARK: - Open Data APIS
    /// Retreive the parkings' with the legacy API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
    @discardableResult public func getStatus(completion: @escaping(Result<[StatusOpenData], Error>) -> Void) -> CancelableRequest {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: 10, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }
}
