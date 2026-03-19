# 📱 앱 개발 심화 주차 과제 - Challenge

## 📌 과제 소개

포켓몬 API를 활용하여 포켓몬 목록을 조회하고 상세 정보를 확인할 수 있는 iOS 애플리케이션입니다.

- 포켓몬 리스트 조회
- 포켓몬 상세 정보 조회
- 무한 스크롤 기능
- MVVM 아키텍처
- RxSwift, RxRelay 구조 적용

---

## 🛠️ 기술 스택

| Tool | |
|------|-|
| UIKit | UI 구성 |
| SnapKit | 오토레이아웃 |
| Then | 클로저 기반 초기화 |
| Kingfisher | 이미지 로딩 및 캐싱 |
| PokeAPI | 포켓몬 데이터 |
| RxSwift | 반응형 프로그래밍 |
| RxRelay | 상태 관리 |

---

## ⏰ 과제 일정

- 시작일: 2026.03.13
- 종료일: 2026.03.17

---

## 📂 프로젝트 구조 (MVVM)

```
📁 Common
 ┣ NetworkManager.swift

📁 Model
 ┣ Pokemon.swift
 ┣ PokemonTypeName.swift

📁 View
 ┣ MainViewController.swift
 ┣ DetailViewController.swift
 ┣ PosterCell.swift

📁 ViewModel
 ┣ MainViewModel.swift
 ┣ DetailViewModel.swift

📁 Utils
 ┣ PokemonTranslator.swift
```

---

## 📋 구현 단계

### Step 1 - NetworkManager 구현

- 싱글톤 패턴을 적용하여 앱 전역에서 하나의 인스턴스만 사용하도록 구현하였다.
- `fetch<T: Decodable>(url: URL) -> Single<T>` 형태의 Generic 메서드를 구현하여 어떤 타입이든 디코딩 가능하도록 설계하였다.
- URLSession의 dataTask를 RxSwift의 `Single`로 래핑하여 성공/실패를 명확하게 처리하였다.
- 네트워크 오류, 응답 오류, 디코딩 오류를 `NetworkError` enum으로 분리하여 관리하였다.

---

### Step 2 - Model 구현

- PokeAPI의 목록 응답을 담는 `PokemonResponse`, `Pokemon` 구조체를 선언하였다.
- 포켓몬 상세 응답을 담는 `PokemonDetailResponse` 구조체를 선언하였다.
- 타입 정보는 `TypeElement`, `TypeInfo` 구조체로 중첩 구조를 그대로 모델링하였다.
- 이미지 URL을 포함하는 `Sprites` 구조체에 `CodingKeys`를 적용하여 snake_case를 camelCase로 변환하였다.
- `Pokemon` 구조체에 `url`에서 id를 파싱하는 computed property를 추가하였다.

---

### Step 3 - MainViewModel 구현

- `BehaviorRelay<[Pokemon]>`을 사용하여 포켓몬 목록 상태를 관리하였다.
- `limit=20, offset=0` 기준으로 페이지네이션을 구현하였다.
- `isFetching` 플래그로 중복 API 호출을 방지하였다.
- `hasNextPage` 플래그로 더 이상 데이터가 없을 때 fetch를 중단하도록 처리하였다.
- 외부에서는 `pokemonObservable`로 읽기 전용 접근만 허용하고, 내부에서만 `accept`로 값을 변경하도록 설계하였다.

---

### Step 4 - MainViewController 구현

- `UICollectionViewCompositionalLayout`을 사용하여 한 줄에 3개씩 노출되는 Grid 레이아웃을 구성하였다.
- `BehaviorRelay`를 구독하여 데이터 변경 시 UI를 자동으로 업데이트하도록 바인딩하였다.
- `scan` 연산자로 이전/현재 포켓몬 배열을 비교하여 처음 로드 시에는 `reloadData`, 추가 로드 시에는 `insertItems`만 호출하도록 최적화하였다.
- 포켓몬 공식 아트워크 이미지를 Kingfisher로 로드하였다.

---

### Step 5 - 화면 전환

- `UICollectionViewDelegate`의 `didSelectItemAt`을 활용하여 셀 클릭 시 선택된 포켓몬 정보를 `DetailViewController`로 전달하였다.
- `navigationController?.pushViewController`로 화면 전환을 구현하였다.
- 메인 화면에서는 네비게이션 바를 숨기고, 상세 화면에서는 back 버튼이 보이도록 `viewWillAppear`에서 제어하였다.

---

### Step 6 - DetailViewModel 구현

- 상위 화면에서 전달받은 `Pokemon` 객체의 id를 기반으로 상세 API를 호출하였다.
- `BehaviorRelay<PokemonDetailResponse?>`를 사용하여 상세 데이터를 관리하였다.
- 에러 발생 시 `PublishRelay<Error>`를 통해 View로 전달하도록 구현하였다.
- `fetchPokemonDetailRelay()` 메서드를 외부에서 명시적으로 호출하는 구조로 설계하였다.

---

### Step 7 - DetailViewController 구현

- 포켓몬 번호, 이름(한글), 타입(한글), 키, 몸무게, 이미지를 화면에 표시하였다.
- `PokemonTranslator`를 활용하여 영어 이름을 한글로 변환하였다.
- `PokemonTypeName` enum을 활용하여 타입을 한글로 변환하고 `, `로 이어서 표시하였다.
- 키는 height / 10.0 (m), 몸무게는 weight / 10.0 (kg) 단위로 환산하여 표시하였다.
- Kingfisher로 공식 아트워크 이미지를 로드하였다.

---

### Step 8 - 무한 스크롤 구현 

- `UICollectionViewDataSourcePrefetching`의 `prefetchItemsAt`을 구현하여 마지막에서 4번째 아이템 도달 시 다음 페이지를 선제적으로 로드하였다.
- `scrollViewDidScroll`에서 스크롤이 하단 100pt 이내에 도달하면 추가 fetch를 호출하도록 구현하였다.
- fetch 완료 시 `offset += limit`으로 다음 페이지 위치를 갱신하였다.

---

##  도전 기능

- Kingfisher 라이브러리를 활용한 이미지 캐싱 및 `prepareForReuse()` 시 다운로드 취소 처리
- `BehaviorRelay`를 활용한 에러 없이 안전한 상태 관리
- `scan` 연산자를 활용한 CollectionView 부분 업데이트 최적화

---

## 📝 Decision 로그

### 1. Subject vs Relay

| | Subject | Relay |
|--|--|--|
| 에러 처리 | `onError` 시 스트림 종료 | 에러 없음, 스트림 유지 |
| 완료 처리 | `onCompleted` 시 종료 | 완료 없음 |
| UI 바인딩 | 부적합 |  적합 |

- UI에 바인딩되는 데이터는 에러나 완료로 스트림이 끊기면 안 된다고 판단하였다.
- `onError` 발생 시 `Subject`는 종료되어 이후 데이터를 받을 수 없게 되는 문제가 있다.
- 따라서 `MainViewModel`의 포켓몬 목록과 `DetailViewModel`의 상세 데이터 모두 `BehaviorRelay`로 관리하였다.
- 에러는 별도의 `PublishRelay<Error>`로 분리하여 View에 전달하였다.

---

### 2. 무한 스크롤 방식

| | scrollViewDidScroll | prefetchItemsAt |
|--|--|--|
| 동작 시점 | 스크롤 위치 기준 (사후) | 셀 렌더링 직전 (선제) |
| 정밀도 | 낮음 (픽셀 기준) | 높음 (인덱스 기준) |
| 중복 호출 | 빈번함 | 상대적으로 적음 |

- `prefetchItemsAt`은 마지막 4번째 아이템 진입 시점을 인덱스로 정확하게 감지할 수 있어 선택하였다.
- `scrollViewDidScroll`은 픽셀 단위로 매 프레임마다 호출되어 중복 호출 가능성이 높지만, `isFetching` 플래그로 방어하여 보조 수단으로 함께 사용하였다.

---

### 3. 이미지 로딩 - 직접 구현 vs Kingfisher

| | 직접 구현 | Kingfisher |
|--|--|--|
| 캐싱 | 별도 구현 필요 |  자동 메모리/디스크 캐싱 |
| 셀 재사용 대응 | 직접 취소 로직 작성 |  `kf.cancelDownloadTask()` 제공 |
| 페이드 전환 | 직접 구현 | `.transition(.fade())` 옵션 제공 |
| 코드량 | 많음 | 적음 |

- 이미지 캐싱, 셀 재사용 시 깜빡임 방지, 페이드 인 전환 등을 직접 구현하면 코드가 복잡해진다.
- Kingfisher는 이 모든 기능을 한 줄로 처리할 수 있어 선택하였다.
- `prepareForReuse()`에서 `kf.cancelDownloadTask()`를 호출하여 셀 재사용 시 이전 이미지가 깜빡이는 문제를 방지하였다.

---

### 4. 네트워크 - Alamofire vs URLSession

| | Alamofire | URLSession |
|--|--|--|
| 코드량 | 적음 | 많음 |
| 의존성 | 외부 라이브러리 | 기본 내장 |
| RxSwift 래핑 | 별도 작업 필요 | 직접 Single로 래핑 가능 |
| 학습 목적 | 낮음 |  높음 |

- `NetworkManager`의 `fetch` 메서드는 URLSession을 직접 `Single`로 래핑하는 구조로 구현하였다.
- RxSwift의 데이터 흐름을 직접 다루는 연습 목적에서 URLSession을 선택하였다.
- Alamofire는 import만 되어 있으나 실제 네트워크 요청에는 사용하지 않았다.

---

### 5. CollectionView 업데이트 - reloadData vs insertItems

| | reloadData | insertItems |
|--|--|--|
| 동작 방식 | 전체 셀 재생성 | 추가된 셀만 삽입 |
| 성능 | 낮음 (전체 갱신) | 높음 (부분 갱신) |
| 스크롤 위치 유지 |  초기화됨 |  유지됨 |

- `reloadData`는 무한 스크롤 시 매번 전체 셀을 재생성하여 스크롤 위치가 초기화되고 성능이 저하된다.
- `scan` 연산자로 이전/현재 배열을 비교하여 처음 로드 시에만 `reloadData`, 이후 추가 로드 시에는 `insertItems`만 호출하도록 최적화하였다.

---

### 6. DetailViewController 포켓몬 정보 레이아웃 위치

| | viewDidLoad | bind() 내부 |
|--|--|--|
| 역할 | UI 구성 및 제약 설정 | 데이터 바인딩 |
| 가독성 |  명확한 책임 분리 | 레이아웃과 데이터가 섞임 |

- 레이아웃(SnapKit 제약)은 `configureUI()`에서 고정값으로 설정하고, 실제 데이터(이름, 타입 등) 바인딩은 `bind()`에서만 처리하도록 역할을 분리하였다.
- 데이터가 없어도 UI 구조는 항상 잡혀 있어야 하므로 레이아웃과 데이터 바인딩을 분리하는 것이 적합하다고 판단하였다.

---

### 7. hasNextPage 판단 기준

| | `!results.isEmpty` | `results.count == limit` |
|--|--|--|
| 마지막 페이지 감지 |  부정확 |  정확 |
| 예시 (limit=20, 마지막 3개) | 데이터 있으므로 true → 불필요한 추가 요청 발생 | 20개 미만이므로 false → 정확히 종료 |

- 마지막 페이지에서 20개 미만의 데이터가 오는 경우, `!results.isEmpty`로는 다음 페이지가 있다고 잘못 판단하여 불필요한 API 요청이 발생한다.
- `results.count == limit` 조건으로 정확하게 마지막 페이지를 감지하도록 수정하였다.

---

### 8. 에러 로깅 - localizedDescription 선택 이유

- `onFailure`에서 에러를 출력할 때 `error.localizedDescription`을 사용하였다.
- `error` 자체를 출력하면 Swift 내부 표현 형식(`NetworkError.decodingFail`)으로 출력되어 가독성이 낮다.
- `localizedDescription`은 사람이 읽기 쉬운 형태의 문자열을 반환하므로 디버깅 시 원인을 빠르게 파악할 수 있다.
- 커스텀 `NetworkError`의 경우 `LocalizedError` 프로토콜을 채택하면 `localizedDescription`을 직접 정의할 수 있어 확장성도 높다.
