//
//  APIClient.swift
//  ParkAPI
//
//  Created by Yannick Heinrich on 03.04.19.
//  Copyright © 2019 Yageek. All rights reserved.
//

import Foundation
import os

private enum Endpoint: String {

    case legacyStatus = "http://carto.strasmap.eu/remote.amf.json/Parking.geometry"
    case legacyLocation = "http://carto.strasmap.eu/remote.amf.json/Parking.status"

    case location = "https://data.strasbourg.eu/api/records/1.0/search/?dataset=parkings"
    case status = "https://data.strasbourg.eu/api/records/1.0/search/?dataset=occupation-parkings-temps-reel"
}

private struct APIPagedCall {
    let endpoint: Endpoint
    var start: UInt
    var count: UInt

    fileprivate var apiURL: URL {
        return URL(string: "\(endpoint.rawValue)&start=\(start)&rows=\(count)")!
    }
}

open class BaseOperation: Operation {

    // MARK: - Helper Begin
    var _isFinished: Bool = false
    open override var isFinished: Bool {
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }

        get {
            return _isFinished
        }
    }

    var _isExecuting: Bool = false

    open override var isExecuting: Bool {
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }

        get {
            return _isExecuting
        }
    }

    open func finish() {
        isExecuting = false
        isFinished = true
    }
}

private final class DownloadOperation<T: Decodable>: BaseOperation {
    private let url: URL
    private let completion: (Result<T, APIClientError>) -> Void
    private let session: URLSession

    private var currentTask: URLSessionTask?

    func finish(result: Result<T, APIClientError>) {
        self.completion(result)
        self.finish()
    }

    // MARK: - Implementation

    init(session: URLSession, url: URL, completion: @escaping(Result<T, APIClientError>) -> Void) {
        self.url = url
        self.completion = completion
        self.session = session

        super.init()
        name = "ch.yageek.strasbourg.park.downloadoperation.\(T.self)"
    }

    convenience init(session: URLSession, endpoint: Endpoint, completion:  @escaping(Result<T, APIClientError>) -> Void) {
        self.init(session: session, url: URL(string: endpoint.rawValue)!, completion: completion)
    }

    override var isAsynchronous: Bool {
        return true
    }

    override func start() {
        isExecuting = true

        guard !isCancelled else { finish(); return }
        os_log(.debug, "Starting request to %s", url.absoluteString)

        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let sSelf = self else { return }

            guard !sSelf.isCancelled else { sSelf.finish(); return }
            self?.parseResponse(data: data, response: response as? HTTPURLResponse, error: error)
        }

        self.currentTask = task
        task.resume()
    }

    override func cancel() {
        self.currentTask?.cancel()
        self.finish()
    }

    // MARK: - Helpers
    private func parseResponse(data: Data?, response: HTTPURLResponse?, error: Error?) {

        if let error = error {
            os_log(.error, "Error on the network: %s", error.localizedDescription)
            self.finish(result: .failure(.network(error)))
        } else if let data = data {

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                os_log("Successfully decoded value")
                self.finish(result: .success(decoded))

            } catch let error {
                os_log(.error, "Error during decoding response: %s", error.localizedDescription)
                self.finish(result: .failure(.decodable(error)))
            }
        }
    }
}

public enum APIClientError: Error {
    case network(Error)
    case decodable(Error)
}

private final class DownloadAllPages<T: Decodable>: BaseOperation {

    private let workingQueue: OperationQueue
    private let endpoint: Endpoint
    private let session: URLSession
    private let pageSize: UInt
    private let completionHandler: (Result<[T], Error>) -> Void
    private var records: [T]
    private var errors: [Error]

    private var lock: NSLock

    init(session: URLSession, endpoint: Endpoint, pageSize: UInt, completionHandler:  @escaping (Result<[T], Error>) -> Void) {
        self.session = session
        self.endpoint = endpoint
        self.pageSize = pageSize

        self.lock = NSLock()
        self.completionHandler = completionHandler

        let queue = OperationQueue()
        queue.qualityOfService = .background
        self.workingQueue = queue

        self.records = []
        self.errors = []
        super.init()
        name = "net.yageek.strasbourgpark.apiclient.downloadallrecords.\(T.self)"
    }

    override var isAsynchronous: Bool { return true }

    override func start() {
        guard !isCancelled else { finish(); return }
        // First download the first page
        let call = APIPagedCall(endpoint: self.endpoint, start: 0, count: pageSize)

        let op = DownloadOperation<OpenDataResponse<T>>(session: self.session, url: call.apiURL) { [weak self] (result) in
            guard let sSelf = self else { return }

            guard !sSelf.isCancelled else { sSelf.finish(); return }
            // Read the value
            do {
                let resp = try result.get()
                sSelf.records.append(contentsOf: resp.records.map { $0.inner })

                // Compute pages to download
                let rest = resp.total - resp.count
                let pagesToDownload = rest / sSelf.pageSize + ((rest % sSelf.pageSize == 0) ? 0 : 1)
                var indexes = (1..<pagesToDownload).map { (sSelf.pageSize*$0, sSelf.pageSize) }
                indexes.append((sSelf.pageSize*pagesToDownload, rest % sSelf.pageSize))

                // Operations
                let calls = indexes.map { APIPagedCall(endpoint: sSelf.endpoint, start: $0.0, count: $0.1) }
                let ops = calls.map { DownloadOperation<OpenDataResponse<T>>(session: sSelf.session, url: $0.apiURL, completion: sSelf.otherCompletion)}

                // Let final operations
                let blockOp = BlockOperation {
                    if sSelf.errors.isEmpty {
                        sSelf.completionHandler(.success(sSelf.records))
                    } else {
                        sSelf.completionHandler(.failure(sSelf.errors[0]))
                    }
                }

                for op in ops {
                    blockOp.addDependency(op)
                }

                sSelf.workingQueue.addOperation(blockOp)
                sSelf.workingQueue.addOperations(ops, waitUntilFinished: false)

            } catch let error {
                os_log(.error, "Error during the download: %s", error.localizedDescription)
                self?.finish()
            }
        }

        workingQueue.addOperation(op)
    }

    override func cancel() {
        workingQueue.cancelAllOperations()
        self.finish()
    }

    // MARK: - Completions
    private func otherCompletion(result: Result<OpenDataResponse<T>, APIClientError>) {

        lock.lock()
        defer {
            lock.unlock()
        }

        do {
            let resp = try result.get()
            let elements = resp.records.map { $0.inner }
            self.records.append(contentsOf: elements)

        } catch let error {
            os_log(.error, "Error downloading data: %s", error.localizedDescription)
            self.errors.append(error)
            workingQueue.cancelAllOperations()
        }
    }
}

public protocol CancelableRequest {
    func cancel()
}

extension Operation: CancelableRequest { }

/// An APIClient to query
/// data from the server
public final class APIClient: NSObject, URLSessionDelegate {

    private var session: URLSession!
    private let workingQueue: OperationQueue

    public init(configuration: URLSessionConfiguration = .default) {

        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.name = "net.yageek.strasbourgpark.apiclient"
        self.workingQueue = queue

        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // MARK: URLSessionTaskDelegate
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
    @discardableResult public func getLegacyLocation(completion: @escaping(Result<LocationResponse, APIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadOperation(session: self.session, endpoint: .legacyLocation, completion: completion)
        workingQueue.addOperation(op)
        return op
    }

   @discardableResult public func getLegacyStatus(completion: @escaping(Result<StatusResponse, APIClientError>) -> Void) -> CancelableRequest {
        let op = DownloadOperation(session: self.session, endpoint: .legacyLocation, completion: completion)
        workingQueue.addOperation(op)
        return op
    }

    // MARK: - Open Data APIS
    @discardableResult public func getLocations(completion: @escaping(Result<[LocationOpenData], Error>) -> Void) -> CancelableRequest {
        let op = DownloadAllPages<LocationOpenData>(session: self.session, endpoint: .location, pageSize: 10, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }

    // MARK: - Open Data APIS
    @discardableResult public func getStatus(completion: @escaping(Result<[StatusOpenData], Error>) -> Void) -> CancelableRequest {
        let op = DownloadAllPages<StatusOpenData>(session: self.session, endpoint: .status, pageSize: 10, completionHandler: completion)
        workingQueue.addOperation(op)
        return op
    }
}
