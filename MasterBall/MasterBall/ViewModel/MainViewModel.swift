import UIKit
import RxSwift
import RxCocoa

class MainViewModel {
    private let disposeBag = DisposeBag()
    private let limit = 20
    private var offset = 0
    private var isFetching = false
    private var hasNextPage = true //  더 가져올 데이터가 있는지 확인
        // Subject -> Relay 사용 (UI 바인딩용으로  안전함. 에러로 끊기지 않음)
    private let pokemonRelay = BehaviorRelay <[Pokemon]>(value: [])
    private let pokemonDetailRelay  = BehaviorRelay <[Int: UIImage]>(value: [:])
        // 외부에서는 읽기 전용 Observable로 접근
    var pokemonObservable: Observable<[Pokemon]> {
        return pokemonRelay.asObservable()
    }
        // 배열 자체를 바로 꺼내올 수 있는 편의 프로퍼티(기존 try? value() 대체)
    var currentPokemons: [Pokemon] {
        return pokemonRelay.value
    }

    var currentDetails: [Int: UIImage] {
        return pokemonDetailRelay.value
    }

    init() {
        fetchPokemon()
    }

    func fetchPokemon() {
            //  가져오는 중이거나 더 이상 데이터가 없으면 중단
        guard !isFetching && hasNextPage else { return }
        isFetching = true

        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=\(limit)&offset=\(offset)") else {
            isFetching = false
            return
        }

        NetworkManager.shared.fetch(url: url)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (pokemonResponse: PokemonResponse) in
                guard let self = self else { return }

                    // 기존 데이터에 새로운 데이터 병합.
                var updatedList = self.pokemonRelay.value
                updatedList.append(contentsOf: pokemonResponse.results)
                self.pokemonRelay.accept(updatedList) // onNext 대신 accept 사용.

                    // 다음 페이지를 위한 세팅.
                self.offset += self.limit
                self.hasNextPage = pokemonResponse.results.count == self.limit
                self.isFetching = false

                    // 여기서 각 포켓몬의 상세 이미지 URL을 바탕으로
                    // 이미지를 다운로드해서 pokemonDetailRelay에 넣어주는 로직이 추가되어야 한다.
            }, onFailure: { [weak self] error in
                print("데이터 로딩 실패: \(error.localizedDescription)")
                self?.isFetching = false
            }).disposed(by: disposeBag)
    }
}
