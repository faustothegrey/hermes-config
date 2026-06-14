# Google/Gmail OAuth diagnostics

Use this reference when checking whether Hermes can access the user's Gmail/Google Workspace account.

## What to check

1. Check the Hermes Google OAuth token first when Gmail API access is expected:
   - default profile token path: `~/.hermes/google_token.json`
   - other profiles may have their own token under `~/.hermes/profiles/<profile>/google_token.json`

2. Inspect only metadata, never print secrets:
   - account/email
   - scopes
   - expiry
   - presence of `token` and `refresh_token`
   - token URI / client ID only if redacted or shortened

3. Prove access with a real Google API call, not just file presence:
   - load `google.oauth2.credentials.Credentials.from_authorized_user_info(...)`
   - if expired and a refresh token exists, call `creds.refresh(Request())`
   - then call Gmail API, e.g. `gmail.users().getProfile(userId='me').execute()` and optionally list one inbox message ID/count

4. If refresh fails with `invalid_grant` / `Token has been expired or revoked`, report that OAuth was configured but the current grant is no longer usable. The fix is to re-run the OAuth authorization flow; do not keep retrying or assume IMAP/GOA will work.

5. GNOME Online Accounts can be a secondary signal:
   - `~/.config/goa-1.0/accounts.conf` shows configured accounts and enabled services
   - `gdbus ... EnsureCredentials` / `GetAccessToken` can confirm whether GOA has a usable token
   - GOA presence alone is not Gmail API access for Hermes.

## Minimal safe probe pattern

```python
import json
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

p = Path.home() / '.hermes' / 'google_token.json'
info = json.loads(p.read_text())
creds = Credentials.from_authorized_user_info(info, scopes=info.get('scopes'))
if not creds.valid and creds.refresh_token:
    creds.refresh(Request())
service = build('gmail', 'v1', credentials=creds, cache_discovery=False)
profile = service.users().getProfile(userId='me').execute()
print(profile.get('emailAddress'))
```

Do not print tokens, refresh tokens, client secrets, or full credential JSON.