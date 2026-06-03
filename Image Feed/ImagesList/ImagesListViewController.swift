import UIKit

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
    
    private let photosName: [String] = Array(0..<20).map{ "\($0)" }
    private let service = ImagesListService.shared
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewCell(_:)),
            name: ImagesListService.didChangeLikeNotification,
            object: nil
        )
    }
    
    @objc private func updateTableViewCell(_ notification: Notification) {
        guard let photoId = notification.userInfo?["photoId"] as? String,
                      let index = service.photos.firstIndex(where: { $0.id == photoId })
                else { return }
                let indexPath = IndexPath(row: index, section: 0)
                tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            let photo = service.photos[indexPath.row]
            viewController.image = UIImage(named: photo.name)
            viewController.photoId = photo.id
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        service.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

extension ImagesListViewController {
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = service.photos[indexPath.row]
                cell.delegate = self
        cell.configure(
            image: UIImage(named: photo.name),
            date: dateFormatter.string(from: photo.date),
            isLiked: photo.isLiked)
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = service.photos[indexPath.row]
        let newLikeState = !photo.isLiked

        cell.setLikeButtonEnabled(false)
        service.changeLike(photoId: photo.id, isLike: newLikeState) { success in
            cell.setLikeButtonEnabled(true)
        }
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = service.photos[indexPath.row]
                guard let image = UIImage(named: photo.name) else { return 0 }
                let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
                let width = tableView.bounds.width - insets.left - insets.right
                return image.size.height * (width / image.size.width) + insets.top + insets.bottom
    }
}
