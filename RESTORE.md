# Restore procedure

On a new machine:

1. Install Hermes Agent.
2. Clone this repo:

   git clone git@github.com:faustothegrey/hermes-config.git ~/Backups/hermes-config

3. Restore non-secret configuration:

   cd ~/Backups/hermes-config
   scripts/restore-hermes.sh

4. If encrypted secrets are present, set `SSH_PRIVATE_KEY` to the matching private key before running restore:

   SSH_PRIVATE_KEY=~/.ssh/id_rsa scripts/restore-hermes.sh

5. Verify:

   hermes config check
   hermes doctor
   hermes tools list
   hermes gateway status

If secrets cannot be decrypted, re-run `hermes setup`, `hermes auth`, and platform setup manually.
