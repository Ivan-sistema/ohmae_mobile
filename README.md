# ohmae_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android release signing

Release builds require a dedicated signing key; the debug key is never used for
release. Store the credentials in the ignored `android/key.properties` file:

```properties
storeFile=path/to/release-key.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Alternatively, provide `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD` as environment variables. Keep
the keystore and its passwords out of source control.

## Local demo mode

To open the dashboard without logging in or connecting to the backend, run a
debug build with `--dart-define=OHMAE_DEMO_MODE=true`. The demo button is hidden
by default and is disabled in release builds. It uses fictional local data;
completing a task only changes the current screen state and sends no API
requests.
