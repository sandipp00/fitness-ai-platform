# Clean Architecture

```text
Flutter UI
   |
API client
   |
FastAPI routes
   |
Services / domain logic
   |
Repositories / SQLAlchemy
   |
PostgreSQL
```

External health providers must enter through adapters:

```text
HealthProvider
  ├── HealthConnectProvider
  ├── HealthKitProvider
  └── ManualProvider
```

The domain layer should never depend directly on Health Connect, HealthKit,
a wearable SDK, or an LLM provider.

## Engineering rules

1. Validate data at the API boundary.
2. Keep health calculations deterministic and testable.
3. Keep provider-specific code isolated.
4. Never put secrets in the mobile app or Git.
5. Store source metadata for health resources.
6. Treat AI output as informational, not medical diagnosis.
