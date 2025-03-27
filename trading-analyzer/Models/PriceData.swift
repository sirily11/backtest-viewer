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

    var time: Date {
        switch self {
        case .trade(let trade):
            return trade.confirmTime
        case .price(let price):
            return price.timeSecond
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
    case oneMinute
    case oneHour

    var displayName: String {
        switch self {
        case .oneSecond:
            return "1s"
        case .oneMinute:
            return "1m"
        case .oneHour:
            return "1h"
        }
    }

    static func initFromScale(scale: Double) -> PriceDataInterval {
        if scale < 10 {
            return .oneSecond
        } else if scale < 40 {
            return .oneMinute
        } else {
            return .oneHour
        }
    }

    static func initFromDataCount(count: Int) -> PriceDataInterval {
        if count < 360 {
            return .oneSecond
        } else if count < 21600 {
            return .oneMinute
        } else {
            return .oneHour
        }
    }

    var sql: String {
        switch self {
        case .oneSecond:
            return "second"
        case .oneMinute:
            // DuckDB doesn't have a 15-second interval for date_trunc
            return "minute"
        case .oneHour:
            return "hour"
        }
    }

    // For intervals that need manual grouping beyond what date_trunc supports
    var needsCustomGrouping: Bool {
        switch self {
        default:
            return false
        }
    }

    var secondsMultiplier: Int {
        switch self {
        default:
            return 1
        }
    }
}
