import Foundation

/// Canonical `JSONEncoder` / `JSONDecoder` pair for the on-disk `[Movie]`
/// wire shape. Both `JSONFileMoviesPersistence` (production) and the
/// fixture-lock test (`MovieWireShapeTests`) read from here so the wire shape
/// has one source of truth — see ADR-011.
public enum MoviePersistenceCoding {
    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
