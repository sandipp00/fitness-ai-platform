# Kinetiq mobile app

Flutter client for Kinetiq (`com.sandipp00.kinetiq`). Build-time settings are
passed with `--dart-define`:

| Define | Required | Purpose |
|---|---|---|
| `API_BASE_URL` | Release: yes, must be `https://` | Kinetiq API address |
| `PRIVACY_POLICY_URL` | Recommended | Shown in the in-app privacy policy |
| `SUPPORT_EMAIL` | Recommended | Contact shown in the privacy policy |

## Local Android emulator

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Debug builds allow plain `http://` so you can use a local API. Release builds do
not; they show a configuration error if the URL isn't https.

## Physical device against a local API

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

The backend must listen on `0.0.0.0` and be reachable from the phone.

## Tests

```bash
flutter analyze
flutter test
```

## Release

See [`../docs/release-android.md`](../docs/release-android.md) for signing,
building the app bundle and the Play Console health-data declarations.
