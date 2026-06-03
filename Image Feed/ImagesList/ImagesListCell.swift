import UIKit

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    @IBOutlet private var cellImage: UIImageView!
    @IBOutlet private var likeButton: UIButton!
    @IBOutlet private var dateLabel: UILabel!
    
    weak var delegate: ImagesListCellDelegate?

    // MARK: - Init

    // Из сториборда (лента) — аутлеты связываются автоматически.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // Программно (избранное в профиле) — строим вёрстку в коде.
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
        button.addTarget(self, action: #selector(likeButtonClicked(_:)), for: .touchUpInside)
        contentView.addSubview(button)
        likeButton = button

        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        dateLabel = label

        NSLayoutConstraint.activate([
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            likeButton.topAnchor.constraint(equalTo: cellImage.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),

            dateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Configuration

    func setLikeButtonEnabled(_ isEnabled: Bool) {
        likeButton.isEnabled = isEnabled
    }
    
    func configure(image: UIImage?, date: String, isLiked: Bool) {
        cellImage.image = image
        dateLabel.text = date
        setIsLiked(isLiked)
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
