# Ishi Grocery Delivery

Flutter MVP for Android and iOS using Firebase Authentication, Firestore,
Storage, and FCM.

## Firebase setup

This machine is not logged in to Firebase CLI, so the app contains placeholder
Firebase config files. Replace them with real generated values:

```bash
firebase login
flutterfire configure
```

Expected outputs/locations:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Enable these Firebase products in the console:

- Authentication: Phone and Email/Password providers
- Firestore Database
- Firebase Storage
- Firebase Cloud Messaging

### Phone OTP with real numbers

Firebase test phone numbers do not send SMS, so they can work even when real
phone OTP is blocked. For real Sri Lanka numbers (`+94...`), check all of these:

- Authentication > Sign-in method: enable Phone.
- Authentication > Settings > SMS region policy: allow Sri Lanka (`+94`).
- Project settings > Your apps > Android app: add the debug/release SHA-1 and
  SHA-256 fingerprints for `com.ishi.grocerydelivery`, then download a fresh
  `android/app/google-services.json`.
- If Firebase returns `BILLING_NOT_ENABLED`, the app reached Firebase but real
  SMS sending is blocked until billing/Blaze is enabled. On Spark, use Firebase
  test phone numbers during development or use the no-OTP admin login below.

On Windows, you can print the Android fingerprints with:

```bash
cd android
.\gradlew signingReport
```

The app stores FCM tokens on `users/{uid}.fcmTokens` and writes notification
documents. The included Cloud Function in `functions/` sends push notifications
when a `notifications/{notificationId}` document is created.

## Admin access

Register normally in the app, then change the user document in Firestore:

```text
users/{uid}.role = "admin"
```

After logout/login, the same mobile app opens the admin dashboard.

For the built-in no-OTP admin account, enable Email/Password authentication and
login with:

```text
Phone: +94768976111
Password: admin123
```

This signs in with Firebase Email/Password using `94768976111@app.local`, so it
does not send a Phone OTP SMS. Deploy the included Firestore and Storage rules
so this account can manage admin data.

## Verification run

```bash
flutter analyze
flutter test
flutter build apk --debug
```
