//
//  PriceData.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/13/25.
//
import Foundation

struct PriceData: Identifiable {
    let id = UUID()
    let timeSecond: Date
    let avgPriceInSol: Double
    let transactionCount: Int
    let minPriceInSol: Double
    let maxPriceInSol: Double
}
