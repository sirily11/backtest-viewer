//
//  PositionData.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import Foundation

struct PositionData: Identifiable {
    let id = UUID()
    let marketId: String
    let pnlRatio: Int
    let pnl: Int
    let cost: Int
    let isMarketLaunched: Bool
    let maxProfitRatio: Int
    let maxProfit: Int
    let maxLossRatio: Int
    let maxLoss: Int
    let createTime: Date
    let updateTime: Date

    init(
        marketId: String, pnlRatio: Int, pnl: Int, cost: Int, isMarketLaunched: Bool,
        maxProfitRatio: Int, maxProfit: Int, maxLossRatio: Int, maxLoss: Int, createTime: String,
        updateTime: String
    ) {
        self.marketId = marketId
        self.pnlRatio = pnlRatio
        self.pnl = pnl
        self.cost = cost
        self.isMarketLaunched = isMarketLaunched
        self.maxProfitRatio = maxProfitRatio
        self.maxProfit = maxProfit
        self.maxLossRatio = maxLossRatio
        self.maxLoss = maxLoss

        let dateFormatter = ISO8601DateFormatter()
        self.createTime = dateFormatter.date(from: createTime) ?? Date()
        self.updateTime = dateFormatter.date(from: updateTime) ?? Date()
    }
}
