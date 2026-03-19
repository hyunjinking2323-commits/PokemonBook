import UIKit
import RxSwift
import RxCocoa

class DetailViewModel {
    private let disposeBag = DisposeBag()
    private let pokemon: Pokemon

    let pokemonDetailRelay = BehaviorRelay<PokemonDetailResponse?>(value: nil)
    let errorRelay = PublishRelay<Error>()

    init(pokemon: Pokemon) {
        self.pokemon = pokemon
    }

    func fetchPokemonDetailRelay() {
        guard let pokemonId = pokemon.id else { return }
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(pokemonId)/") else { return }

        NetworkManager.shared.fetch(url: url)
            .subscribe(onSuccess: { [weak self] (detail: PokemonDetailResponse) in
                self?.pokemonDetailRelay.accept(detail)
            }, onFailure: { [weak self] error in
                self?.errorRelay.accept(error)
            }).disposed(by: disposeBag)
    }
}
