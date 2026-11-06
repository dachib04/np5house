# Pending Tasks

## Real email delivery for quote requests
**Status:** Not started — waiting on a Resend account.

Right now, quote requests submitted from the configurator save to Supabase and show up in the admin's **Quote Requests** tab, but nothing emails anyone. To close this gap:

1. Sign up at [resend.com](https://resend.com) using the **boss's email** (this should be company-owned infrastructure, not tied to a personal account)
2. Dashboard → API Keys → create one
3. Send the key over, and it gets wired into a Supabase Edge Function that emails new quote requests to `sales@np5.eu` (or whichever inbox is preferred)

Everything else is already built and ready for this — just needs the API key.
