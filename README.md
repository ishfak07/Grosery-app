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

- Authentication: Email/Password provider
- Firestore Database
- Cloud Functions
- Firebase Cloud Messaging

Image uploads use the unsigned Cloudinary preset `grocery_unsigned` in the
`grocery_app` folder. Do not add a Cloudinary API secret to the Flutter app.

### Authentication without OTP

Registration uses the customer's Sri Lankan mobile number as a hidden Firebase
Email/Password login (`947xxxxxxxx@app.local`). No SMS OTP is sent.

Forgot password also avoids OTP. The customer submits a reset request, admin
opens Password resets in the admin dashboard, approves or rejects it, and the
customer can then set a new password. The password change is performed by the
Cloud Functions Admin SDK, so deploy functions and rules together:

```bash
firebase deploy --only functions,firestore:rules --project grocery-delivery-app-388bc
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

For the built-in admin account, enable Email/Password authentication and login
with:

```text
Phone: +94768976111
Password: admin123
```

This signs in with Firebase Email/Password using `94768976111@app.local`.
Deploy the included Firestore rules so this account can manage admin data.

## Verification run

```bash
flutter analyze
flutter test
flutter build apk --debug
```
