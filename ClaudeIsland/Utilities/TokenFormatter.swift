//
//  TokenFormatter.swift
//  ClaudeIsland
//
//  Formats token counts for compact display (e.g., "12.5K", "1.5M")
//

import Foundation

enum TokenFormatter {
    static func format(_ count: Int) -> String {
        if count < 1_000 {
            return "\(count)"
        }
        if count < 1_000_000 {
            let k = Double(count) / 1_000.0
            return k < 10 ? String(format: "%.1fK", k) : String(format: "%.0fK", k)
        }
        let m = Double(count) / 1_000_000.0
        return m < 10 ? String(format: "%.1fM", m) : String(format: "%.0fM", m)
    }
}
