import UIKit
import Kingfisher

protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfileViewPresenterProtocol? { get set }
    func updateProfileDetails(name: String, login: String, bio: String)
    func updateAvatar(url: URL?)
    func updateFavorites(count: Int, isEmpty: Bool)
}

final class ProfileViewController: UIViewController & ProfileViewControllerProtocol {
    
    // MARK: - Properties
    
    var presenter: ProfileViewPresenterProtocol?
    private var gradientViews: [GradientView] = []
    
    private var favoritePhotos: [Photo] {
        presenter?.favoritePhotos ?? []
    }
    
    // MARK: - UI Elements
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .gray
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(white: 0.65, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoutButton: UIButton = {
        guard let image = UIImage(named: "logout_button") else {
            assertionFailure("Image 'logout_button' not found")
            return UIButton(type: .system)
        }
        let button = UIButton.systemButton(
            with: image,
            target: nil,
            action: nil
        )
        button.tintColor = UIColor(named: "YP Red")
        button.accessibilityIdentifier = "logout button"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let favoritesCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(white: 0.65, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emptyFavoritesLabel: UILabel = {
        let label = UILabel()
        label.text = "Ничего ещё нет!"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let favoritesTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Configuration
    
    func configure(_ presenter: ProfileViewPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        
        setupProfileUI()
        setupFavoritesUI()
        addGradients()
        
        presenter?.viewDidLoad()
    }
    
    // MARK: - ProfileViewControllerProtocol
    
    func updateProfileDetails(name: String, login: String, bio: String) {
        nameLabel.text = name
        usernameLabel.text = login
        bioLabel.text = bio
        removeGradients()
    }
    
    func updateAvatar(url: URL?) {
        guard let url else { return }
        
        let placeholderImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ]
        )
        removeGradients()
    }
    
    func updateFavorites(count: Int, isEmpty: Bool) {
        favoritesCountLabel.text = "\(count)"
        emptyFavoritesLabel.isHidden = !isEmpty
        favoritesTableView.isHidden = isEmpty
        favoritesTableView.reloadData()
    }
    
    // MARK: - Setup
    
    private func setupProfileUI() {
        view.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        logoutButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        view.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let stackView = UIStackView(arrangedSubviews: [nameLabel, usernameLabel, bioLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupFavoritesUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Избранное"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, favoritesCountLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStack)
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 24),
            headerStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        ])
        
        view.addSubview(emptyFavoritesLabel)
        NSLayoutConstraint.activate([
            emptyFavoritesLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 80),
            emptyFavoritesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        favoritesTableView.dataSource = self
        favoritesTableView.delegate = self
        favoritesTableView.register(
            ImagesListCell.self,
            forCellReuseIdentifier: ImagesListCell.reuseIdentifier
        )
        view.addSubview(favoritesTableView)
        NSLayoutConstraint.activate([
            favoritesTableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            favoritesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            favoritesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            favoritesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Gradients (skeleton)
    
    private func addGradients() {
        let targets: [UIView] = [avatarImageView, nameLabel, usernameLabel, bioLabel]
        for target in targets {
            let gradient = GradientView()
            gradient.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(gradient)
            NSLayoutConstraint.activate([
                gradient.leadingAnchor.constraint(equalTo: target.leadingAnchor),
                gradient.topAnchor.constraint(equalTo: target.topAnchor),
                gradient.widthAnchor.constraint(equalToConstant: target === avatarImageView ? 70 : 150),
                gradient.heightAnchor.constraint(equalToConstant: target === avatarImageView ? 70 : 20)
            ])
            gradient.startAnimating()
            gradientViews.append(gradient)
        }
    }
    
    private func removeGradients() {
        gradientViews.forEach {
            $0.stopAnimating()
            $0.removeFromSuperview()
        }
        gradientViews.removeAll()
    }
    
    // MARK: - Actions
    
    @objc private func didTapButton() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Да", style: .destructive) { [weak self] _ in
            self?.presenter?.logout()
            self?.switchToSplashScreen()
        })
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel))
        present(alert, animated: true)
    }
    
    private func switchToSplashScreen() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            assertionFailure("Invalid window configuration")
            return
        }
        window.rootViewController = SplashViewController()
    }
}

// MARK: - UITableViewDataSource

extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favoritePhotos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }
        let photo = favoritePhotos[indexPath.row]
        cell.configure(
            imageURL: URL(string: photo.thumbImageURL),
            date: "",
            isLiked: photo.isLiked
        )

        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photo = favoritePhotos[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "SingleImageViewController"
        ) as? SingleImageViewController else { return }
        vc.fullImageURL = URL(string: photo.largeImageURL)
        vc.photoId = photo.id
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = favoritePhotos[indexPath.row]
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let width = tableView.bounds.width - insets.left - insets.right
        guard photo.size.width > 0 else { return 200 }
        return photo.size.height * (width / photo.size.width) + insets.top + insets.bottom
    }
}

// MARK: - ImagesListCellDelegate

extension ProfileViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = favoritesTableView.indexPath(for: cell) else { return }
        let photo = favoritePhotos[indexPath.row]

        cell.setLikeButtonEnabled(false)
        presenter?.changeLike(photoId: photo.id, isLike: !photo.isLiked) { _ in
            cell.setLikeButtonEnabled(true)
        }
    }
}
