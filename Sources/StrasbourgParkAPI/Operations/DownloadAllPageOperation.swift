//
//  File.swift
//  
//
//  Created by Yannick Heinrich on 01.07.20.
//

import Foundation

private struct APIPagedCall {
    let endpoint: Endpoint
    var start: UInt
    var count: UInt

    fileprivate var apiURL: URL {
        return URL(string: "\(endpoint.rawValue)&start=\(start)&rows=\(count)")!
    }
}

final class DownloadAllPages<T: Decodable>: BaseOperation {

    private let workingQueue: OperationQueue
    private let endpoint: Endpoint
    private let session: URLSession
    private let pageSize: UInt
    private let completionHandler: (Result<[T], Error>) -> Void
    private var records: [Int: [T]]
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

        self.records = [:]
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
            guard let self = self else { return }

            guard !self.isCancelled else { self.finish(); return }
            // Read the value
            do {
                let resp = try result.get()
                let firstPage = resp.records.map { $0.inner }
                self.records[0] = firstPage

                // Compute pages to download
                let rest = resp.total - resp.count
                guard rest > 0 else {
                    self.completionHandler(.success(firstPage))
                    self.finish()
                    return
                }

                let r = UInt(rest) % self.pageSize
                let pagesToDownload =  UInt(rest) / self.pageSize + min(1, r)

                var indexes = (1..<pagesToDownload).map { (self.pageSize*$0, self.pageSize) }
                indexes.append((self.pageSize*pagesToDownload, UInt(rest) % self.pageSize))

                // Operations
                let calls = indexes.map { APIPagedCall(endpoint: self.endpoint, start: $0.0, count: $0.1) }

                var ops: [Operation] = []
                for (i, op) in calls.enumerated() {

                    // i + 1 because the first page is already set
                    let op = DownloadOperation<OpenDataResponse<T>>(session: self.session, url: op.apiURL) { [unowned self] result in
                        self.otherCompletion(pageNumber: i + 1, result: result)
                    }
                    ops.append(op)
                }

                // Let final operations
                let blockOp = BlockOperation {
                    if self.errors.isEmpty {
                        let result: [T] = self.records.sorted(by: { $0.0 > $1.0 }).reduce(into: [T](), { $0.append(contentsOf: $1.value) })
                        self.completionHandler(.success(result))
                    } else {
                        self.completionHandler(.failure(self.errors[0]))
                    }
                }

                for op in ops {
                    blockOp.addDependency(op)
                }

                self.workingQueue.addOperation(blockOp)
                self.workingQueue.addOperations(ops, waitUntilFinished: false)

            } catch let error {
                logger.error("Error during the download: \(error)")
                self.completionHandler(.failure(error))
                self.finish()
            }
        }

        workingQueue.addOperation(op)
    }

    override func cancel() {
        workingQueue.cancelAllOperations()
        self.finish()
    }

    // MARK: - Completions
    private func otherCompletion(pageNumber: Int, result: Result<OpenDataResponse<T>, ParkingAPIClientError>) {

        lock.lock()
        defer {
            lock.unlock()
        }

        do {
            let resp = try result.get()
            let elements = resp.records.map { $0.inner }
            self.records[pageNumber] = elements

        } catch let error {
            logger.error("Error downloading data: \(error)")
            self.errors.append(error)
            workingQueue.cancelAllOperations()
        }
    }
}
