#!/usr/bin/env bash
# RTK Claude Code hook — rewrites Bash commands through RTK for token savings.
# Requires: rtk >= 0.23.0, jq
#
# Exit code protocol for `rtk rewrite`:
#   0 + stdout  Rewrite found → auto-allow
#   1           No RTK equivalent → pass through unchanged
#   2           Deny rule matched → pass through
#   3 + stdout  Ask rule matched → rewrite but prompt user

if ! command -v jq &>/dev/null; then
  exit 0
fi

if ! command -v rtk &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

REWRITTEN=$(rtk rewrite "$CMD" 2>/dev/null)
EXIT_CODE=$?

case $EXIT_CODE in
  0)
    [ "$CMD" = "$REWRITTEN" ] && exit 0
    ;;
  1|2|*)
    [ "$EXIT_CODE" -ne 3 ] && exit 0
    ;;
  3)
    ;;
esac

ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$REWRITTEN" '.command = $cmd')

if [ "$EXIT_CODE" -eq 3 ]; then
  jq -n \
    --argjson updated "$UPDATED_INPUT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "updatedInput": $updated
      }
    }'
else
  jq -n \
    --argjson updated "$UPDATED_INPUT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason": "RTK auto-rewrite",
        "updatedInput": $updated
      }
    }'
fi
