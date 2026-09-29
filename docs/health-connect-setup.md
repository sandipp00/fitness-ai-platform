# Android Health Connect setup

The Flutter app uses the maintained `health` package (`^13.3.2`) to bridge Android Health Connect and iOS HealthKit.

## 1. Generate the native Flutter platforms

From the `mobile` directory:

```bash
flutter create --platforms=android,ios .
```

Do this once if the repository was created without generated native folders.

## 2. Android manifest

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>

<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.READ_DISTANCE"/>
<uses-permission android:name="android.permission.health.READ_SLEEP"/>
```

Also add the Health Connect package query:

```xml
<queries>
    <package android:name="com.google.android.apps.healthdata" />
    <intent>
        <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
    </intent>
</queries>
```

The health plugin documentation also requires the Health Connect permission-usage activity alias and an activity intent filter for its Android permission flow. Copy those from the plugin's current README when configuring the generated native project.

## 3. Android activity

The `health` plugin documents using `FlutterFragmentActivity` for Android permission requests.

Your `MainActivity.kt` should therefore extend:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

## 4. Health Connect

Install/update Health Connect on the Android device and grant the app access to the requested data types.

The app requests only:
- Steps
- Active calories
- Distance
- Sleep

Do not request unrelated health data.

## 5. Sync

The app flow is:

```text
Health Connect
    ↓
HealthConnectService
    ↓
NormalizedHealthData
    ↓
POST /api/health-data/sync
    ↓
FastAPI
    ↓
Activity/Sleep tables
    ↓
Dashboard analytics
```

## Important

Google restricts historical reads by default; older data may require the separate historical-data permission. Background reads also require an additional permission. This MVP deliberately performs a foreground "today" sync first.

For Google Play publication, declare the health-data access/use in Play Console and provide the required privacy policy.


## Sync behavior

The backend uses an upsert-by-user-and-day strategy for activity and sleep.
Repeated foreground syncs therefore update the same daily record instead of
creating duplicates.

The first release intentionally syncs the current day only. A later background
sync worker can use Health Connect's background-read permission and WorkManager.

## 6. Background sync

The Flutter app now schedules a unique hourly WorkManager task. The worker:

1. Loads the stored JWT.
2. Checks that Health Connect background reading is supported.
3. Checks that the user granted background health access.
4. Reads today's normalized health data.
5. Sends it to `/api/health-data/sync`.
6. The backend upserts today's activity/sleep record.

Android's Health Connect documentation explicitly uses WorkManager for periodic
background reads and recommends checking the `FEATURE_READ_HEALTH_DATA_IN_BACKGROUND`
feature before scheduling the job. citeturn0search0

Background execution is still controlled by Android. The app must not promise
minute-by-minute synchronization.

## 7. AI recommendations

`GET /api/ai/recommendations` now generates conservative, deterministic
recommendations from the latest activity, sleep, recovery score, and user goal.
This is the foundation for a later ML/LLM coaching layer; it is intentionally
not medical advice.
