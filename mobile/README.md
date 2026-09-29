# Fitness AI mobile client

The Flutter client reads the API URL from `API_BASE_URL` so development and production builds do not require source changes.

## Local Android emulator

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Physical Android device

Use the computer's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

The backend must listen on `0.0.0.0` and the phone must be able to reach the computer.

## Production

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN
```

Before release, generate the native Android/iOS folders with:

```bash
flutter create --platforms=android,ios .
```

Then apply the Health Connect / HealthKit permissions documented in `../docs/health-connect-setup.md`.
