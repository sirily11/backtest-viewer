import Foundation

enum TradeStatsError: Error {
    case fileNotFound
    case parsingError(String)
}

class TradeStatsService {
    static func loadTradeStats(from url: URL) async throws -> TradeStats {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let stats = try decoder.decode(TradeStats.self, from: data)
                continuation.resume(returning: stats)
            } catch {
                continuation.resume(
                    throwing: TradeStatsError.parsingError(error.localizedDescription))
            }
        }
    }
}
