import Foundation

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let tokenStorage = OAuth2TokenStorage.shared

    private var task: URLSessionTask?
    private var lastCode: String?

    private init() { }

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        // Если повторно пришёл тот же code и запрос ещё в полёте — не дублируем
        guard lastCode != code else {
            print("[fetchOAuthToken]: NetworkError - invalidRequest, повторный вызов с тем же code: \(code)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        // Пришёл новый code — отменяем предыдущий запрос
        task?.cancel()
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[fetchOAuthToken]: NetworkError - invalidRequest, code: \(code)")
            lastCode = nil
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self else { return }
            self.task = nil
            self.lastCode = nil

            switch result {
            case .success(let responseBody):
                let token = responseBody.accessToken
                self.tokenStorage.token = token
                completion(.success(token))
            case .failure(let error):
                print("[fetchOAuthToken]: NetworkError - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("[makeOAuthTokenRequest]: NetworkError - failed to create URLComponents")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = urlComponents.url else {
            print("[makeOAuthTokenRequest]: NetworkError - failed to create URL from components")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
