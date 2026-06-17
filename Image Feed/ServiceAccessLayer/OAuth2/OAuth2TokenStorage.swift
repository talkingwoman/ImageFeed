import Foundation

final class OAuth2TokenStorage {
    private let storage = UserDefaults.standard
    private let tokenKey = "OAuth2AccessToken"
    
    var token: String? {
        get {
            storage.string(forKey: tokenKey)
        }
        set {
            storage.set(newValue, forKey: tokenKey)
        }
    }
}
