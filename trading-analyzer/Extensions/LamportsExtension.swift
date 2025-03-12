//
//  LamportsExtension.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import Foundation

/// Extension to convert between Solana lamports and SOL
extension Double {
    /// Converts lamports to SOL (1 SOL = 1,000,000,000 lamports)
    /// - Returns: The equivalent value in SOL
    func lamportsToSol() -> Double {
        return self / 1_000_000_000.0
    }

    /// Formats the SOL value with appropriate decimal places and SOL symbol
    /// - Parameter maximumFractionDigits: Maximum number of decimal places to show (default: 5)
    /// - Returns: Formatted string representation of the SOL value
    func formattedSol(maximumFractionDigits: Int = 5) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 2

        if let formattedValue = formatter.string(from: NSNumber(value: self)) {
            return "\(formattedValue) SOL"
        }

        return "\(self) SOL"
    }
}

/// Extension to convert between Solana lamports and SOL for Int values
extension Int {
    /// Converts lamports to SOL (1 SOL = 1,000,000,000 lamports)
    /// - Returns: The equivalent value in SOL
    func lamportsToSol() -> Double {
        return Double(self) / 1_000_000_000.0
    }

    /// Formats the SOL value with appropriate decimal places and SOL symbol
    /// - Parameter maximumFractionDigits: Maximum number of decimal places to show (default: 5)
    /// - Returns: Formatted string representation of the SOL value
    func formattedSol(maximumFractionDigits: Int = 5) -> String {
        return self.lamportsToSol().formattedSol(maximumFractionDigits: maximumFractionDigits)
    }
}
