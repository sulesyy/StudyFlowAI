import Foundation

enum AppConfiguration {
    // Xcode Simulator connects to the Mac through IPv4 loopback.
    // A physical iPhone needs a reachable HTTPS backend URL instead.
    static let aiProxyURL: String = {
        if let configuredURL = Bundle.main.object(forInfoDictionaryKey: "AIProxyURL") as? String,
           !configuredURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configuredURL
        }
        return "http://127.0.0.1:3000/generate"
    }()
}
