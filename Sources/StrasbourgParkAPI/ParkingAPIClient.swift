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
}

// MARK: - Combine
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
    
    /// Retrieve the parkings' locations with the legacy endpoints
    /// - Returns: A ``AnyPublisher`` instance providing legacy ``LocationResponse`` element.
    public func getLegacyLocationPublisher() -> AnyPublisher<LocationResponse, ParkingAPIClientError> {
        let op = DownloadOperation<LocationResponse>(session: self.session, endpoint: .legacyLocation)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }

    /// Retreive the parkings' statuses with the legacy API
    /// - Returns: A ``AnyPublisher`` instance providing legacy ``StatusResponse`` element.
    public func getLegacyStatusPublisher() -> AnyPublisher<StatusResponse, ParkingAPIClientError> {
        let op = DownloadOperation<StatusResponse>(session: self.session, endpoint: .legacyLocation)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }

    // MARK: - Open Data APIS
    /// Retrieve the parkings' locations
    /// - Parameter completion: The result when the request completed
    /// - Returns: A ``AnyPublisher`` instance providing legacy ``[LocationOpenData]`` element.
    public func getLocationsPublisher() -> AnyPublisher<[LocationOpenData], Error> {
        let op = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: self.pageSize)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }

    // MARK: - Open Data APIS
    /// Retreive the parkings' with the legacy API
    /// - Parameter completion: The result when the request completed
    /// - Returns: A ``AnyPublisher`` instance providing legacy ``[StatusOpenData]`` element.
    public func getStatusPublisher() -> AnyPublisher<[StatusOpenData], Error> {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: self.pageSize)
        return Publishers.ParkingPublisher(operation: op, queue: self.workingQueue).eraseToAnyPublisher()
    }
}

// MARK: - Async
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


    /// Retrieve the legacy locations
    public func fetchLegacyLocation() async throws -> LocationResponse {
        let dlOp = DownloadOperation<LocationResponse>(session: self.session, endpoint: .legacyLocation)
        return try await self.executeOperation(dlOp)
    }

    public func fetchLegacyStatus() async throws -> StatusResponse {
        let op = DownloadOperation<StatusResponse>(session: self.session, endpoint: .legacyLocation)
        return try await self.executeOperation(op)
    }

    // MARK: - Open Data APIS
    public func fetchStatus() async throws -> [StatusOpenData] {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: self.pageSize)
        return try await self.executeOperation(op)
    }

    /// Retrieve all the locations of parkings
    /// - Returns: An array of `StrasbourgParkAPI.LocationOpenData`
    public func fetchLocations() async throws -> [StrasbourgParkAPI.LocationOpenData] {
        let dlOp = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: self.pageSize)
        return try await self.executeOperation(dlOp)
    }
}
