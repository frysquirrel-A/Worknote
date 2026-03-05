# RELEASE_CHECKLIST.md — TestFlight Readiness

## Must be GO
- flutter analyze: 0 errors
- iOS build succeeds (Archive possible)
- Crashlytics receiving crashes in debug/test
- No data-loss auto-recovery (no deleteBoxFromDisk on open failure)

## Manual steps (Human required)
- iOS:
  - GoogleService-Info.plist added + target membership
  - Info.plist URL scheme set (REVERSED_CLIENT_ID)
- Android:
  - release keystore configured
  - Firebase SHA-1/SHA-256 registered
  - google-services.json re-downloaded after packageId confirmation
- Apple:
  - Bundle ID confirmed
  - Signing Team + Profile configured
  - Version/Build number policy confirmed

## Smoke tests (device)
- Local profile start
- Google sign-in (if enabled)
- Create task + plan toggle -> schedule reflects
- Create journal + photo -> gallery shows
- Send message in group + DM thread
- Feedback submit to Firestore (write)
