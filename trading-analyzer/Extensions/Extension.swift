//
//  Extension.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/16/25.
//

import Foundation

extension ClosedRange where Bound == Date {
    func scale(to: Double) -> ClosedRange<Date> {
        let start = self.lowerBound
        let end = self.upperBound

        let interval = end.timeIntervalSince(start)
        let scaledInterval = interval * to
        let scaledStart = start.addingTimeInterval((interval - scaledInterval) / 2)
        let scaledEnd = end.addingTimeInterval(-(interval - scaledInterval) / 2)

        return scaledStart ... scaledEnd
    }
}
