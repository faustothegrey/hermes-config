# Model picker provider mismatch — diagnostic reference

## What it looks like

When a user selects a model via `hermes model` interactive picker that belongs
to a different provider than the active one, the error is permanent and looks
like this (example: provider `nous` + OpenRouter `:free` model):

```
⚠️  API call failed (attempt 1/3): AuthenticationError [HTTP 401]
   🔌 Provider: nous  Model: nvidia/nemotron-3-ultra:free
   🌐 Endpoint: https://inference-api.nousresearch.com/v1
   📝 Error: HTTP 401: Your API key is invalid, blocked or out of funds.
              Please go visit the portal to sort that out:
              https://portal.nousresearch.com
   ⏱️  Elapsed: 5.16s  Context: 10 msgs, ~14,282 tokens
⚠️ Non-retryable error (HTTP 401) — trying fallback...
❌ Non-retryable error (HTTP 401): HTTP 401: Your API key is invalid, blocked
   or out of funds. Please go visit the portal to sort that out:
   https://portal.nousresearch.com
❌ Non-retryable client error (HTTP 401). Aborting.
   🔌 Provider: nous  Model: nvidia/nemotron-3-ultra:free
   🌐 Endpoint: https://inference-api.nousresearch.com/v1
   💡 Nous Portal OAuth token was rejected (HTTP 401). Your token may be
      expired, revoked, or your account may be out of credits. To fix:
      1. Re-authenticate: hermes auth add nous --type oauth
      2. Check your portal account: https://portal.nousresearch.com
      ⚠️  Note: `nvidia/nemotron-3-ultra:free` looks like an OpenRouter
         slug (`:free` suffix). Nous Portal won't recognize that model name.
         Either switch to a Nous catalog model, or run
         `/model openrouter:nvidia/nemotron-3-ultra:free` to use OpenRouter.
```

## Why it happens

The interactive `hermes model` picker aggregates models from all configured
providers. The user sees `nvidia/nemotron-3-ultra:free` in the list, selects it
in good faith, but the active provider remains `nous`. The Nous inference API
doesn't know that model slug — it's an OpenRouter model. The 401 is the Nous
portal rejecting an unknown model name, not an auth expiry or credit issue.

## How to diagnose

```bash
hermes model          # shows active provider and model
hermes model --list   # shows available models per provider
```

If the model slug contains `:free` (OpenRouter convention) but the provider is
`nous`, it's a mismatch.

## How to fix

Option A — switch provider to match the model:
```bash
hermes model openrouter:nvidia/nemotron-3-ultra:free
```
Requires an OpenRouter API key configured.

Option B — keep `nous` provider, pick a Nous-catalog model:
```bash
hermes model
# pick from Nous-native models only
```

## What NOT to do

- Do NOT add retry loops around the 401 — it will never succeed.
- Do NOT re-authenticate Nous OAuth — the token is fine, the model name is wrong.
- Do NOT treat this as transient throttling or rate-limiting.
