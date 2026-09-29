# Health data privacy notes

Fitness AI treats health data as sensitive.

Principles in this MVP:
- Request only the health data types needed by the feature.
- Read health data only after user authorization.
- Background reads require a separate user permission.
- Store normalized daily data rather than raw provider records.
- Never expose a user's health data without authentication.
- Keep AI recommendations informational and avoid diagnosis or treatment claims.
- Before production release, add a formal privacy policy, retention/deletion
  controls, audit logging, encryption-at-rest strategy, and Google Play Health
  Connect declarations.

For production, restrict CORS and replace development secrets with managed
secrets. Do not commit `.env` or real access tokens.
