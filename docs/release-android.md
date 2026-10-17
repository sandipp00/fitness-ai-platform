# Releasing Kinetiq on Google Play

App ID: `com.sandipp00.kinetiq`. It is permanent once uploaded.

## 1. Deploy the API

1. Merge the backend changes. Render runs `alembic upgrade head` on deploy.
2. Confirm `https://<your-api>/health/ready` returns `{"status":"ready"}`.
3. Render env vars: `ENVIRONMENT=production`, a generated `SECRET_KEY`,
   `OPENAI_API_KEY` (optional). Leave `CORS_ORIGINS` empty unless you also ship
   a web client.
4. Make yourself an admin if you will publish resources:
   `python -m scripts.make_admin you@example.com` (Render shell).

## 2. Create the upload key (once)

Keep the keystore and passwords somewhere safe (a password manager). If you
lose them, you can still recover with Play App Signing, but only through Google
support.

```bash
keytool -genkey -v -keystore ~/kinetiq-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Create `mobile/android/key.properties` (it is git-ignored):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/absolute/path/to/kinetiq-upload.jks
```

Without this file, release builds are signed with the debug key and Play will
reject them.

## 3. Build

```bash
cd mobile
flutter pub get
flutter test
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://<your-api> \
  --dart-define=PRIVACY_POLICY_URL=https://<your-site>/privacy \
  --dart-define=SUPPORT_EMAIL=<support address>
```

The bundle is at `build/app/outputs/bundle/release/app-release.aab`. Bump
`version:` in `pubspec.yaml` (e.g. `1.0.1+4`) for every upload.

A release build with an `http://` API URL shows a configuration error instead
of starting, by design.

## 4. Test on a real device first

Use an internal-testing track and a physical Android 13 and Android 14+ phone:

- [ ] Register, sign out, sign in.
- [ ] Health tab → consent → Health Connect permission sheet appears → values show.
- [ ] In Health Connect → App permissions → Kinetiq → "Read privacy policy" opens
      the in-app policy (both Android 13 and 14).
- [ ] Deny permissions → app explains how to allow them.
- [ ] Dashboard shows today's numbers in your local timezone after sync.
- [ ] Leave the app closed > 1 hour → data still updates (background sync).
- [ ] Coach answers; workout plan and recommendations load.
- [ ] Airplane mode → readable "can't reach Kinetiq" error.
- [ ] Account & privacy → Delete account → you are signed out and can no
      longer sign in.

## 5. Play Console

- **Privacy policy:** host `docs/privacy-policy.md` (after filling placeholders)
  and enter its URL.
- **Health Connect declaration** (App content → Health apps / Health Connect):
  declare read access for Steps, Active calories burned, Distance, Exercise,
  Sleep, and background read; explain each is used to compute daily scores,
  trends and workout plans shown to the user.
- **Data safety:**
  - Collected: email (account management), name (app functionality), health
    and fitness data (app functionality, personalization), app interactions
    via coach messages (app functionality).
  - Shared: coach questions and metric summaries with the AI provider (if
    `OPENAI_API_KEY` is set). Mark it as shared for app functionality.
  - Encrypted in transit: yes. Users can request deletion: yes (in-app).
- **Account deletion:** Play also requires a web link where users can request
  deletion without the app. Point it to a page or form that reaches
  `SUPPORT_EMAIL`.
- **Target audience:** 13+; not designed for children.
- **Content rating:** complete the questionnaire. There is no user-generated
  content shared between users.

## iOS (later)

iOS has HealthKit usage strings, the entitlement file and bundle ID
`com.sandipp00.kinetiq`. To ship it you need a Mac with Xcode and an Apple
Developer account. Enable the HealthKit capability for the App ID, and add
background delivery if you want hourly sync on iOS. Then test on a device.
