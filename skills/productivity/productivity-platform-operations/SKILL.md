---
name: productivity-platform-operations
description: "Productivity integrations: Google Workspace, Airtable, Notion, PDFs/OCR, PowerPoint, maps, email, Obsidian, and Teams pipelines."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [productivity, google-workspace, airtable, notion, pdf, powerpoint, email, notes, teams]
---

# Productivity Platform Operations

Use this class-level skill for user productivity systems: Google Workspace, Airtable, Notion, PDFs/OCR, PowerPoint, maps/geocoding, email, Obsidian vaults, and Teams meeting pipelines.

## Platform selection

| Task | Preferred workflow |
|---|---|
| Gmail/Calendar/Drive/Docs/Sheets | Google Workspace CLI/API workflow |
| IMAP/SMTP email | Himalaya CLI workflow |
| Structured records/tables | Airtable REST API |
| Knowledge pages/databases | Notion CLI/API |
| Local markdown knowledge base | Obsidian filesystem workflow |
| PDF/scanned document extraction | OCR/document extraction tools |
| PDF typo/title edits | nano-pdf |
| PPTX create/read/edit | PowerPoint tooling |
| Geocoding/routes/POIs/time zones | Maps/OpenStreetMap/OSRM workflow |
| Teams transcript/action summary ops | Teams meeting pipeline CLI |

## General rules

- Resolve credentials and target workspace/account before mutating anything.
- Prefer read-only discovery before writes.
- Treat sending email, modifying calendars, editing databases, and posting pages as external side effects.
- Verify by reading back the created/modified resource when possible.

## Google Workspace

Use for Gmail, Calendar, Drive, Docs, and Sheets. Prefer the configured Google Workspace CLI or Python client. Confirm account, document IDs, sheet names, calendar, and sharing settings before changes.

For Gmail access checks, do not stop at “account/token file exists”. Verify usable OAuth with a real Gmail API call. Check `~/.hermes/google_token.json` metadata safely, try token refresh, then call `gmail.users().getProfile(userId='me')` or list one inbox message. If refresh returns `invalid_grant` / `Token has been expired or revoked`, report that OAuth was configured but must be re-authorized. See `references/google-gmail-oauth-diagnostics.md`.

## Email via Himalaya

Use Himalaya for terminal IMAP/SMTP: search/read mail, draft/send messages, and manage folders. Confirm recipients and final body before sending sensitive mail.

## Airtable and Notion

Use Airtable for structured record CRUD and filtering. Use Notion for pages, databases, block content, markdown import/export, and Notion Workers when available.

## Documents: PDF, OCR, PowerPoint

- For remote PDFs, try web extraction first.
- For scanned PDFs/images, use OCR/document extraction.
- For PDF text edits, use nano-pdf and verify the edited page.
- For PPTX, use PowerPoint-specific tooling for slides, notes, layouts, comments, and thumbnails.

## Maps/location intelligence

Use open data sources for geocoding, nearby POIs, routes, distances, and time zones. When user sends a location pin, preserve lat/lon precision and clarify radius/category only if not inferable.

## Obsidian

Use filesystem-first markdown operations. Resolve the vault path from `OBSIDIAN_VAULT_PATH` or a known default. Avoid passing unexpanded shell variables to file tools.

## Teams meeting pipeline

Operate via `hermes teams-pipeline` subcommands for meeting summaries, transcripts, recordings, action items, Graph subscriptions, job replay, and pipeline status.
