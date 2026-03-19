import UIKit
import RxSwift
import RxCocoa

class DetailViewModel {
    private let disposeBag = DisposeBag()
    private let pokemon: Pokemon

        // VC와 소통할 규격 정의
    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {
        let pokemonDetail: Driver<PokemonDetailResponse?>
        let errorMessage: Driver<String>
    }

    init(pokemon: Pokemon) {
        self.pokemon = pokemon
    }

    func transform(input: Input) -> Output {
        let pokemonDetailRelay = BehaviorRelay<PokemonDetailResponse?>(value: nil)
        let errorRelay = PublishRelay<String>()

        input.viewDidLoad
            .flatMapFirst { [weak self] _ -> Observable<PokemonDetailResponse> in
                guard let self = self, let pokemonId = self.pokemon.id,
                      let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(pokemonId)/") else {
                    return .empty()
                }
                return NetworkManager.shared.fetch(url: url).asObservable()
            }
            .subscribe(onNext: { detail in
                pokemonDetailRelay.accept(detail)
            }, onError: { error in
                errorRelay.accept("포켓몬 정보를 불러오지 못했습니다.")
            })
            .disposed(by: disposeBag)

        return Output(
            pokemonDetail: pokemonDetailRelay.asDriver(onErrorJustReturn: nil),
            errorMessage: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 에러가 발생했습니다.")
        )
    }
}
