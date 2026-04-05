//
//  RateLimitReader.swift
//  ClaudeIsland
//
//  Reads rate limit data written by the statusline script
//

import Foundation

struct RateLimitData: Equatable, Sendable {
    let sessionUsedPercentage: Double?
    let sessionResetsAt: Date?
    let weeklyUsedPercentage: Double?
    let weeklyResetsAt: Date?
    let updatedAt: Date?

    var hasData: Bool {
        sessionUsedPercentage != nil || weeklyUsedPercentage != nil
    }

    var sessionResetText: String? {
        guard let resets = sessionResetsAt else { return nil }
        let remaining = resets.timeIntervalSinceNow
        if remaining <= 0 { return "resetting" }
        let hours = Int(remaining / 3600)
        let mins = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "resets in \(hours)h \(mins)m" }
        return "resets in \(mins)m"
    }

    var weeklyResetText: String? {
        guard let resets = weeklyResetsAt else { return nil }
        let remaining = resets.timeIntervalSinceNow
        if remaining <= 0 { return "resetting" }
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        if days > 0 { return "resets in \(days)d \(hours)h" }
        return "resets in \(hours)h"
    }
}

enum RateLimitReader {
    private static let filePath = "/tmp/claude-island-ratelimits.json"

    static func read() -> RateLimitData? {
        guard let data = FileManager.default.contents(atPath: filePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Check freshness — ignore data older than 10 minutes
        if let updatedAt = json["updated_at"] as? Double {
            let age = Date().timeIntervalSince1970 - updatedAt
            if age > 600 { return nil }
        }

        let fiveHour = json["five_hour"] as? [String: Any]
        let sevenDay = json["seven_day"] as? [String: Any]

        let sessionPct = fiveHour?["used_percentage"] as? Double
        let sessionResets: Date? = {
            guard let ts = fiveHour?["resets_at"] as? Double else { return nil }
            return Date(timeIntervalSince1970: ts)
        }()

        let weeklyPct = sevenDay?["used_percentage"] as? Double
        let weeklyResets: Date? = {
            guard let ts = sevenDay?["resets_at"] as? Double else { return nil }
            return Date(timeIntervalSince1970: ts)
        }()

        let updatedAt: Date? = {
            guard let ts = json["updated_at"] as? Double else { return nil }
            return Date(timeIntervalSince1970: ts)
        }()

        let result = RateLimitData(
            sessionUsedPercentage: sessionPct,
            sessionResetsAt: sessionResets,
            weeklyUsedPercentage: weeklyPct,
            weeklyResetsAt: weeklyResets,
            updatedAt: updatedAt
        )

        return result.hasData ? result : nil
    }
}
