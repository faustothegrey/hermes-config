---
name: social-platform-operations
description: "Operate social/messaging platform integrations such as X/Twitter and Yuanbao groups with posting, search, DMs, mentions, and media."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [social-media, x, twitter, yuanbao, messaging, groups]
---

# Social Platform Operations

Use this class-level skill for platform-specific social and group operations: X/Twitter via CLI/API and Yuanbao group interactions.

## General rules

- Posting, replying, DMing, deleting, following, and mentioning are external side effects. Resolve target/account/thread first.
- For public posts, preserve the user's wording unless asked to rewrite.
- For media uploads, verify file existence and platform size/format constraints.
- After posting or sending, report concrete IDs/URLs or platform confirmation when available.

## X / Twitter

Use the configured X API CLI workflow for posting, replying, quote posting, deleting posts, searching, timelines/mentions, likes/reposts/bookmarks, follows/blocks/mutes, DMs, media upload, and raw v2 API access.

## Yuanbao groups

For Yuanbao group chats, the final assistant text is the delivered message. Include `@nickname` in the final text when the user wants a real mention; the gateway resolves it. Do not claim inability to message when the conversation is already in Yuanbao context.

## Verification

Prefer direct API/CLI readback for posts, messages, or group/member lookups. If a platform tool reports failure, do not synthesize success.
