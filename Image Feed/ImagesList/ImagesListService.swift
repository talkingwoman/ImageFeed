import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    private init() {}

    private(set) var photos: [Photo] = Array(0..<20).map {
        Photo(id: "\($0)", name: "\($0)", date: Date(), isLiked: $0 % 2 == 0)
    }

    static let didChangeLikeNotification = Notification.Name("ImagesListServiceDidChangeLike")

    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            let success = true
            DispatchQueue.main.async {
                if success, let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    self.photos[index].isLiked = isLike
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeLikeNotification,
                        object: self,
                        userInfo: ["photoId": photoId]
                    )
                }
                completion(success)
            }
        }
    }
}
