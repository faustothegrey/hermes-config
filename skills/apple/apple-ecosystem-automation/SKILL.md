---
name: apple-ecosystem-automation
description: "Apple ecosystem automation: Notes, Reminders, Messages, Find My, and macOS computer-use workflows."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [apple, macos, notes, reminders, imessage, findmy, computer-use]
---

# Apple Ecosystem Automation

Use this class-level skill whenever the user asks Hermes to interact with Apple apps or a macOS desktop: Apple Notes, Reminders, Messages/iMessage, Find My, or background GUI automation.

## Preconditions

- These workflows require macOS and the relevant Apple app signed into the user's Apple/iCloud account.
- Expect first-run privacy prompts: Automation, Accessibility, Screen Recording, Contacts, Reminders, Notes, or Full Disk Access depending on the task.
- Prefer app-specific CLIs when available. Use computer-use/UI automation only when no reliable CLI exists or visual confirmation is required.

## Notes.app

Use `memo` for Apple Notes: create notes, search existing notes, and edit content that syncs through iCloud.

Typical setup:

```bash
brew tap antoniorodr/memo
brew install antoniorodr/memo/memo
memo --help
```

Use when the user asks to save, retrieve, or organize notes in Apple Notes. Confirm the target folder/account when destructive edits are involved.

## Reminders.app

Use `remindctl` for Apple Reminders: add reminders, list tasks, complete tasks, and manage lists.

Typical setup:

```bash
brew install steipete/tap/remindctl
remindctl status
remindctl authorize
```

Use Reminders for user-facing to-dos that should sync to iOS/watchOS. Use Hermes todos only for transient session work.

## Messages / iMessage

Use the configured Messages/iMessage workflow when the user asks to read or send Apple Messages. Treat sending messages as an external side effect: identify the exact contact/thread first and avoid guessing recipients.

General rules:

1. Search/resolve the contact or chat before composing.
2. Show the exact outgoing text when ambiguity or sensitivity is high.
3. After sending, verify via the CLI/app state if possible and report the concrete result.

## Find My

Find My has no stable official CLI. Use AppleScript/UI automation and screenshots to open FindMy.app and read device/AirTag locations.

Prerequisites:

- Find My app signed in and devices/AirTags registered.
- Screen Recording permission for the terminal/Hermes runtime.
- Prefer `peekaboo` or the available `computer_use` screenshot tools for visual state.

Never invent a location if the UI cannot be read; report the blocker and the permission/app state needed.

## macOS background computer use

When the `computer_use` tool is available on macOS, it can drive the desktop in the background without stealing the user's cursor, keyboard focus, or Space. Use it for GUI-only Apple workflows or verification screenshots.

Operating rules:

- Inspect before acting; never click blind.
- Prefer stable UI identifiers/text over coordinates.
- Keep actions reversible and explain any app permissions required.
- For Find My or Messages, verify the final visible state before claiming success.

## Decision table

| User intent | Prefer |
|---|---|
| Save/search note | Notes.app via `memo` |
| Create/complete personal reminder | Reminders.app via `remindctl` |
| Send/read Apple Message | Messages/iMessage workflow with recipient resolution |
| Locate device/AirTag | Find My UI automation + screenshot verification |
| Interact with arbitrary macOS app | Background `computer_use` |
