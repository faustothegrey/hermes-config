# Discord Gateway Setup Notes

Use this reference when guiding a user through adding Discord text/voice to Hermes Gateway.

## Core distinction

- A Discord **server** is a Discord-hosted workspace/community. The user does **not** install a local Discord server.
- The only process that must run on the user's machine/VPS is **Hermes Gateway**.
- Telegram and Discord can coexist on the same Hermes Gateway, but they may have separate platform sessions/conversation histories.

## Safe secret handling

- Do **not** ask the user to paste a Discord bot token into Telegram/Discord chat.
- Have the user create/reset the token in Discord Developer Portal and enter it directly on the host where Hermes runs.
- Accept in chat only non-secret setup details: server name, text channel name, voice channel name, non-sensitive error messages, and screenshots with tokens hidden.
- When verifying config, report only whether a token is present/valid; never print token values or full `.env` files.

## User-facing bot creation flow

1. Open <https://discord.com/developers/applications>.
2. Create **New Application**, e.g. `Hermes`.
3. Go to **Bot** and create the bot/reset token if needed.
4. Under **Privileged Gateway Intents**:
   - enable **Message Content Intent**;
   - enable **Server Members Intent** only if needed;
   - Presence Intent is usually unnecessary.
5. Go to **OAuth2 → URL Generator**.
6. Select scopes:
   - `bot`
   - `applications.commands`
7. Select permissions:
   - View Channels
   - Send Messages
   - Read Message History
   - Connect
   - Speak
   - Optional temporary shortcut: Administrator for first setup, then tighten later.
8. Open generated invite URL, select the user's Discord server, and authorize the bot.

## Recommended server/channel layout

For a simple Hermes-only server, recommend a plain/community template such as **Study Group** or **Friends** rather than Gaming.

Create:

- Text: `#hermes-chat`
- Voice: `Hermes Voice`
- Optional text log/test channel: `#log-hermes`

Test order:

1. Confirm bot appears online or invited in Discord.
2. Configure token locally in Hermes Gateway.
3. Restart Gateway.
4. Test text messages in `#hermes-chat`.
5. Test voice join/speak in `Hermes Voice`.
