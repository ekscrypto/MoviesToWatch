import Testing
import Foundation
@testable import DomainLogic

/// Literal-fixture lock for the on-disk `[Movie]` JSON wire shape, per
/// ADR-011. A round-trip pair (`encode → decode → ==`) would pass even if
/// every `CodingKey` were silently renamed in lock-step; this fixture is the
/// external anchor that catches that class of typo. If you change a property
/// name, encoding strategy, or top-level shape, update the literal below in
/// the same change.
@Suite("Movie wire-shape (ADR-011)")
struct MovieWireShapeTests {

    @Test func encodingMatchesPinnedFixture() throws {
        let movies = [
            Movie(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "The Matrix",
                year: 1999,
                watched: false,
                addedAt: Date(timeIntervalSince1970: 1_234_567_890)
            ),
            Movie(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                title: "Blade Runner",
                year: 1982,
                watched: true,
                addedAt: Date(timeIntervalSince1970: 1_234_567_891)
            ),
        ]

        let data = try MoviePersistenceCoding.encoder.encode(movies)
        let actual = String(data: data, encoding: .utf8)!

        let expected = """
        [
          {
            "addedAt" : "2009-02-13T23:31:30Z",
            "id" : "11111111-1111-1111-1111-111111111111",
            "title" : "The Matrix",
            "watched" : false,
            "year" : 1999
          },
          {
            "addedAt" : "2009-02-13T23:31:31Z",
            "id" : "22222222-2222-2222-2222-222222222222",
            "title" : "Blade Runner",
            "watched" : true,
            "year" : 1982
          }
        ]
        """

        #expect(actual == expected)
    }

    @Test func decodingAcceptsPinnedFixture() throws {
        let fixture = """
        [
          {
            "addedAt" : "2009-02-13T23:31:30Z",
            "id" : "11111111-1111-1111-1111-111111111111",
            "title" : "The Matrix",
            "watched" : false,
            "year" : 1999
          }
        ]
        """
        let data = fixture.data(using: .utf8)!
        let decoded = try MoviePersistenceCoding.decoder.decode([Movie].self, from: data)
        #expect(decoded.count == 1)
        let movie = try #require(decoded.first)
        #expect(movie.id == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        #expect(movie.title == "The Matrix")
        #expect(movie.year == 1999)
        #expect(movie.watched == false)
        #expect(movie.addedAt == Date(timeIntervalSince1970: 1_234_567_890))
    }
}
