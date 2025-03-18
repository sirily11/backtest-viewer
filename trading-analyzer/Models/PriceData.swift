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

    static func initFromScale(scale: Double) -> PriceDataInterval {
        if scale < 10 {
            return .oneSecond
        } else {
            return .oneMinute
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
