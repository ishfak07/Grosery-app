# Ishi Grocery Delivery

Flutter MVP for Android and iOS using Firebase Authentication, Firestore,
Firebase Cloud Messaging, and Cloudinary unsigned image uploads.

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
- Firebase Cloud Messaging

Image uploads use the unsigned Cloudinary preset `grocery_unsigned` in the
`grocery_app` folder. Do not add a Cloudinary API secret to the Flutter app.

### Phone OTP with real numbers

Firebase test phone numbers do not send SMS, so they can work even when real
phone OTP is blocked. For real Sri Lanka numbers (`+94...`), check all of these:

- Authentication > Sign-in method: enable Phone.
- Authentication > Settings > SMS region policy: allow Sri Lanka (`+94`).
- Project settings > Your apps > Android app: add the debug/release SHA-1 and
  SHA-256 fingerprints for `com.ishi.grocerydelivery`, then download a fresh
  `android/app/google-services.json`.
- If your Google API key is restricted, allow the browser verification fallback
  domain `grocery-delivery-app-388bc.firebaseapp.com`. Debug or sideloaded
  Android builds can fall back to reCAPTCHA even after the SHA keys are correct.
- If Firebase returns `BILLING_NOT_ENABLED`, the app reached Firebase but real
  SMS sending is blocked until billing/Blaze is enabled. On Spark, use Firebase
  test phone numbers during development or use the no-OTP admin login below.
- If Android logs show `unknown status code: 17499 Error code:39`, Firebase is
  usually blocking the request as quota/fraud before sending SMS. Open
  Authentication > Settings > Sign-up quota, raise the temporary quota, then
  wait for any device/project throttle to cool down before retrying.

On Windows, you can print the Android fingerprints with:

```bash
cd android
.\gradlew signingReport
```

For this debug keystore, the current fingerprints are:

```text
SHA1:    0B:78:BE:68:E6:42:A1:FF:E4:6A:7E:4A:63:5F:5E:78:CB:31:5A:65
SHA-256: 19:D7:E8:42:F7:DC:29:35:96:76:BF:56:A9:04:E1:92:2D:93:2E:E4:F3:9A:1B:CC:C8:83:00:8E:B2:AE:38:2C
```

After adding those to the Android app with package `com.ishi.grocerydelivery`,
download `google-services.json` again from that same Android app. If the file
still contains an empty `oauth_client` array, Firebase has not attached the SHA
fingerprints to this app yet.

### Phone OTP on emulators

Use Firebase test phone numbers on Android emulators. Real SMS OTP is intended
for real devices, and emulators often fail app verification before Firebase sends
SMS.

1. In Firebase Console, open Authentication > Sign-in method > Phone > Phone
   numbers for testing.
2. Add a fictional phone number and code, for example `+94770000000` and
   `123456`.
3. Run the debug app with the same values:

```bash
flutter run -d emulator-5554 --dart-define=FIREBASE_AUTH_TEST_PHONE=+94770000000 --dart-define=FIREBASE_AUTH_TEST_CODE=123456
```

When that number is entered in the app, Firebase uses the configured test code
without trying Play Integrity, reCAPTCHA, or a real SMS.

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
does not send a Phone OTP SMS. Deploy the included Firestore rules so this
account can manage admin data.

## Verification run

```bash
flutter analyze
flutter test
flutter build apk --debug
```
