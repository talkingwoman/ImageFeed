import Foundation

struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
    
    private enum CodingKeys: String, CodingKey {
        case small
        case medium
        case large
    }
}

struct UserResult: Codable {
    let profileImage: ProfileImage
    
    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

final class ProfileImageService {
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    static let shared = ProfileImageService()
    private init() {}
    
    private(set) var avatarURL: String?
    private var task: URLSessionTask?
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
          task?.cancel()

          guard let token = OAuth2TokenStorage.shared.token else {
              completion(.failure(NetworkError.invalidRequest))
              return
          }
      
          guard let request = makeProfileImageRequest(username: username, token: token) else {
              completion(.failure(NetworkError.invalidRequest))
              return
          }

          let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
              guard let self else { return }
              defer { self.task = nil }

              switch result {
              case .success(let userResult):
                  let avatarURL = userResult.profileImage.large
                  self.avatarURL = avatarURL
                  completion(.success(avatarURL))
                  NotificationCenter.default.post(
                      name: ProfileImageService.didChangeNotification,
                      object: self,
                      userInfo: ["URL": avatarURL]
                  )
              case .failure(let error):
                  print("[fetchProfileImageURL]: NetworkError - \(error.localizedDescription)")
                  completion(.failure(error))
              }
          }
      
          self.task = task
          task.resume()
      }
    
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
