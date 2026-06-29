import Foundation

protocol ProfileViewPresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    var favoritePhotos: [Photo] { get }
    func viewDidLoad()
    func logout()
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void)
}

final class ProfileViewPresenter: ProfileViewPresenterProtocol {
    
    weak var view: ProfileViewControllerProtocol?
    
    private let profileService: ProfileService
    private let profileImageService: ProfileImageService
    private let imagesListService: ImagesListService
    private let logoutService: ProfileLogoutService
    
    private var profileImageObserver: NSObjectProtocol?
    private var likeObserver: NSObjectProtocol?
    
    init(
        profileService: ProfileService = .shared,
        profileImageService: ProfileImageService = .shared,
        imagesListService: ImagesListService = .shared,
        logoutService: ProfileLogoutService = .shared
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.imagesListService = imagesListService
        self.logoutService = logoutService
    }
    
    deinit {
        if let profileImageObserver { NotificationCenter.default.removeObserver(profileImageObserver) }
        if let likeObserver { NotificationCenter.default.removeObserver(likeObserver) }
    }
    
    var favoritePhotos: [Photo] {
        imagesListService.photos.filter { $0.isLiked }
    }
    
    func viewDidLoad() {
        profileImageObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
        
        likeObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeLikeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFavorites()
        }
        
        if let profile = profileService.profile {
            updateProfileDetails(with: profile)
        }
        updateAvatar()
        updateFavorites()
    }
    
    func logout() {
        logoutService.logout()
    }
    
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        imagesListService.changeLike(photoId: photoId, isLike: isLike, completion: completion)
    }
    
    // MARK: - Private
    
    private func updateProfileDetails(with profile: Profile) {
        let name = profile.name.isEmpty ? "Имя не указано" : profile.name
        let bio = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : (profile.bio ?? "")
        view?.updateProfileDetails(name: name, login: profile.loginName, bio: bio)
    }
    
    private func updateAvatar() {
        guard
            let avatarURL = profileImageService.avatarURL,
            let url = URL(string: avatarURL)
        else {
            view?.updateAvatar(url: nil)
            return
        }
        view?.updateAvatar(url: url)
    }
    
    private func updateFavorites() {
        let photos = favoritePhotos
        view?.updateFavorites(count: photos.count, isEmpty: photos.isEmpty)
    }
}
