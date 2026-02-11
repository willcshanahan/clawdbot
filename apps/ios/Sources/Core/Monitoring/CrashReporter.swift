import Sentry

enum CrashReporter {
    static func initialize() {
        SentrySDK.start { options in
            // TODO: Move DSN to secure configuration
            // For now, initialize without DSN (will not send events until configured)
            // options.dsn = Configuration.sentryDSN

            #if DEBUG
            options.tracesSampleRate = 1.0
            options.debug = true
            #else
            options.tracesSampleRate = 0.1
            #endif

            options.enableAutoPerformanceTracing = true
            options.enableNetworkTracking = true
            options.enableFileIOTracing = true
            options.attachScreenshot = true
            options.attachViewHierarchy = true

            // Don't send PII
            options.beforeSend = { event in
                // Scrub sensitive data
                event.user = nil
                return event
            }
        }
    }

    static func captureError(_ error: Error, context: [String: Any]? = nil) {
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: context, key: "custom")
            }
        }
    }

    static func setUser(id: String) {
        let user = Sentry.User(userId: id)
        SentrySDK.setUser(user)
    }
}
