import Foundation

  struct Photo {
      let id: String
      let size: CGSize
      let createdAt: Date?
      let welcomeDescription: String?
      let thumbImageURL: String
      let largeImageURL: String
      let isLiked: Bool
  }

  // MARK: - Декодинг ответа GET /photos

  struct PhotoResult: Decodable {
      let id: String
      let width: Int
      let height: Int
      let createdAt: String?
      let description: String?
      let likedByUser: Bool
      let urls: UrlsResult

      enum CodingKeys: String, CodingKey {
          case id, width, height, description, urls
          case createdAt = "created_at"
          case likedByUser = "liked_by_user"
      }
  }

  struct UrlsResult: Decodable {
      let thumb: String
      let full: String
      let regular: String
  }
