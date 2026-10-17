# Kinetiq Privacy Policy

_Last updated: [DATE]_

> **Before publishing:** replace every `[BRACKETED]` placeholder, have the
> text reviewed for the countries you launch in, and host it at a public URL.
> Google Play and Health Connect require that URL. Keep it consistent with the
> in-app policy in `mobile/lib/screens/privacy_policy_screen.dart`.

Kinetiq ("we", "us") provides a fitness app that turns your activity and sleep
data into recovery scores, trends, workout plans and AI coaching. This policy
explains what we collect, why, and the choices you have.

## Information we collect

| Category | Data | Source |
|---|---|---|
| Account | Email address, password (stored only as a bcrypt hash) | You |
| Profile | Name, age, height, weight, fitness goal, activity level, timezone | You / your device |
| Health and fitness | Daily totals of steps, active minutes, active calories, distance and sleep duration | Health Connect (Android) or Apple Health (iOS), **only after you grant permission** |
| Manual entries | Workouts, weight and water you log | You |
| Coach questions | Questions you ask the AI coach | You |
| Technical | IP address and request logs (no health data) for security and abuse prevention | Your device |

We read health data only; we never write to Health Connect or Apple Health. We
store daily totals, not raw sensor records.

## How we use information

- To show your dashboard, progress trends, recovery and sleep scores,
  personalized workout plans and recommendations.
- To answer your questions in the AI coach.
- To secure the service (for example rate-limiting sign-in attempts).

We do **not** sell personal data, use health data for advertising, or share it
with data brokers. Health Connect and HealthKit data is used only to provide
the features above, in line with the
[Health Connect Permissions policy](https://support.google.com/googleplay/android-developer/answer/12991134)
and Apple's HealthKit guidelines.

## Sharing

- **AI provider.** When you use the AI coach, your question and a summary of
  your recent metrics (steps, active minutes, calories, sleep hours, goal) are
  sent to [AI PROVIDER, e.g. OpenAI] to generate an answer. Your email and name
  are not sent. [Describe the provider's retention terms.]
- **Infrastructure providers.** Our servers and database are hosted by
  [HOSTING PROVIDER, e.g. Render] under contract.
- **Legal.** We may disclose information if required by law.

## Storage and security

Data is encrypted in transit (HTTPS). Sign-in tokens are stored in your
device's secure storage (Keychain / Android Keystore). Passwords are hashed.
Data is stored in [REGION].

## Retention and deletion

We keep your data while your account is active. You can delete your account at
any time in the app under **Account & privacy → Delete account**. This
immediately and permanently deletes your account, profile and all health and
activity data from our database. [State backup retention, e.g. "Backups are
overwritten within 30 days."]

You can also revoke Kinetiq's health access at any time in Health Connect or
Apple Health settings, and request a copy of your data at [SUPPORT EMAIL].

## Children

Kinetiq is not intended for children under 13 (or the minimum age in your
country), and we do not knowingly collect their data.

## Medical disclaimer

Kinetiq provides general wellness information. It is not a medical device and
does not diagnose, treat or prevent any condition.

## Changes and contact

We will post changes here and update the date above. Questions:
[SUPPORT EMAIL].
