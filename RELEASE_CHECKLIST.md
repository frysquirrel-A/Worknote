# RELEASE_CHECKLIST.md — TestFlight Readiness

## Must be GO
- flutter analyze: 0 errors
- iOS build succeeds (Archive 가능)
- Crashlytics receiving crashes in debug/test
- No data-loss auto-recovery (no deleteBoxFromDisk on open failure)

## Manual steps (Human required)
- iOS:
  - GoogleService-Info.plist added + target membership
  - Info.plist URL scheme set (REVERSED_CLIENT_ID)
- Android:
  - release keystore configured
  - Firebase SHA-1/SHA-256 등록
  - google-services.json re-download after packageId confirmation
- Apple:
  - Bundle ID 확정
  - Signing Team + Profile 설정
  - Version/Build number 정책 확정

## Smoke tests (device)
- Local profile start
- Google sign-in (if enabled)
- Create task + plan toggle → schedule reflects
- Create journal + photo → gallery shows
- Send message in group + DM thread
- Feedback submit to Firestore (write)
