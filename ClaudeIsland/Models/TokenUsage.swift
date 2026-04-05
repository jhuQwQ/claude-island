//
//  TokenUsage.swift
//  ClaudeIsland
//
//  Token usage tracking from Claude API responses
//

import Foundation

/// Accumulated token usage for a session, parsed from JSONL `message.usage` fields
struct TokenUsage: Equatable, Sendable {
    var inputTokens: Int = 0
    var cacheCreationInputTokens: Int = 0
    var cacheReadInputTokens: Int = 0
    var outputTokens: Int = 0

    var totalInputTokens: Int {
        inputTokens + cacheCreationInputTokens + cacheReadInputTokens
    }

    var totalTokens: Int { totalInputTokens + outputTokens }
    var isEmpty: Bool { totalTokens == 0 }

    mutating func accumulate(_ other: TokenUsage) {
        inputTokens += other.inputTokens
        cacheCreationInputTokens += other.cacheCreationInputTokens
        cacheReadInputTokens += other.cacheReadInputTokens
        outputTokens += other.outputTokens
    }
}
