# Production checklist

Items marked **(you)** need your accounts, devices or decisions and cannot be
done in code. See [release-android.md](release-android.md) for the steps.

## Backend

- [x] Environment-driven database URL, secret and CORS allowlist
- [x] Unset `ENVIRONMENT` treated as production (refuses the dev secret)
- [x] Database readiness endpoint and Docker healthcheck
- [x] Non-root Docker runtime user; no tests shipped in the image
- [x] Alembic migrations run before startup; CI checks upgrade, model drift and downgrade
- [x] Typed, bounded request validation (health sync, chat, profile, timezone)
- [x] Daily activity/sleep/water upserts; partial syncs never erase data
- [x] Per-user timezone for "today"
- [x] Access + refresh tokens, revocation (logout-all), login rate limiting
- [x] Admin-only shared resources
- [x] Account deletion and data export endpoints
- [x] Request IDs and per-request logs; OpenAI timeout + fallback
- [x] Pinned dependencies
- [ ] **(you)** Confirm Render env vars; verify migration `0002` ran on PostgreSQL
- [ ] **(you)** Database backups / point-in-time recovery on the Render plan
- [ ] Error tracking (e.g. Sentry) and uptime alerting on `/health/ready`
- [ ] Shared rate-limit store (Redis) before running more than one API instance

## Mobile

- [x] API URL via `--dart-define`; release builds require https
- [x] INTERNET permission in release; cleartext only in debug
- [x] Health Connect permissions, background read, Android 14 rationale alias
- [x] Per-platform health types (Android uses workouts/sleep sessions)
- [x] Consent before first health connection
- [x] Tokens in secure storage; automatic refresh; expired session → sign-in
- [x] Background hourly sync scheduled after connecting
- [x] In-app privacy policy and account deletion
- [x] App ID `com.sandipp00.kinetiq`; release signing via `key.properties`
- [x] iOS HealthKit usage descriptions and entitlement
- [x] CI: analyze, test, release APK build
- [ ] **(you)** Create upload keystore and `key.properties`
- [ ] **(you)** Test on physical Android 13 and 14+ devices (checklist in release-android.md)
- [ ] **(you)** App icon and store screenshots/listing
- [ ] iOS: Xcode capability setup and device testing (needs a Mac)

## Legal / store

- [ ] **(you)** Fill in and host `docs/privacy-policy.md`; pass its URL at build time
- [ ] **(you)** Play Console: Health Connect declaration, Data safety, account-deletion URL
- [ ] **(you)** Support email address

## AI / ML

- [x] Trusted-resource RAG fallback when the AI provider is unavailable
- [x] Server-side OpenAI key only; explicit non-clinical framing
- [x] Personalization model scaffold (lazy-loaded)
- [ ] Replace synthetic bootstrap training with evaluated real/representative data
- [ ] Model evaluation report, drift monitoring, versioned feature schemas
