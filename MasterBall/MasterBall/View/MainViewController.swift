import UIKit
import RxSwift
import RxCocoa
import Then
import SnapKit

class MainViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let mainViewModel = MainViewModel()

    private let logoImageView = UIImageView().then {
        $0.image = UIImage(named: "MonsterBall")
        $0.contentMode = .scaleAspectFit
    }

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.register(PosterCell.self, forCellWithReuseIdentifier: PosterCell.id)
        $0.backgroundColor = UIColor(red: 120/255, green: 30/255, blue: 30/255, alpha: 1.0)
        $0.dataSource = self
        $0.delegate = self
        $0.prefetchDataSource = self // 무한 스크롤
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func configureUI() {
        view.backgroundColor = UIColor(red: 190/255, green: 30/255, blue: 40/255, alpha: 1.0)
        [logoImageView, collectionView].forEach {
            view.addSubview($0)
        }

        logoImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(100)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func bind() {
        mainViewModel.pokemonObservable
            .observe(on: MainScheduler.instance)
            .scan((old: [Pokemon](), new: [Pokemon]())) { acc, new in
                (old: acc.new, new: new)   // scan으로 이전/현재 값 동시에 들고 다니기
            }
            .subscribe(onNext: { [weak self] (old, new) in
                guard let self = self else { return }
                if old.isEmpty {
                    self.collectionView.reloadData()
                } else {
                    let indexPaths = (old.count..<new.count).map { IndexPath(item: $0, section: 0) }
                    self.collectionView.insertItems(at: indexPaths)
                }
            })
            .disposed(by: disposeBag)
    }
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1/3))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0.4, leading: 0.4, bottom: 0.4, trailing: 0.4)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

    // MARK: - Delegate
extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pokemons = mainViewModel.currentPokemons
        guard indexPath.item < pokemons.count else { return }

        let pokemon = pokemons[indexPath.item]
        let detailVC = DetailViewController(pokemon: pokemon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height - 100 {
            mainViewModel.fetchPokemon()
        }
    }
}

    // MARK: - DataSource & Prefetching
extension MainViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            // try? value() 대신 깔끔하게 접근
        return mainViewModel.currentPokemons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PosterCell.id, for: indexPath) as? PosterCell else {
            return UICollectionViewCell()
        }

        let pokemons = mainViewModel.currentPokemons
        

            // 인덱스 초과 방지 안전망
        guard indexPath.item < pokemons.count else { return cell }

        let pokemon = pokemons[indexPath.item]


        cell.configure(with: pokemon)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let currentCount = mainViewModel.currentPokemons.count

            // 마지막에서 4번째 아이템에 도달하면 패치
        if indexPaths.contains(where: { $0.item >= currentCount - 4 }) {
            mainViewModel.fetchPokemon()
        }
    }
}

