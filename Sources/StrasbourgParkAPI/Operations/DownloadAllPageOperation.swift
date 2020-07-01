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
                logger.error("Error during the download: \(error.localizedDescription)")
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
    private func otherCompletion(result: Result<OpenDataResponse<T>, ParkingAPIClientError>) {

        lock.lock()
        defer {
            lock.unlock()
        }

        do {
            let resp = try result.get()
            let elements = resp.records.map { $0.inner }
            self.records.append(contentsOf: elements)

        } catch let error {
            logger.error("Error downloading data: \(error.localizedDescription)")
            self.errors.append(error)
            workingQueue.cancelAllOperations()
        }
    }
}
