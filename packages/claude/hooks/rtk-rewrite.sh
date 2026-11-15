#!/usr/bin/env bash
# RTK Claude Code hook — rewrites Bash commands through RTK for token savings.
# Requires: rtk >= 0.23.0, jq
#
# RTK returns rewrites on exit 0 or 3. Claude Code decides whether to run them.

if ! command -v jq &>/dev/null; then
  exit 0
fi

if ! command -v rtk &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
if ! CMD=$(jq -ers '
  select(length == 1) | .[0].tool_input.command
  | select(type == "string")
  | select(test("\\S") and (contains("\u0000") | not))
' <<<"$INPUT" 2>/dev/null); then
  exit 0
fi

# Keep the rewriter on its default approval path regardless of the shell environment.
REWRITE_STATUS=0
REWRITTEN=$(env -u RTK_REWRITE_HOST rtk rewrite -- "$CMD" 2>/dev/null) || REWRITE_STATUS=$?
case "$REWRITE_STATUS" in
  0|3)
    ;;
  *)
    exit 0
    ;;
esac

if [[ "$CMD" == "$REWRITTEN" || ! "$REWRITTEN" =~ [^[:space:]] ]]; then
  exit 0
fi

jq -c --arg cmd "$REWRITTEN" '.tool_input.command = $cmd | {
  hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: .tool_input}
}' <<<"$INPUT"
