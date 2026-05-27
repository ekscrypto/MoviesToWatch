import Foundation

public struct Movie: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var title: String
    public var year: Int
    public var watched: Bool
    public var addedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        year: Int,
        watched: Bool = false,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.watched = watched
        self.addedAt = addedAt
    }
}

public struct SearchHit: Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let year: Int

    public init(id: String, title: String, year: Int) {
        self.id = id
        self.title = title
        self.year = year
    }
}
