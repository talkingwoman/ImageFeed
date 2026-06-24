import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    // MARK: - Properties
    
    var fullImageURL: URL? {
        didSet {
            guard isViewLoaded else { return }
            loadImage()
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
        
        loadImage()
    }
    
    
    // MARK: - Private Methods
    
    private func loadImage() {
             guard let fullImageURL else { return }

             UIBlockingProgressHUD.show()
             imageView.kf.setImage(with: fullImageURL) { [weak self] result in
                 UIBlockingProgressHUD.dismiss()
                 guard let self else { return }

                 switch result {
                 case .success(let value):
                     self.imageView.frame.size = value.image.size
                     self.rescaleAndCenterImageInScrollView(image: value.image)
                 case .failure(let error):
                     print("[SingleImageViewController.loadImage]: \(error.localizedDescription)")
                 }
             }
         }
    
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
             service.changeLike(photoId: photoId, isLike: newLikeState) { [weak self] result in
                 guard let self else { return }
                 DispatchQueue.main.async {
                     self.likeButton.isEnabled = true
                     switch result {
                     case .success:
                         self.updateLikeButton()
                     case .failure(let error):
                         print("[SingleImageViewController.didTapLikeButton]: \(error.localizedDescription)")
                     }
                 }
             }
         }
    
    
    @IBAction private func didTapShareButton(_ sender: Any) {
        guard let image = imageView.image else { return }
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
         }

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
