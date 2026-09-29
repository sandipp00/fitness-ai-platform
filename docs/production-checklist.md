# Production checklist

## Backend

- [x] Environment-driven database URL and secret
- [x] Environment-driven CORS allowlist
- [x] Database connection readiness endpoint
- [x] Docker healthcheck for PostgreSQL
- [x] Non-root Docker runtime user
- [x] Typed health-sync payload validation
- [x] Daily activity/sleep/water upserts
- [x] Progress snapshot refresh after health updates
- [ ] Run schema migrations in production before startup
- [ ] Configure a managed PostgreSQL database
- [ ] Configure a strong `SECRET_KEY`
- [ ] Set `CORS_ORIGINS` to the actual mobile/web origins where applicable
- [ ] Configure API logging, metrics and error tracking
- [ ] Configure backups and database retention

## Mobile

- [x] API URL supplied through `--dart-define`
- [x] Background health sync
- [x] Health Connect activity and exercise-time reads
- [ ] Generate native Android/iOS folders
- [ ] Apply Android Health Connect permissions
- [ ] Configure iOS HealthKit capability and usage descriptions
- [ ] Test on a physical Android device
- [ ] Test background sync after reboot and permission changes
- [ ] Add release signing and store metadata

## AI / ML

- [x] Trusted-resource RAG fallback
- [x] Optional OpenAI server-side integration
- [x] Personalization model scaffold
- [x] Explicit non-clinical framing
- [ ] Replace synthetic bootstrap training with evaluated real/representative data
- [ ] Add model evaluation report and drift monitoring
- [ ] Version production models and feature schemas
