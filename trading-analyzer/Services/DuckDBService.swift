//
//  DuckDBService.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/13/25.
//

import DuckDB
import Foundation
import SwiftUI
import TabularData

typealias FoundationDate = Foundation.Date

enum DuckDBError: LocalizedError {
    case connectionError
    case missingDataset

    var errorDescription: String? {
        switch self {
        case .connectionError:
            return "Connection to the database is not established"
        case .missingDataset:
            return "No dataset is loaded"
        }
    }
}

@Observable
class DuckDBService {
    var database: Database?
    var connection: Connection?
    private var currentDataset: URL?

    func initDatabase() throws {
        // Create our database and connection as described above
        let database = try Database(store: .inMemory)
        let connection = try database.connect()

        self.database = database
        self.connection = connection
    }

    func loadDataset(filePath: URL) async throws {
        // check if file exist
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath.path) else {
            throw DuckDBError.missingDataset
        }
        self.currentDataset = filePath
    }

    @MainActor
    func fetchPriceData(forMarketId marketId: String, start: FoundationDate, end: FoundationDate, interval: PriceDataInterval) async throws
        -> [PriceData]
    {
        guard let connection = connection else {
            throw DuckDBError.connectionError
        }

        guard let dataset = currentDataset else {
            throw DuckDBError.missingDataset
        }

        let iSO8601DateFormatter = ISO8601DateFormatter()

        // Calculate the duration between start and end
        let durationSeconds = end.timeIntervalSince(start)
        let minDurationSeconds: TimeInterval = 10 * 60 // 10 minutes in seconds

        // If the duration is less than 10 minutes, expand it equally on both sides
        var adjustedStart = start
        var adjustedEnd = end

        if durationSeconds < minDurationSeconds {
            let additionalTimeNeeded = minDurationSeconds - durationSeconds
            let additionalTimePerSide = additionalTimeNeeded / 2

            adjustedStart = start.addingTimeInterval(-additionalTimePerSide)
            adjustedEnd = end.addingTimeInterval(additionalTimePerSide)
        }

        let startString = iSO8601DateFormatter.string(from: adjustedStart)
        let endString = iSO8601DateFormatter.string(from: adjustedEnd)
        var query = ""

        if interval.needsCustomGrouping {
            // For 15-second and 5-minute intervals, we need custom grouping
            query = """
            SELECT
                CAST(date_trunc('\(interval.sql)', block_time) AS VARCHAR) || 
                    CAST((EXTRACT(SECOND FROM block_time) / \(interval.secondsMultiplier)) * \(interval.secondsMultiplier) AS VARCHAR) AS time_interval,
                AVG(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS avg_price_in_sol,
                COUNT(*) AS transaction_count,
                MIN(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS min_price_in_sol,
                MAX(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS max_price_in_sol
            FROM read_parquet('\(dataset.path)')
            WHERE base_address = '\(marketId)'
            AND block_time BETWEEN '\(startString)' AND '\(endString)'
            GROUP BY date_trunc('\(interval.sql)', block_time), (EXTRACT(SECOND FROM block_time) / \(interval.secondsMultiplier)) * \(interval.secondsMultiplier)
            ORDER BY time_interval
            """
        } else {
            // For 1-second and 1-minute intervals, we can use simple date_trunc
            query = """
            SELECT
                CAST(date_trunc('\(interval.sql)', block_time) AS VARCHAR) AS time_interval,
                AVG(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS avg_price_in_sol,
                COUNT(*) AS transaction_count,
                MIN(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS min_price_in_sol,
                MAX(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS max_price_in_sol
            FROM read_parquet('\(dataset.path)')
            WHERE base_address = '\(marketId)'
            AND block_time BETWEEN '\(startString)' AND '\(endString)'
            GROUP BY date_trunc('\(interval.sql)', block_time)
            ORDER BY time_interval
            """
        }
        let result = try connection.query(query)
        let secondColumn = result[0].cast(to: String.self)
        let avgPriceColumn = result[1].cast(to: Double.self)
        let transactionCountColumn = result[2].cast(to: Int.self)
        let minPriceColumn = result[3].cast(to: Double.self)
        let maxPriceColumn = result[4].cast(to: Double.self)

        let dataFrame = DataFrame(
            columns: [
                TabularData.Column(secondColumn).eraseToAnyColumn(),
                TabularData.Column(avgPriceColumn).eraseToAnyColumn(),
                TabularData.Column(transactionCountColumn).eraseToAnyColumn(),
                TabularData.Column(minPriceColumn).eraseToAnyColumn(),
                TabularData.Column(maxPriceColumn).eraseToAnyColumn()
            ]
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Adjust format to match your data

        let priceData = dataFrame.rows.map { row in
            let time = row[0, String.self]

            // Create a date formatter for parsing the input time
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Adjust this to match your input format
            inputFormatter.timeZone = TimeZone(identifier: "UTC") // Assuming original time is in UTC

            // Parse the date in the original timezone
            let utcDate = inputFormatter.date(from: time ?? "") ?? Date()

            // Convert to user's local timezone
            let localDate = utcDate // The Date object remains the same, but will display in local time when formatted

            return PriceData(
                timeSecond: localDate,
                avgPriceInSol: row[1, Double.self] ?? 0.0,
                transactionCount: row[2, Int.self] ?? 0,
                minPriceInSol: row[3, Double.self] ?? 0,
                maxPriceInSol: row[4, Double.self] ?? 0
            )
        }
        return priceData
    }
}
