//
//  WeeklyUsageTracker.swift
//  ClaudeIsland
//
//  Aggregates token usage across all sessions in the last 7 days
//

import Foundation
import os.log

actor WeeklyUsageTracker {
    static let shared = WeeklyUsageTracker()

    private static let logger = Logger(subsystem: "com.claudeisland", category: "WeeklyUsage")

    struct WeeklyUsage: Equatable, Sendable {
        let totalInputTokens: Int
        let totalOutputTokens: Int
        let totalTokens: Int
        let sessionCount: Int
    }

    private var cachedUsage: WeeklyUsage?
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 60

    func getWeeklyUsage() -> WeeklyUsage {
        if let cached = cachedUsage,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            return cached
        }

        let usage = scanWeeklyUsage()
        cachedUsage = usage
        cacheTimestamp = Date()
        return usage
    }

    private func scanWeeklyUsage() -> WeeklyUsage {
        let projectsDir = NSHomeDirectory() + "/.claude/projects"
        let fileManager = FileManager.default
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)

        var totalInput = 0
        var totalOutput = 0
        var sessionCount = 0

        guard let projectDirs = try? fileManager.contentsOfDirectory(atPath: projectsDir) else {
            return WeeklyUsage(totalInputTokens: 0, totalOutputTokens: 0, totalTokens: 0, sessionCount: 0)
        }

        for projectDir in projectDirs {
            let projectPath = projectsDir + "/" + projectDir
            guard let files = try? fileManager.contentsOfDirectory(atPath: projectPath) else { continue }

            for file in files where file.hasSuffix(".jsonl") {
                let filePath = projectPath + "/" + file

                // Skip files not modified in last 7 days
                guard let attrs = try? fileManager.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date,
                      modDate > sevenDaysAgo else { continue }

                let (input, output) = scanFileUsage(filePath: filePath, since: sevenDaysAgo)
                if input > 0 || output > 0 {
                    totalInput += input
                    totalOutput += output
                    sessionCount += 1
                }
            }
        }

        return WeeklyUsage(
            totalInputTokens: totalInput,
            totalOutputTokens: totalOutput,
            totalTokens: totalInput + totalOutput,
            sessionCount: sessionCount
        )
    }

    private func scanFileUsage(filePath: String, since: Date) -> (input: Int, output: Int) {
        guard let data = FileManager.default.contents(atPath: filePath),
              let content = String(data: data, encoding: .utf8) else {
            return (0, 0)
        }

        var totalInput = 0
        var totalOutput = 0
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for line in content.components(separatedBy: "\n") where line.contains("\"type\":\"assistant\"") {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }

            // Check timestamp
            if let timestampStr = json["timestamp"] as? String,
               let date = dateFormatter.date(from: timestampStr),
               date < since {
                continue
            }

            guard let messageDict = json["message"] as? [String: Any],
                  let usage = messageDict["usage"] as? [String: Any] else { continue }

            let input = (usage["input_tokens"] as? Int ?? 0)
                + (usage["cache_creation_input_tokens"] as? Int ?? 0)
                + (usage["cache_read_input_tokens"] as? Int ?? 0)
            let output = usage["output_tokens"] as? Int ?? 0

            totalInput += input
            totalOutput += output
        }

        return (totalInput, totalOutput)
    }
}
