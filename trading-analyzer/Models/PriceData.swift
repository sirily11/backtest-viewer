//
//  PriceData.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/13/25.
//
import Foundation

enum PriceOrTrade {
    case price(price: PriceData)
    case trade(trade: PositionTradeData)

    var price: PriceData? {
        switch self {
        case .price(let price):
            return price
        default:
            return nil
        }
    }

    var trade: PositionTradeData? {
        switch self {
        case .trade(let trade):
            return trade
        default:
            return nil
        }
    }
}

struct PriceData: Identifiable {
    let id = UUID()
    let timeSecond: Date
    let avgPriceInSol: Double
    let transactionCount: Int
    let minPriceInSol: Double
    let maxPriceInSol: Double
}

enum PriceDataInterval: String, CaseIterable {
    case oneSecond
    case fifteenSeconds
    case oneMinute
    case fiveMinutes

    var displayName: String {
        switch self {
        case .oneSecond:
            return "1s"
        case .fifteenSeconds:
            return "15s"
        case .oneMinute:
            return "1m"
        case .fiveMinutes:
            return "5m"
        }
    }

    static func initFromDateRange(from startDate: Date, to endDate: Date) -> PriceDataInterval {
        // Calculate the time difference between dates in seconds
        let timeInterval = endDate.timeIntervalSince(startDate)

        // Choose the appropriate interval based on the time span
        if timeInterval <= 300 { // 5 minutes or less
            return .oneSecond
        } else if timeInterval <= 3600 { // 1 hour or less
            return .fifteenSeconds
        } else if timeInterval <= 86400 { // 1 day or less
            return .oneMinute
        } else {
            return .fiveMinutes
        }
    }

    var sql: String {
        switch self {
        case .oneSecond:
            return "second"
        case .fifteenSeconds:
            // DuckDB doesn't have a 15-second interval for date_trunc
            return "second"
        case .oneMinute:
            return "minute"
        case .fiveMinutes:
            // DuckDB doesn't have a 5-minute interval for date_trunc
            return "minute"
        }
    }

    // For intervals that need manual grouping beyond what date_trunc supports
    var needsCustomGrouping: Bool {
        switch self {
        case .fifteenSeconds, .fiveMinutes:
            return true
        default:
            return false
        }
    }

    var secondsMultiplier: Int {
        switch self {
        case .fifteenSeconds:
            return 15
        case .fiveMinutes:
            return 300
        default:
            return 1
        }
    }
}
