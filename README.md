# 🔴 MasterBall - 포켓몬 도감 앱

iOS UIKit 기반 포켓몬 도감 앱입니다. [PokeAPI](https://pokeapi.co/)를 활용해 포켓몬 목록을 무한 스크롤로 탐색하고, 각 포켓몬의 상세 정보를 한국어로 확인할 수 있습니다.

---

## 📱 주요 기능

- 포켓몬 목록 무한 스크롤 (페이지네이션)
- 포켓몬 이름 한국어 번역
- 타입 한국어 표시
- 포켓몬 상세 정보 (키, 몸무게, 타입, 이미지)
- 공식 아트워크 이미지 로드

---

## 🛠 기술 스택

| 분류 | 사용 기술 |
|------|-----------|
| UI | UIKit, SnapKit, Then |
| 반응형 프로그래밍 | RxSwift, RxCocoa |
| 네트워킹 | URLSession, Alamofire |
| 이미지 | Kingfisher |
| 아키텍처 | MVVM |

---

## 🗂 프로젝트 구조

```
MasterBall/
├── Model/
│   ├── Pokemon.swift              # 포켓몬 데이터 모델 (PokemonResponse, PokemonDetailResponse 등)
│   └── PokemonTypeName.swift      # 포켓몬 타입 한글 변환 enum
├── ViewModel/
│   ├── MainViewModel.swift        # 목록 페이지네이션 및 데이터 관리
│   └── DetailViewModel.swift      # 상세 정보 fetch 및 relay
├── View/
│   ├── MainViewController.swift   # 포켓몬 목록 (CollectionView)
│   ├── DetailViewController.swift # 포켓몬 상세 화면
│   └── PosterCell.swift           # 목록 셀
├── Network/
│   └── NetworkManger.swift        # 싱글톤 네트워크 매니저 (Generic fetch)
└── Util/
    └── PokemonTranslator.swift    # 영어 → 한국어 이름 변환 딕셔너리
```

---

## ⚠️ 코드 점검 결과

### 1. `NetworkManger` 오타
**파일:** `NetworkManger.swift`  
`NetworkManger` → `NetworkManager` 로 수정 권장 (Manager 오타)

---

### 2. `DetailViewModel` — `BehaviorSubject` 에러 처리 취약
**파일:** `DetailViewModel.swift`

```swift
// 현재 코드
let pokemonDetailRelay = BehaviorSubject<PokemonDetailResponse?>(value: nil)

// onError가 발생하면 Subject가 종료되어 이후 구독이 불가능해집니다.
self?.pokemonDetailRelay.onError(error)
```

**권장:** `BehaviorRelay`로 교체하고 에러는 별도 Subject로 전달

```swift
let pokemonDetailRelay = BehaviorRelay<PokemonDetailResponse?>(value: nil)
let errorRelay = PublishRelay<Error>()

// onFailure 시
self?.errorRelay.accept(error)
```

---

### 3. `MainViewController` — 스크롤 이벤트 중복 호출 가능성
**파일:** `MainViewController.swift`

`scrollViewDidScroll`과 `prefetchItemsAt` 두 곳에서 모두 `fetchPokemon()`을 호출하고 있어 중복 요청이 발생할 수 있습니다. `isFetching` 가드가 있어 실제 중복 요청은 막히지만, 한 곳으로 통일하는 것이 명확합니다.

**권장:** `prefetchItemsAt`만 사용하거나, `scrollViewDidScroll` 조건을 더 보수적으로 설정

---

### 4. `DetailViewController` — `BehaviorSubject` onError 시 UI 업데이트 중단
**파일:** `DetailViewController.swift`

`pokemonDetailRelay`가 `BehaviorSubject`이므로 `onError` 이벤트 수신 시 `subscribe`가 완전히 종료됩니다. 에러 발생 후 재시도 버튼 등의 UX가 없다면 화면이 빈 상태로 남습니다.

**권장:** 에러 발생 시 사용자에게 알림 처리 추가

```swift
}, onError: { [weak self] error in
    // 알럿 또는 토스트로 사용자에게 알림
    self?.showErrorAlert(message: "포켓몬 정보를 불러오지 못했습니다.")
})
```

---

### 5. `PosterCell` — 네임스페이스 충돌 가능성
**파일:** `PosterCell.swift`

`static let id = "PosterCell"` 방식은 안전하지만, 셀 ID를 타입 이름 기반으로 자동 생성하면 오타 위험을 줄일 수 있습니다.

```swift
// 더 안전한 방식
static var id: String { String(describing: Self.self) }
```

---

### 6. `MainViewModel` — `hasNextPage` 판단 로직
**파일:** `MainViewModel.swift`

```swift
self.hasNextPage = !pokemonResponse.results.isEmpty
```

결과가 `limit`보다 적게 왔을 때도 다음 페이지가 있다고 판단할 수 있습니다.

**권장:**
```swift
self.hasNextPage = pokemonResponse.results.count == self.limit
```
제공해주신 양식과 동일한 스타일로 작성했습니다. 혹시 수정하고 싶은 내용 있으면 말씀해주세요!
