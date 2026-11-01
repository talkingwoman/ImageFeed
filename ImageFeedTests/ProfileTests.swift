@testable import Image_Feed
import XCTest

@MainActor
final class ProfileTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() {
        //given
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.configure(presenter)
        
        //when
        _ = viewController.view
        
        //then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testPresenterUpdatesViewOnViewDidLoad() {
        //given
        let presenter = ProfileViewPresenter()
        let view = ProfileViewControllerSpy()
        presenter.view = view
        
        //when
        presenter.viewDidLoad()
        
        //then
        XCTAssertTrue(view.updateAvatarCalled)
        XCTAssertTrue(view.updateFavoritesCalled)
    }
}
