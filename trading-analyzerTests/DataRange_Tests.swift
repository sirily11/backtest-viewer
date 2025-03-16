//
//  trading_analyzerTests.swift
//  trading-analyzerTests
//
//  Created by Qiwei Li on 3/12/25.
//

import Foundation
import Testing
@testable import trading_analyzer

struct DataRangeTests {
    @Test func zoomIn() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let dateRange = formatter.date(from: "2022/01/02 00:00")! ... formatter.date(from: "2022/01/02 00:01")!

        let newRange = dateRange.scale(to: 0.8)
        let diff = newRange.upperBound.timeIntervalSince(newRange.lowerBound)
        #expect(diff == 48)
    }

    @Test func zoomOut() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let dateRange = formatter.date(from: "2022/01/02 00:00")! ... formatter.date(from: "2022/01/02 00:01")!

        let newRange = dateRange.scale(to: 1.2)
        let diff = newRange.upperBound.timeIntervalSince(newRange.lowerBound)
        #expect(diff == 72)
    }
}
