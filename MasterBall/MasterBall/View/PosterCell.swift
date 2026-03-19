import UIKit
import Then
import SnapKit
import Kingfisher

class PosterCell: UICollectionViewCell {

    static var id: String { String(describing: Self.self) }
    private let posterImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 235/255, alpha: 1.0)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(posterImageView)

        posterImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.kf.cancelDownloadTask()
        posterImageView.image = nil
    }

    func configure(with pokemon: Pokemon) {
        guard let pokemonId = pokemon.id else { return }

        let url = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(pokemonId).png")

        posterImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder"),
            options: [.transition(.fade(0.5))]
        )
    }
}
