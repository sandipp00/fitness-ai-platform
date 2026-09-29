# Architecture

## Data flow

Health sources / manual entry
→ mobile app
→ FastAPI
→ validation
→ PostgreSQL
→ analytics
→ recommendations
→ AI/RAG

## Integration strategy

Use provider adapters:

```text
HealthProvider
├── HealthConnectProvider
├── HealthKitProvider
└── ManualProvider
```

The domain model should not depend on a specific health provider.

## Safety boundary

The application is a wellness/fitness tracker. It should not:
- diagnose medical conditions
- recommend prescription changes
- fabricate measurements
- present uncertain model output as clinical fact

Health resources should retain source and URL metadata.
