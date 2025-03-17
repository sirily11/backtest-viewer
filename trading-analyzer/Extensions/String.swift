import Foundation

extension String {
    /// Removes ANSI color codes from a string
    /// - Returns: A string with all ANSI color codes removed
    func removeANSIColorCodes() -> String {
        // ANSI color codes typically follow the pattern: ESC[<code>m
        // Where ESC is the escape character (ASCII 27, or \u{001B})
        // This regex matches all ANSI color code sequences
        let pattern = "\u{001B}\\[[0-9;]+m"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: self.utf16.count)
            return regex.stringByReplacingMatches(
                in: self, options: [], range: range, withTemplate: "")
        }

        return self
    }

    /// Removes leading and trailing whitespace from a string
    /// - Returns: A string with leading and trailing whitespace removed
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
