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

    init(database: Database?, connection: Connection?) {
        self.database = database
        self.connection = connection
    }

    func initDatabase() throws {
        // Create our database and connection as described above
        let database = try Database(store: .inMemory)
        let connection = try database.connect()

        self.database = database
        self.connection = connection
    }

    func loadDataset(filePath: URL) async throws {
        self.currentDataset = filePath
    }

    func fetchPriceData(forMarketId marketId: String, startDate: Foundation.Date, endDate: Foundation.Date) async throws
        -> DataFrame
    {
        guard let connection = connection else {
            throw DuckDBError.connectionError
        }

        guard let dataset = currentDataset else {
            throw DuckDBError.missingDataset
        }

        let query = """
        SELECT
            date_trunc('second', block_time) AS time_second,
            AVG(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS avg_price_in_sol,
            COUNT(*) AS transaction_count,
            MIN(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS min_price_in_sol,
            MAX(quote_amount::numeric / NULLIF(base_amount, 0)::numeric) AS max_price_in_sol
        FROM read_parquet(\(dataset.path))
        WHERE base_address = $1
            AND block_time >= $2
            AND block_time < $3
        GROUP BY date_trunc('second', block_time)
        ORDER BY time_second
        """

        let result = try connection.query(query)

        let secondColumn = result[0].cast(to: Int.self)
        let avgPriceColumn = result[1].cast(to: Double.self)
        let transactionCountColumn = result[2].cast(to: Int.self)
        let minPriceColumn = result[3].cast(to: Double.self)
        let maxPriceColumn = result[4].cast(to: Double.self)

        return DataFrame(
            columns: [
                TabularData.Column(secondColumn).eraseToAnyColumn(),
                TabularData.Column(avgPriceColumn).eraseToAnyColumn(),
                TabularData.Column(transactionCountColumn).eraseToAnyColumn(),
                TabularData.Column(minPriceColumn).eraseToAnyColumn(),
                TabularData.Column(maxPriceColumn).eraseToAnyColumn()
            ]
        )
    }
}
