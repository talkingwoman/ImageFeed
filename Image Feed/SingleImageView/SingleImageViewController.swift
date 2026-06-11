import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: - Properties
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            setImage(image)
        }
    }
    var photoId: String?
    
    private let service = ImagesListService.shared
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!
    
    let likeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "like_button_off"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        setupLikeButton()
        updateLikeButton()
        
        guard let image else { return }
        setImage(image)
    }
    
    // MARK: - Private Methods
    
    private func updateLikeButton() {
        guard let photoId,
              let photo = service.photos.first(where: { $0.id == photoId })
        else { return }
        let img = photo.isLiked
        ? UIImage(named: "like_button_on")
        : UIImage(named: "like_button_off")
        likeButton.setImage(img, for: .normal)
    }
    
    private func setupLikeButton() {
        view.addSubview(likeButton)
        NSLayoutConstraint.activate([
            likeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 78),
            likeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            likeButton.widthAnchor.constraint(equalToConstant: 51),
            likeButton.heightAnchor.constraint(equalToConstant: 51)
        ])
        likeButton.addTarget(self, action: #selector(didTapLikeButton), for: .touchUpInside)
    }
    
    @objc private func didTapLikeButton() {
        guard let photoId,
              let photo = service.photos.first(where: { $0.id == photoId })
        else { return }
        
        let newLikeState = !photo.isLiked
        likeButton.isEnabled = false
        service.changeLike(photoId: photoId, isLike: newLikeState) { [weak self] success in
            guard let self else { return }
            self.likeButton.isEnabled = true
            if success {
                self.updateLikeButton()
            }
        }
    }
    
    
    @IBAction private func didTapShareButton(_ sender: Any) {
        
        guard let image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
    
    private func setImage(_ image: UIImage) {
        imageView.image = image
        imageView.frame.size = image.size
        rescaleAndCenterImageInScrollView(image: image)
    }
}

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
