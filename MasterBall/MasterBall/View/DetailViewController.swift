    //
    //  PokemonDetailViewController.swift
    //  MasterBall
    //
    //  Created by t2025-m0239 on 2026.03.16.
    //

import UIKit
import RxSwift
import RxCocoa
import Then
import SnapKit
import Kingfisher // 이미지 로드를 위해 필요합니다

final class DetailViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let detailViewModel: DetailViewModel

    private let pokemonCard = UIView().then {
        $0.backgroundColor =  UIColor(red: 120/255, green: 30/255, blue: 30/255, alpha: 1.0)
        $0.layer.cornerRadius = 15
        $0.clipsToBounds = true
    }

    private let stackView = UIStackView().then {
        $0.distribution = .fill
        $0.axis = .horizontal
        $0.spacing = 10
    }

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private var no = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 34, weight: .medium)
        $0.textColor = .white
    }

    private let name = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 34, weight: .medium )
        $0.textColor = .white
    }

    private let type = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 20, weight: .medium )
        $0.textColor = .white
    }

    private let height = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 20, weight: .medium )
        $0.textColor = .white
    }

    private let weight = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 20, weight: .medium )
        $0.textColor = .white
    }

    private var pokemon: Pokemon

    init(pokemon: Pokemon) {
        self.pokemon = pokemon
        self.detailViewModel = DetailViewModel(pokemon: pokemon)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
            // ViewModel에 데이터 요청 호출이 필요할 수 있습니다
        detailViewModel.fetchPokemonDetailRelay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)

    }

    private func configureUI() {
        view.backgroundColor = UIColor(red: 190/255, green: 30/255, blue: 40/255, alpha: 1.0)

        [pokemonCard, stackView, imageView, type, height, weight].forEach {
            view.addSubview($0)
        }

        [no, name].forEach {
            stackView.addArrangedSubview($0)
        }

        pokemonCard.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.bottom.equalTo(weight.snp.bottom).offset(30)
        }

        imageView.snp.makeConstraints {
            $0.top.equalTo(pokemonCard.snp.top).offset(20)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(200)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        type.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        height.snp.makeConstraints {
            $0.top.equalTo(type.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        weight.snp.makeConstraints {
            $0.top.equalTo(height.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
    }

    func bind() {
        detailViewModel.pokemonDetailRelay
            .observe(on: MainScheduler.instance)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] pokemonDetail in
                guard let self = self else { return }
                self.no.text = "No. \(pokemonDetail.id)"
                self.name.text = PokemonTranslator.getKoreanName(for: pokemonDetail.name)
                self.type.text = "타입: " + pokemonDetail.types.compactMap {
                    PokemonTypeName(rawValue: $0.type.name)?.displayName
                }.joined(separator: ", ")
                self.height.text = "키: \(Float(pokemonDetail.height) / 10.0) m"
                self.weight.text = "몸무게: \(Float(pokemonDetail.weight) / 10.0) kg"

                if let url = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(pokemonDetail.id).png") {
                    self.imageView.kf.setImage(with: url)
                }
            })
            .disposed(by: disposeBag)

        detailViewModel.errorRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                let alert = UIAlertController(
                    title: "오류",
                    message: "포켓몬 정보를 불러오지 못했습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
