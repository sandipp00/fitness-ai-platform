# Live Data Flow

## Authentication

```text
Flutter
  -> POST /api/auth/register or /api/auth/login
  <- JWT
  -> SharedPreferences
```

## Dashboard

```text
Flutter
  -> GET /api/dashboard
     Authorization: Bearer <JWT>
  <- activity + sleep + water + scores + recommendations
```

## Health integration

The mobile app should read health data through provider-specific adapters.

Android:
```text
Health Connect -> HealthConnectService -> normalized health metrics -> API
```

iOS:
```text
HealthKit -> HealthKitService -> normalized health metrics -> API
```

Do not put health-provider SDK logic inside dashboard widgets.
