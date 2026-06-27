import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

enum FeedCellImageState {
    case loading
    case error
    case finished(UIImage)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    @IBOutlet private var cellImage: UIImageView!
    @IBOutlet private var likeButton: UIButton!
    @IBOutlet private var dateLabel: UILabel!
    
    weak var delegate: ImagesListCellDelegate?
    private let gradientView = GradientView()
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGradientView()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupProgrammaticLayout()
    }
    
    private func setupProgrammaticLayout() {
        backgroundColor = .clear
        selectionStyle = .none
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        cellImage = imageView
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(likeButtonClicked(_:)), for:
                .touchUpInside)
        contentView.addSubview(button)
        likeButton = button
        
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        dateLabel = label
        
        setupGradientView()
        
        NSLayoutConstraint.activate([
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                               constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                constant: -16),
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant:
                                                -4),
            
            likeButton.topAnchor.constraint(equalTo: cellImage.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
            
            dateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant:
                                                8),
            dateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant:
                                                -8)
        ])
    }
    
    private func setupGradientView() {
        guard gradientView.superview == nil else { return }   // защита от двойного добавления
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradientView)
        NSLayoutConstraint.activate([
            gradientView.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            gradientView.topAnchor.constraint(equalTo: cellImage.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor)
        ])
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
        gradientView.stopAnimating()
    }
    
    // MARK: - Configuration
    
    func setLikeButtonEnabled(_ isEnabled: Bool) {
        likeButton.isEnabled = isEnabled
    }
    
    private func setState(_ state: FeedCellImageState) {
        switch state {
        case .loading:
            gradientView.isHidden = false
            gradientView.startAnimating()
        case .error:
            gradientView.stopAnimating()
            gradientView.isHidden = true
            cellImage.image = UIImage(named: "photo_placeholder")
        case .finished(let image):
            gradientView.stopAnimating()
            gradientView.isHidden = true
            cellImage.image = image
        }
    }
    
    func configure(imageURL: URL?, date: String, isLiked: Bool) {
        dateLabel.text = date
        setIsLiked(isLiked)
        
        setState(.loading)
        cellImage.kf.setImage(with: imageURL) { [weak self] result in
            switch result {
            case .success(let value):
                self?.setState(.finished(value.image))
            case .failure:
                self?.setState(.error)
            }
        }
    }
    
    func setIsLiked(_ isLiked: Bool) {
        let likeImage = isLiked
        ? UIImage(named: "like_button_on")
        : UIImage(named: "like_button_off")
        likeButton.setImage(likeImage, for: .normal)
    }
    
    @IBAction private func likeButtonClicked(_ sender: Any) {
        delegate?.imageListCellDidTapLike(self)
    }
}
