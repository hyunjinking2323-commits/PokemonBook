


import UIKit

struct PokemonResponse: Codable {
    let results: [Pokemon]
}

struct Pokemon: Codable {
    let name: String
    let url: String?

    var id: Int? {
        guard let url = url,
              let idString = url.split(separator: "/").filter({ !$0.isEmpty }).last else { return nil }
        return Int(idString)
    }
}

    // PokeAPI 상세 응답 구조에 맞게 수정
struct PokemonDetailResponse: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [TypeElement] // String에서 배열 구조로 변경
    let sprites: Sprites    // 이미지 로드를 위해 추가
}

struct TypeElement: Codable {
    let type: TypeInfo
}

struct TypeInfo: Codable {
    let name: String
}

struct Sprites: Codable {
    let frontDefault: String

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}
