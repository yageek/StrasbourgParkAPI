//
//  File.swift
//  
//
//  Created by eidd5180 on 01/07/2020.
//

import Foundation

final class DownloadOperation<T: Decodable>: BaseOperation, CompletableOperation {
    private let url: URL
    private let lock = NSLock()
    private var _completion: ((Result<T, ParkingAPIClientError>) -> Void)?
    var completionHandler: ((Result<T, ParkingAPIClientError>) -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _completion
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _completion = newValue
        }
    }
    private let session: URLSession

    private var currentTask: URLSessionTask?

    func finish(result: Result<T, ParkingAPIClientError>) {
        self.completionHandler?(result)
        self.finish()
    }

    // MARK: - Implementation
    init(session: URLSession, url: URL, completion: ((Result<T, ParkingAPIClientError>) -> Void)? = nil) {
        self.url = url
        self._completion = completion
        self.session = session

        super.init()
        name = "ch.yageek.strasbourg.park.downloadoperation.\(T.self)"
    }

    convenience init(session: URLSession, endpoint: Endpoint, completion: ((Result<T, ParkingAPIClientError>) -> Void)? = nil) {
        self.init(session: session, url: URL(string: endpoint.rawValue)!, completion: completion)
    }

    override var isAsynchronous: Bool {
        return true
    }

    override func start() {
        isExecuting = true

        guard !isCancelled else { finish(); return }
        logger.debug("Starting request to \(url.absoluteString)")

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
            logger.error("Error on the network: \(error)")
            self.finish(result: .failure(.network(error)))
        } else if let data = data {

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                logger.info("Successfully decoded value")
                self.finish(result: .success(decoded))

            } catch let error {
                logger.error("Error during decoding response: \(error)")
                self.finish(result: .failure(.decodable(error)))
            }
        }
    }
}
