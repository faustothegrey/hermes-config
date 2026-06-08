# Persistent YOLO / no-confirmation mode for Hermes Gateway

Use this note when the user explicitly wants Hermes to run local commands without approval prompts, especially from Telegram/Gateway sessions.

## Procedure

1. Confirm the user explicitly wants persistent no-confirmation execution.
2. Set the approval mode:
   ```bash
   hermes config set approvals.mode off
   ```
3. Verify the actual serialized config, not just command output:
   ```bash
   grep -A3 '^approvals:' ~/.hermes/config.yaml
   ```
4. Expected shape:
   ```yaml
   approvals:
     mode: off
     timeout: 60
   ```
5. If the config writer produced `mode: false`, patch the YAML to literal `mode: off`.
6. Restart Gateway so Telegram sessions pick up the setting:
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
