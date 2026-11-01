@testable import Image_Feed
import Foundation

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfileViewPresenterProtocol?
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false
    var updateFavoritesCalled = false
    
    func updateProfileDetails(name: String, login: String, bio: String) {
        updateProfileDetailsCalled = true
    }
    
    func updateAvatar(url: URL?) {
        updateAvatarCalled = true
    }
    
    func updateFavorites(count: Int, isEmpty: Bool) {
        updateFavoritesCalled = true
    }
}
