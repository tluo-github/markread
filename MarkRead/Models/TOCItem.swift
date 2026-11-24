import Foundation

struct TOCItem: Identifiable, Equatable, Decodable {
    let id: String
    let level: Int
    let title: String
}
