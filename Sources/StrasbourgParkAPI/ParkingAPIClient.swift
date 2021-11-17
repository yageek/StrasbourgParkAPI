//
//  APIClient.swift
//  ParkAPI
//
//  Created by Yannick Heinrich on 03.04.19.
//  Copyright © 2019 Yageek. All rights reserved.
//

import Foundation

#if canImport(Combine)
    import Combine
#endif

/// The returned error type
public enum ParkingAPIClientError: Error {
    /// An error due  tp the network
    case network(Error)
    /// An error due to decoding error
    case decodable(Error)
}


@available(iOS 15.0.0, *)
actor OperationContext {
    private(set) var operation: Operation?
    func attach(_ operation: Operation?) {
        self.operation = operation
    }
}

/// An http client to query
/// data from the server
public final class ParkingAPIClient: NSObject, URLSessionDelegate {

    private var session: URLSession!
    private let workingQueue: OperationQueue
    private let pageSize: UInt

    /// Default initializer
    /// - Parameter configuration: The `URLSessionConfiguration` to use. Default to `URLSession.default`
    /// - Parameter pageSize: The pagination value to use. Default to `10`.
    public init(configuration: URLSessionConfiguration = .default, pageSize: UInt = 10) {

        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.name = "net.yageek.strasbourgpark.apiclient"
        self.workingQueue = queue
        self.pageSize = pageSize

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

    @available(iOS 13.0, *)
    /// Retrieve the parkings' locations with the legacy endpoints
    /// - Returns: One ``AnyPublisher`` returning the response
    public func getLegacyLocationPublisher() -> AnyPublisher<LocationResponse, ParkingAPIClientError> {
        let op = DownloadOperation<LocationResponse>(session: self.session, endpoint: .legacyLocation)

        return Deferred {
            return Future { obs in
                op.completion = { result in
                    obs(result)
                }
            }
        }.handleEvents(receiveCancel: {
            op.cancel()
        }).eraseToAnyPublisher()
    }

    @available(iOS 15.0.0, *)
    func fetchLegacyLocation() async throws -> LocationResponse {
        // See: SE-0300 https://github.com/apple/swift-evolution/blob/main/proposals/0300-continuation.md
        let ctx = OperationContext()

        return try await withTaskCancellationHandler {
            let response: LocationResponse = try await withUnsafeThrowingContinuation { continuation in
                let dlOp = DownloadOperation<LocationResponse>(session: self.session, endpoint: .legacyLocation, completion: { result in
                    switch result {
                    case .success(let success):
                        continuation.resume(returning: success)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })

                Task {
                    await ctx.attach(dlOp)
                }
            }
            
            return response
        } onCancel: {
            Task {
                await ctx.operation?.cancel()
            }
        }
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
        let op = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: self.pageSize, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }

    // MARK: - Open Data APIS
    /// Retreive the parkings' with the legacy API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
    @discardableResult public func getStatus(completion: @escaping(Result<[StatusOpenData], Error>) -> Void) -> CancelableRequest {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: self.pageSize, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }
    
    @available(macOS 12.5, iOS 15.0, *)
    func fetchLocations() async throws -> [StrasbourgParkAPI.LocationOpenData] {
        let ctx = OperationContext()
        return try await withTaskCancellationHandler {
            Task {
                await ctx.operation?.cancel()
            }

        } operation: {
            let result: [StrasbourgParkAPI.LocationOpenData] = try await withCheckedThrowingContinuation { continuation in

                let dlOp = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: self.pageSize) { result in
                    continuation.resume(with: result)
                }
                Task {
                    await ctx.attach(dlOp)
                }

                workingQueue.addOperation(dlOp)
            }

            return result
        }
    }
}
