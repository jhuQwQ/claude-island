#!/bin/bash
# Claude Island statusline script
# Extracts rate limit data from Claude Code and writes to a shared file
# so Claude Island can display actual usage percentages.

input=$(cat)

# Write rate limits to shared file for Claude Island to read
RATE_FILE="/tmp/claude-island-ratelimits.json"
echo "$input" | jq -c '{
  five_hour: {
    used_percentage: (.rate_limits.five_hour.used_percentage // null),
    resets_at: (.rate_limits.five_hour.resets_at // null)
  },
  seven_day: {
    used_percentage: (.rate_limits.seven_day.used_percentage // null),
    resets_at: (.rate_limits.seven_day.resets_at // null)
  },
  session_id: (.session_id // null),
  updated_at: now
}' > "$RATE_FILE" 2>/dev/null
