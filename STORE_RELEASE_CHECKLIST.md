# Store Release Checklist

## App Identity

- App name: `Puttalam Drop`
- Android application ID: `com.ishi.grocerydelivery`
- iOS bundle ID: `com.ishi.grocerydelivery`
- Version: set in `pubspec.yaml` as `version: 1.0.0+1`

## Android / Google Play

1. Create the upload keystore:

   ```powershell
   keytool -genkeypair -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill in the passwords used when creating the key.
3. Keep `android/key.properties` and `android/app/upload-keystore.jks` private and backed up. They are ignored by git.
4. Build the Play Store bundle:

   ```powershell
   flutter build appbundle --release --build-name=1.0.0 --build-number=1
   ```

5. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.
6. In Play Console, enable Play App Signing, complete the store listing, Data safety, content rating, target audience, app access, and production release steps.

Notes:

- The Android release build targets API 35, which satisfies the current Google Play requirement for new mobile apps and updates.
- Do not add `READ_MEDIA_IMAGES` or `READ_EXTERNAL_STORAGE` for one-off uploads. The app uses the system picker through `image_picker`.
- The release build no longer uses the debug signing key. It requires `android/key.properties`.
- If Firebase Android auth/API integrations depend on SHA certificates, add the upload/app signing SHA-1 and SHA-256 values in Firebase Console.

## Cloudinary Upload Signing

Images upload to Cloudinary through signed direct uploads. The Flutter app never
contains the Cloudinary API secret.

1. Set the API secret in Firebase Secret Manager:

   ```powershell
   firebase functions:secrets:set CLOUDINARY_API_SECRET --project grocery-delivery-app-388bc
   ```

2. Configure the non-secret Function params for the same Cloudinary product
   environment. The simplest path is to let the Firebase CLI prompt for them
   on the first deploy:

   ```text
   CLOUDINARY_CLOUD_NAME
   CLOUDINARY_API_KEY
   ```

   You can also predefine them in the project Functions params env file used by
   the Firebase CLI.

3. Deploy Functions and Firestore rules before testing uploads:

   ```powershell
   firebase deploy --project grocery-delivery-app-388bc --only functions,firestore:rules
   ```

The signing Function restricts uploads to image resources, 8 MB maximum size,
`jpg`, `jpeg`, `png`, `webp`, `heic`, and `heif`, and server-generated folders
under `puttalam-drop/`.

## iOS / App Store

1. Use a Mac with Xcode 26 or later and a current Flutter stable SDK that supports Xcode 26 and iOS 26.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the Runner target, set your Apple Developer Team, and confirm the bundle ID is `com.ishi.grocerydelivery`.
4. Confirm signing and capabilities, including push notifications if you use Firebase Cloud Messaging.
5. Build an archive in Xcode or run:

   ```bash
   flutter build ipa --release --build-name=1.0.0 --build-number=1
   ```

6. Upload the archive/IPA to App Store Connect with Xcode Organizer or Transporter.
7. In App Store Connect, complete app information, screenshots, age rating, privacy policy URL, app privacy answers, TestFlight testing, and App Review submission.

Notes:

- The deployment target is iOS 13, matching the Firebase Apple SDK generation used by the current FlutterFire dependencies.
- `ios/Runner/PrivacyInfo.xcprivacy` is included in the Runner resources for UserDefaults access used by local storage.
- App Store Connect privacy answers must include the app and Firebase services.
  Use `STORE_DATA_DISCLOSURES.md` for the exact selections.

## Mandatory Privacy And Account Deletion

Implemented in the repository:

1. Public privacy policy at
   `https://grocery-delivery-app-388bc.web.app/privacy`.
2. Privacy Policy link in the customer Profile screen.
3. Password-confirmed in-app customer account deletion.
4. Public deletion request page at
   `https://grocery-delivery-app-388bc.web.app/delete-account`.
5. Admin review and verified deletion flow for public requests.
6. Firebase Auth/profile/support/notification/reset deletion, Firebase Storage
   cleanup, and closed-order/accounting anonymization.
7. Retention/deletion disclosure and scheduled cleanup: anonymized financial
   records expire after seven years and processed web requests after 90 days.
8. Store answer matrix in `STORE_DATA_DISCLOSURES.md`.

The Hosting site, Functions, Firestore rules, and Storage rules must be deployed
before these URLs and workflows are considered live.

## Production Security

- The source and Firestore rules no longer contain a bootstrap administrator backdoor.
- Delete any old Firebase Authentication account created with the former fixed debug administrator password, or reset it to a strong unique credential.
- Create the real Firebase administrator account and set only its Firestore profile to `role: "admin"`.
- New uploads use signed Cloudinary parameters from the `signCloudinaryUpload`
  Firebase Function. Never put the Cloudinary API secret in Flutter source.
- Old unsigned Cloudinary presets should be disabled after any legacy build is
  retired.
- Cloudinary URLs and public IDs discovered during deletion are removed from
  customer records and placed in the admin-only `legacy_media_cleanup` queue.
- Deploy Firestore rules, Storage rules, Cloud Functions, and Hosting before
  store review.

## Firebase API Key Troubleshooting

If Android logs show:

```text
Requests to this API securetoken.googleapis.com method google.identity.securetoken.v1.SecureToken.GrantToken are blocked
```

the Firebase API key is blocked by Google Cloud API restrictions.

For the Android key used by `com.ishi.grocerydelivery`, open Google Cloud Console > APIs & Services > Credentials, edit the Android API key, and make sure API restrictions include:

- Identity Toolkit API: `identitytoolkit.googleapis.com`
- Token Service API: `securetoken.googleapis.com`
- Firebase Installations API: `firebaseinstallations.googleapis.com`

For local debug/emulator builds, the debug certificate fingerprint is:

```text
SHA-1:   0B:78:BE:68:E6:42:A1:FF:E4:6A:7E:4A:63:5F:5E:78:CB:31:5A:65
SHA-256: 19:D7:E8:42:F7:DC:29:35:96:76:BF:56:A9:04:E1:92:2D:93:2E:E4:F3:9A:1B:CC:C8:83:00:8E:B2:AE:38:2C
```

After changing Firebase Android app SHA certificates, download the fresh `google-services.json` from Firebase Console and replace `android/app/google-services.json`.
