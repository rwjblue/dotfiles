---
name: copy-for-slack
description: Convert a message from standard Markdown to Slack's mrkdwn formatting and copy it to the clipboard, ready to paste into Slack. Trigger phrases "copy for slack", "/copy-for-slack", "format this for slack", "slackify this", "make this slack-ready", "copy that to slack", "give me a slack version".
---

# Copy for Slack

Take a message (usually one just drafted in the conversation) and rewrite it in Slack's
`mrkdwn` dialect, then put it on the clipboard so the user can paste it straight into
the Slack composer.

Slack is **not** standard Markdown. Pasting GitHub-flavored Markdown into Slack renders
`**bold**` as literal asterisks, drops headings, and mangles tables. This skill fixes
that.

## 1. Pick the source text

In priority order:

1. Text the user passed as an argument / quoted in their request.
2. The specific message they point at ("copy the message above", "the draft you just wrote").
3. Otherwise, the most recent substantive message you produced.

If it's ambiguous which message they mean, ask before copying.

## 2. Convert Markdown → Slack mrkdwn

Apply every rule that's relevant. The first three are the ones that bite most often.

| Markdown | Slack mrkdwn | Notes |
| --- | --- | --- |
| `**bold**` / `__bold__` | `*bold*` | Single asterisks. The #1 gotcha. |
| `*italic*` / `_italic_` | `_italic_` | Underscores only. |
| `~~strike~~` | `~strike~` | Single tildes. |
| `` `code` `` | `` `code` `` | Unchanged. |
| ` ```lang ` fenced block | ` ``` ` fenced block | Drop the language label — Slack shows it as literal text. Keep the triple backticks. |
| `# H1` / `## H2` … | `*Heading*` on its own line | Slack has no headings. Bold the text; keep a blank line after. |
| `[text](url)` | `[text](url)` | Keep Markdown-style links — Slack's composer auto-links them on paste. (For API/incoming-webhook payloads use `<url|text>` instead; ask if unsure which target.) |
| Bare `https://…` | leave as-is | Slack auto-links bare URLs. |
| `- item` / `1. item` | `- item` / `1. item` | Bullets and numbers render fine. Use `-` for bullets. |
| `> quote` | `> quote` | Supported. Use `>>>` before a multi-line block quote. |
| `---` horizontal rule | remove (blank line) | No divider in mrkdwn. |
| tables | code block or plain lines | No table support; reformat as an aligned ` ``` ` block or simple `Label: value` lines. |
| `:emoji:` | `:emoji:` | Shortcodes work. |
| `@name` you can't resolve | leave as `@name` | Only use `<@U123>` when you actually know the member ID. |

Keep the wording identical — only the formatting changes. Don't hard-wrap; let Slack reflow.

## 3. Copy to the clipboard

Write the converted text via a quoted heredoc (so backticks and `$` stay literal) into the
platform clipboard command. Use a unique delimiter that can't appear in the body.

macOS:

```bash
pbcopy <<'SLACK_MSG_EOF'
<converted slack text here>
SLACK_MSG_EOF
```

Portable (use whichever exists — macOS `pbcopy`, Linux X11 `xclip`/`xsel`, Wayland
`wl-copy`, WSL `clip.exe`):

```bash
copy_cmd=$(command -v pbcopy || command -v wl-copy || echo "xclip -selection clipboard")
$copy_cmd <<'SLACK_MSG_EOF'
<converted slack text here>
SLACK_MSG_EOF
```

If no clipboard tool is available, print the converted text in a fenced block and tell
the user to copy it manually.

## 4. Confirm

After copying, show the converted message (so the user can eyeball it) and confirm it's on
the clipboard — e.g. "Copied to clipboard (Slack-formatted)." Note any lossy conversions
you made (a table flattened to a code block, a heading turned into bold, etc.).

## Notes

- Default link style is Markdown `[text](url)` for pasting into the Slack message box. Only
  switch to `<url|text>` when the destination is the Slack API / an incoming webhook.
- Slack bold/italic/strike only render when the markers hug the text and sit on word
  boundaries (`*bold*`, not `* bold *`).
- Don't invent content or trim the message — this skill reformats, it doesn't rewrite.
