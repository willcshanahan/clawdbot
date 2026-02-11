import Foundation

enum NetworkConfiguration {
    /// Default timeout for individual network requests (30 seconds)
    static let defaultTimeout: TimeInterval = 30.0

    /// Timeout for entire resource download (60 seconds)
    static let resourceTimeout: TimeInterval = 60.0

    /// Shared URLSession with optimized configuration
    static var urlSession: URLSession = {
        let config = URLSessionConfiguration.default

        // Timeouts
        config.timeoutIntervalForRequest = defaultTimeout
        config.timeoutIntervalForResource = resourceTimeout

        // Network behavior
        config.waitsForConnectivity = true
        config.requestCachePolicy = .returnCacheDataElseLoad

        // Allow cellular data
        config.allowsCellularAccess = true

        // HTTP settings
        config.httpMaximumConnectionsPerHost = 4
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always

        return URLSession(configuration: config)
    }()

    /// Ephemeral session for requests that should not be cached
    static var ephemeralSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = defaultTimeout
        config.timeoutIntervalForResource = resourceTimeout
        config.waitsForConnectivity = true

        return URLSession(configuration: config)
    }()
}
