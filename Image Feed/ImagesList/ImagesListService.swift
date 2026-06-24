import Foundation
import CoreGraphics

final class ImagesListService {
    static let shared = ImagesListService()
    private init() {}
    
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    static let didChangeLikeNotification =
    Notification.Name("ImagesListServiceDidChangeLike")
    
    private(set) var photos: [Photo] = []
    
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    private let dateFormatter = ISO8601DateFormatter()
    
    // MARK: - Постраничная загрузка
    
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        guard task == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        guard let request = makePhotosRequest(page: nextPage) else { return }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            defer { self.task = nil }
            
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { self.makePhoto(from: $0) }
                
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self
                )
            case .failure(let error):
                print("[fetchPhotosNextPage]: \(error.localizedDescription)")
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Helpers
    
    private func makePhoto(from result: PhotoResult) -> Photo {
        Photo(
            id: result.id,
            size: CGSize(width: result.width, height: result.height),
            createdAt: result.createdAt.flatMap { dateFormatter.date(from: $0) },
            welcomeDescription: result.description,
            thumbImageURL: result.urls.regular,
            largeImageURL: result.urls.full,
            isLiked: result.likedByUser
        )
    }
    
    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard let token = tokenStorage.token,
              var components = URLComponents(string:
                                                "\(Constants.defaultBaseURLString)/photos")
        else { return nil }
        
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    // MARK: - Лайки
    
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void,
                                                                          Error>) -> Void) {
        guard let token = tokenStorage.token,
              let url = URL(string:
                                "\(Constants.defaultBaseURLString)/photos/\(photoId)/like")
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = urlSession.data(for: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    let photo = self.photos[index]
                    let newPhoto = Photo(
                        id: photo.id,
                        size: photo.size,
                        createdAt: photo.createdAt,
                        welcomeDescription: photo.welcomeDescription,
                        thumbImageURL: photo.thumbImageURL,
                        largeImageURL: photo.largeImageURL,
                        isLiked: !photo.isLiked
                    )
                    self.photos[index] = newPhoto
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
