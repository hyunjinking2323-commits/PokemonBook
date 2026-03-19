import UIKit
import RxSwift
import RxCocoa

class MainViewModel {
    private let disposeBag = DisposeBag()
    private let limit = 20
    private var offset = 0
    private var isFetching = false
    private var hasNextPage = true

        // 내부에서만 값을 수정할 수 있는 Relay (데이터 저장소)
    private let pokemonRelay = BehaviorRelay<[Pokemon]>(value: [])

        // VC에서 실시간 데이터가 필요할 때 안전하게 꺼내 쓰는 프로퍼티
    var currentPokemons: [Pokemon] {
        return pokemonRelay.value
    }

    init() {}

        // transform: VC의 '신호'를 받아 '결과 데이터'로 변환하는 함수
    func transform(input: Input) -> Output {

            // 1. VC에서 보낸 fetchTrigger(신호)가 들어오면 실행됨
        input.fetchTrigger
            .drive(with: self, onNext: { owner, _ in
                    // 중복 요청 방지 및 다음 페이지가 있을 때만 실제 데이터 호출
                if !owner.isFetching && owner.hasNextPage {
                    owner.fetchPokemon()
                }
            })
            .disposed(by: disposeBag)

            // 2. pokemonRelay -> Driver로 변환해서 반환
        return Output(pokemon: pokemonRelay.asDriver(onErrorJustReturn: []))
    }

    private func fetchPokemon() {
        isFetching = true

        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=\(limit)&offset=\(offset)") else {
            isFetching = false
            return
        }

        NetworkManager.shared.fetch(url: url)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (pokemonResponse: PokemonResponse) in
                guard let self = self else { return }

                    // 기존 리스트 뒤에 새로 받아온 리스트를 합쳐서 전달
                var updatedList = self.pokemonRelay.value
                updatedList.append(contentsOf: pokemonResponse.results)
                self.pokemonRelay.accept(updatedList)

                    // 다음 페이지를 위한 오프셋 계산 및 상태 업데이트
                self.offset += self.limit
                self.hasNextPage = pokemonResponse.results.count == self.limit
                self.isFetching = false
            }, onFailure: { [weak self] error in
                print("데이터 로딩 실패: \(error.localizedDescription)")
                self?.isFetching = false
            })
            .disposed(by: disposeBag)
    }
}

    // VC와 통신할 데이터 규격을 정의
extension MainViewModel {
    struct Input {
        let fetchTrigger: Driver<Void> // VC가 보내는 신호
    }

    struct Output {
        let pokemon: Driver<[Pokemon]> // 뷰모델이 답장하는 결과
    }
}
