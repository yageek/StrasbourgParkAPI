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
    /// An error due  to the network network layer
    case network(Error)
    /// An error occured while decoding the server response
    case decodable(Error)
    /// An unknown error type
    case generic(Error)
}

/// An http client to query
/// data from the server
@objc(SPParkingAPIClient)
public final class ParkingAPIClient: NSObject, URLSessionDelegate {

    private var session: URLSession!
    private let workingQueue: OperationQueue
    private let pageSize: UInt

    // MARK: - Initialization

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

    // MARK: - Callback closures APIs(OBJC)    
    // MARK: - Callback closures APIs
    /// Retrieve the parkings' locations with the legacy API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
    @discardableResult public func getLegacyLocation(completion: @escaping(Result<LocationResponse, ParkingAPIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadOperation(session: self.session, endpoint: .legacyLocation, completion: completion)
        workingQueue.addOperation(op)
        return op
    }

    /// Retrieve the parkings' statuses with the legacy API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
   @discardableResult public func getLegacyStatus(completion: @escaping(Result<StatusResponse, ParkingAPIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadOperation(session: self.session, endpoint: .legacyLocation, completion: completion)
        workingQueue.addOperation(op)
        return op
    }

    /// Retrieve the parkings' locations with the open data API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
    @discardableResult public func getLocations(completion: @escaping(Result<[LocationOpenData], ParkingAPIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: self.pageSize, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }

    /// Retrieve the parkings' status with the open data API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A `CancelableRequest` compatible element
    @discardableResult public func getStatus(completion: @escaping(Result<[StatusOpenData], ParkingAPIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: self.pageSize, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }
}

// MARK: - Combine APIs
#if canImport(Combine)
    import Combine
#endif

@available(iOS 13.0, macOS 10.15, *)
extension Publishers {

    private final class ParkingClientSubscription<S: Subscriber, Op: CompletableOperation>: Subscription where Op.Success == S.Input, Op.Failure == S.Failure {

        private let subscriber: S
        private var operation: Op
        private let queue: OperationQueue

        init(subscriber: S, operation: Op, queue: OperationQueue) {
            self.subscriber = subscriber
            self.operation = operation
            self.queue = queue
        }

        func request(_ demand: Subscribers.Demand) {
            guard !self.operation.isFinished else {
                self.subscriber.receive(completion: .finished)
                return
            }

            guard !self.operation.isCancelled else {
                self.subscriber.receive(completion: .finished)
                return
            }

            operation.completionHandler = { result in
                switch result {
                case .success(let ok):
                    _ = self.subscriber.receive(ok)
                    self.subscriber.receive(completion: .finished)
                case .failure(let failure):
                    self.subscriber.receive(completion: .failure(failure))
                }
            }

            self.queue.addOperation(operation)

        }

        func cancel() {
            self.operation.cancel()
        }
    }

    struct ParkingPublisher<Op: CompletableOperation>: Publisher {
        typealias Output = Op.Success
        typealias Failure = Op.Failure

        private let queue: OperationQueue
        private let operation: Op

        init(operation: Op, queue: OperationQueue) {
            self.queue = queue
            self.operation = operation
        }

        func receive<S>(subscriber: S) where S : Subscriber, Op.Failure == S.Failure, Op.Success == S.Input {
            let subscription = ParkingClientSubscription(subscriber: subscriber, operation: self.operation, queue: self.queue)
            subscriber.receive(subscription: subscription)
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension ParkingAPIClient {
    
    /// Retrieve the parkings' locations with the legacy API
    /// - Returns: A ``AnyPublisher`` answering one ``LocationResponse`` element.
    public func getLegacyLocationPublisher() -> AnyPublisher<LocationResponse, ParkingAPIClientError> {
        let op = DownloadOperation<LocationResponse>(session: self.session, endpoint: .legacyLocation)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }

    /// Retrieve the parkings' statuses with the legacy API
    /// - Returns: A ``AnyPublisher`` answering one ``StatusResponse`` element.
    public func getLegacyStatusPublisher() -> AnyPublisher<StatusResponse, ParkingAPIClientError> {
        let op = DownloadOperation<StatusResponse>(session: self.session, endpoint: .legacyLocation)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }

    /// Retrieve the parkings' locations using the open data API
    /// - Returns: A ``AnyPublisher`` answering one ``[LocationOpenData]`` .
    public func getLocationsPublisher() -> AnyPublisher<[LocationOpenData], ParkingAPIClientError> {
        let op = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: self.pageSize)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }

    /// Retrieve the parkings' statuses with the opendata API
    /// - Returns: A ``AnyPublisher`` answering one ``[StatusOpenData]`` element.
    public func getStatusPublisher() -> AnyPublisher<[StatusOpenData], ParkingAPIClientError> {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: self.pageSize)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }
}

// MARK: - Async APIs
@available(iOS 15.0.0, macOS 12.0.0, *)
/// A compatible async context that managed
/// internally the sendable protocol
struct OperationContext: @unchecked Sendable {

    private var lock = NSLock()
    private var _operation: Operation?

    var operation: Operation? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _operation
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _operation = newValue
        }
    }
}


@available(macOS 12.0.0, iOS 15.0, *)
extension ParkingAPIClient {

    func executeOperation<O: CompletableOperation>(_ operation: O) async throws -> O.Success {
        var ctx = OperationContext()
        return try await withTaskCancellationHandler {
            let result: O.Success = try await withCheckedThrowingContinuation { continuation in

                operation.completionHandler = { result in
                    continuation.resume(with: result)
                }
                self.workingQueue.addOperation(operation)
                ctx.operation = operation
            }
            return result
        } onCancel: { [ctx] in
            ctx.operation?.cancel()
        }
    }

    /// Retrieve the parkings' location with the legacy API
    /// - Returns: An array of ``LocationResponse``
    public func fetchLegacyLocation() async throws -> LocationResponse {
        let dlOp = DownloadOperation<LocationResponse>(session: self.session, endpoint: .legacyLocation)
        return try await self.executeOperation(dlOp)
    }
    /// Retrieve the parkings' statuses with the legacy API
    /// - Returns: An array of ``StatusResponse``
    public func fetchLegacyStatus() async throws -> StatusResponse {
        let op = DownloadOperation<StatusResponse>(session: self.session, endpoint: .legacyLocation)
        return try await self.executeOperation(op)
    }

    /// Retrieve the parkings' location with the open data API
    /// - Returns: An array of ``LocationOpenData``
    public func fetchLocations() async throws -> [LocationOpenData] {
        let dlOp = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: self.pageSize)
        return try await self.executeOperation(dlOp)
    }

    /// Retrieve the parkings' statuses with the open data API
    /// - Returns: An array of ``StatusResponse``
    public func fetchStatus() async throws -> [StatusOpenData] {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: self.pageSize)
        return try await self.executeOperation(op)
    }
}
