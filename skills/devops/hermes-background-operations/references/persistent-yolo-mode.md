# Persistent YOLO / no-confirmation mode for Hermes Gateway

Use this note when the user explicitly wants Hermes to run local commands without approval prompts, especially from Telegram/Gateway sessions.

## Procedure

1. Confirm the user explicitly wants persistent no-confirmation execution. For this user's dedicated agent PC, "all grants" or "YOLO by default" means permanent local autonomy, not just a one-session `/yolo` toggle.
2. Set the approval mode with a plain unquoted value:
   ```bash
   hermes config set approvals.mode off
   ```
   Do not run `hermes config set approvals.mode "'off'"`; shell-embedded quotes can be preserved and serialize as `mode: '''off'''`.
3. If the user asks for maximum autonomy on a trusted/dedicated machine, set and verify the related grants:
   ```bash
   hermes config set approvals.cron_mode approve
   hermes config set security.tirith_enabled false
   hermes config set hooks_auto_accept true
   hermes config set browser.allow_private_urls true
   hermes config set security.allow_private_urls true
   ```
   Then enable any disabled toolsets the user wants available:
   ```bash
   hermes tools list
   hermes tools enable video
   hermes tools enable video_gen
   # ...repeat only for toolsets that are disabled and appropriate for the user's request
   ```
4. Verify the actual serialized config, not just command output:
   ```bash
   grep -A5 '^approvals:' ~/.hermes/config.yaml
   grep -A5 '^security:' ~/.hermes/config.yaml
   grep -A8 '^browser:' ~/.hermes/config.yaml
   ```
5. Expected parsed values:
   ```yaml
   approvals:
     mode: off        # parsed by Hermes as string "off", not as a wrong custom literal
     cron_mode: approve
   security:
     tirith_enabled: false
     allow_private_urls: true
   browser:
     allow_private_urls: true
   hooks_auto_accept: true
   ```
6. If the config writer produced boolean `mode: false` or over-quoted text such as `mode: '''off'''`, rewrite with a YAML-aware script and verify with `yaml.safe_load`:
   ```bash
   python3 - <<'PY'
   from pathlib import Path
   import yaml
   p = Path('~/.hermes/config.yaml').expanduser()
   c = yaml.safe_load(p.read_text())
   c.setdefault('approvals', {})['mode'] = 'off'
   c['approvals']['cron_mode'] = 'approve'
   p.write_text(yaml.safe_dump(c, sort_keys=False, allow_unicode=True))
   PY
   python3 - <<'PY'
   from pathlib import Path
   import yaml
   c = yaml.safe_load(Path('~/.hermes/config.yaml').expanduser().read_text())
   print(repr(c['approvals']['mode']))
   print(repr(c['approvals']['cron_mode']))
   PY
   ```
7. Restart Gateway so Telegram/Discord sessions pick up the setting:
   ```bash
   hermes gateway restart
   hermes gateway status
   ```

## Verification

- `hermes status --all` should show Gateway running and terminal backend local if the goal is command execution on the current PC.
- `hermes tools list --platform telegram` should show `terminal`, `file`, and optionally `code_execution` enabled.
- Remember: approval mode bypasses confirmation prompts only. It does not grant root; sudo remains governed by Hermes sudo configuration and credentials.

## Pitfall captured

In one session, `hermes config set approvals.mode off` reported success but serialized the YAML value as boolean `false`. The safe follow-up is to inspect the config and patch to literal `off` when needed, then restart Gateway.
