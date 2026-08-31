---
name: fastmail-email
description: Use the configured Fastmail MCP server for the user's email requests, including finding and reading messages, composing drafts, replying, and organizing mail. Covers the observed Markdown-to-HTML draft bug and verification of rich-text email. Use another provider or client when the user explicitly requests it.
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

## Formatting bug observed 2026-09-18

The official server at `https://api.fastmail.com/mcp` advertised this
`draft_email.inputSchema.properties.body.description`:

> Email body in markdown format. Converted to HTML automatically with the markdown kept as plain text alternative.

A draft created through `tools/call` with `name: draft_email` instead contained
only `Content-Type: text/plain; charset=utf-8` with literal Markdown. Both Apple
Mail and Fastmail web showed raw Markdown links and bullets. The supplied raw
MIME had no HTML part and no `multipart/alternative`. This is an observed server
behavior on that date, not a claim that all deployments or future versions are
affected.

- For plain-text email, use readable plain text with ordinary URLs rather than
  Markdown link syntax.
- For rich-text drafts, pass actual HTML directly in `draft_email.body`, even
  though its description advertises Markdown. Use `<p>` for paragraphs,
  `<ul>` and `<li>` for lists, and `<a href="...">` for links. Escape text and
  attribute values appropriately. Do not submit Markdown and rely on automatic
  conversion.
- Do not use browser automation or the Fastmail web composer as a formatting
  workaround unless the user specifically requests it. Otherwise, keep draft
  creation in Fastmail MCP.
- Read the saved draft through MCP to confirm recipients, subject, content, and
  Drafts status. Inspect stored HTML or raw MIME through an available API when
  possible; a `text/html` part is evidence of HTML output. `read_email.bodyText`
  or a successful save alone does not verify rich-text rendering. If HTML
  verification is unavailable, state that limit; switch to a browser only if the
  user specifically requests it.
- If a newer server fixes the issue, update this dated guidance from verified
  evidence rather than retaining an unnecessary workaround.

The observed MCP schema had no separate HTML-body parameter. Passing HTML in
`body` is the requested approach, but was not verified by the original Markdown
reproduction. Do not describe it as a confirmed server fix without checking the
saved result. The configured MCP token also returned HTTP 401,
`JMAP request for session without JMAP enabled`, at
`https://api.fastmail.com/jmap/session`. Do not broaden token scopes or create
credentials merely to work around this bug.

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
