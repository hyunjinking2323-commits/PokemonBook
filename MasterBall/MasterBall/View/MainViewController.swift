import UIKit
import RxSwift
import RxCocoa
import Then
import SnapKit

class MainViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let mainViewModel = MainViewModel()

        // 1. 이벤트를 발생시킬 소스
    private let fetchTriggerRelay = PublishRelay<Void>()

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
        $0.prefetchDataSource = self
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
            // 1. 뷰모델에 전달할 Input 객체 생성
            // fetchTriggerRelay(이벤트 발생지)를 Driver로 변환하여 전달
        let input = MainViewModel.Input(
            fetchTrigger: fetchTriggerRelay.asDriver(onErrorJustReturn: ())
        )

            // 2. 뷰모델의 transform을 거쳐 나온 Output을 받음
        let output = mainViewModel.transform(input: input)

            // 3. Output(데이터)을 화면에 바인딩
        output.pokemon
            // [scan] 이전 데이터(old)와 현재 데이터(new)를 튜플로 묶어서 다음 단계로 넘겨줌
            .scan((old: [Pokemon](), new: [Pokemon]())) { acc, new in
                    // acc.new는 직전 데이터, new는 방금 들어온 최신 데이터
                (old: acc.new, new: new)
            }
            // [drive] UI 업데이트 시작 (Main 스레드 보장)
            .drive(with: self, onNext: { owner, data in
                if data.old.isEmpty {
                        // 처음 데이터를 가져왔을 때는 전체 리프레시
                    owner.collectionView.reloadData()
                } else {
                        // 늘어난 개수만큼만 IndexPath를 계산해서 부분 삽입
                        // 화면이 위로 튀지 않고 부드럽게 아래로 붙음
                    let indexPaths = (data.old.count..<data.new.count).map { IndexPath(item: $0, section: 0) }
                    owner.collectionView.insertItems(at: indexPaths)
                }
            })
            .disposed(by: disposeBag)

            // 4. 앱 시작 시 첫 데이터를 불러오기 위해 수동으로 신호 한 번 보내기
        fetchTriggerRelay.accept(())
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

        // 스크롤이 끝에 닿으려 할 때 호출되는 대리자 메서드
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height - 100 {
                //  뷰모델 함수를 직접 호출하지 않고, Relay에 값을 넣어 '신호'만 보냄
            fetchTriggerRelay.accept(())
        }
    }
}

    // MARK: - DataSource & Prefetching
extension MainViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mainViewModel.currentPokemons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PosterCell.id, for: indexPath) as? PosterCell else {
            return UICollectionViewCell()
        }

        let pokemons = mainViewModel.currentPokemons
        guard indexPath.item < pokemons.count else { return cell }

        cell.configure(with: pokemons[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let currentCount = mainViewModel.currentPokemons.count
        if indexPaths.contains(where: { $0.item >= currentCount - 4 }) {
            fetchTriggerRelay.accept(())
        }
    }
}
