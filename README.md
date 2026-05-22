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

The app stores FCM tokens on `users/{uid}.fcmTokens` and writes notification
documents. The included Cloud Function in `functions/` sends push notifications
when a `notifications/{notificationId}` document is created.

## Admin access

Register normally in the app, then change the user document in Firestore:

```text
users/{uid}.role = "admin"
```

After logout/login, the same mobile app opens the admin dashboard.

## Verification run

```bash
flutter analyze
flutter test
flutter build apk --debug
```
