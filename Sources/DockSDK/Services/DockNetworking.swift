// DockSDK/Sources/Services/DockNetworking.swift
//
// Shared URLSession for dock network requests.

import Foundation

/// Shared networking service providing a host-configured URLSession.
///
/// Currently uses callback-based API only. No async/await wrapper yet.
@objc(DockNetworking)
public class DockNetworking: NSObject {

    private let session: URLSession

    @objc public override init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Superdock/1.0 DockSDK/1.0"
        ]
        self.session = URLSession(configuration: config)
        super.init()
    }

    /// Fetch data from a URL.
    ///
    /// - Parameters:
    ///   - url: The URL to fetch.
    ///   - completion: Called on the main thread with (data, error).
    @objc public func fetchData(from url: URL, completion: @escaping (Data?, Error?) -> Void) {
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }.resume()
    }

    /// Perform a URLRequest.
    ///
    /// - Parameters:
    ///   - request: The URLRequest to execute.
    ///   - completion: Called on the main thread with (data, response, error).
    @objc public func perform(
        _ request: URLRequest,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, response, error)
            }
        }.resume()
    }
}
