---
name: fastmail-email
description: Use the configured Fastmail MCP server for the user's email requests, including finding and reading messages, composing drafts, replying, and organizing mail. Covers Markdown and plain-text composition and verification of rich-text email. Use another provider or client when the user explicitly requests it.
---

# Fastmail email

Use the configured `fastmail` MCP server as the default for work with the user's
mailbox. Use another provider or client only when the user explicitly requests
it. A request for a draft means save a draft; send only when the user's
instructions authorize sending.

Read the current draft before replacing it so that user edits, recipients,
sender identity, attachments, and reply/threading context are preserved. When
recovering from an uncertain create response, locate the result before retrying
to avoid duplicate drafts.

## Body format

- For rich-text drafts, pass Markdown directly in `draft_email.body`; omit
  `format` or set `format: "markdown"`. The server generates HTML and keeps the
  original Markdown as the plain-text alternative.
- For intentionally plain-text-only email, set `format: "text"` and use readable
  plain text with ordinary URLs rather than Markdown link syntax.
- The old HTML-in-`body` workaround is unnecessary. Raw HTML also remains in the
  plain-text alternative, exposing tags to clients that display that part.
- For replies, set `mode: "reply"` and `emailId` and supply only the new text in
  `body`; the server adds quoting and reply headers automatically.
- Keep draft creation in Fastmail MCP; use browser automation or the web
  composer only when the user specifically requests it.

Read the saved draft through MCP to confirm recipients, subject, content, and
Drafts status. `read_email.bodyText` can contain literal Markdown even when
conversion succeeds, because the plain-text alternative retains the input.
When investigating formatting, inspect stored HTML or raw MIME through an
available API or mail client: confirm both the `text/html` part and the expected
rendered markup. A successful save or `bodyText` alone does not verify HTML
conversion. If source inspection is unavailable, state that verification limit.

### Fix verified 2026-10-21

The Markdown-to-HTML bug observed on 2026-09-18 is fixed on the configured
official server at `https://api.fastmail.com/mcp`. Saved MIME inspected through
Apple Mail confirmed that default and explicit Markdown drafts contain
`multipart/alternative` with rendered HTML and the original Markdown as plain
text. Links, nested lists, emphasis, code, and escaped characters converted
correctly. `format: "text"` produced plain-text-only drafts. Markdown and text
reply drafts preserved their respective formats, quoting, and reply headers.
These checks covered saved drafts, not message delivery.

## When the configured MCP tools are not exposed

Check the `mcp_servers.fastmail` entry in `$CODEX_HOME/config.toml` (normally
`~/.codex/config.toml`).
The local configuration uses `https://api.fastmail.com/mcp` with an
`http_headers_helper`. If necessary, call the configured server directly using
the helper's headers and the MCP initialization handshake, then `tools/list`
and `tools/call`. Treat current schemas as authoritative for accepted arguments.

Capture authentication-helper output privately in process memory. Do not print
credentials, put them in command arguments, or save them in artifacts. Preserve
the server's session headers when required. Failure to expose a connector in
the current tool list does not mean the configured server is unavailable.

The configured MCP token can reject `https://api.fastmail.com/jmap/session` with
HTTP 401, `JMAP request for session without JMAP enabled`. Do not broaden token
scopes or create credentials merely to inspect formatting.
