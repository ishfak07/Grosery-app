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

- The Android release build targets API 35, which is required for new Google Play submissions from August 31, 2025.
- The release build no longer uses the debug signing key. It requires `android/key.properties`.
- If Firebase Android auth/API integrations depend on SHA certificates, add the upload/app signing SHA-1 and SHA-256 values in Firebase Console.

## iOS / App Store

1. Use a Mac with Xcode 16 or later.
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

- `ios/Runner/PrivacyInfo.xcprivacy` is included in the Runner resources for UserDefaults access used by local storage.
- App Store Connect privacy answers must include the app and third-party services. This app uses Firebase, Cloudinary image upload, account/order data, phone numbers, addresses, uploaded images/receipts, support messages, and push notification tokens.

## Production Security

- Do not publish with the debug bootstrap admin as your only admin path. Release builds disable it, so create the real Firebase admin user before launch.
- Change any Firebase admin account that was created with the old debug password.
- Review the Cloudinary unsigned upload preset and restrict it as much as possible, or move uploads behind a signed backend endpoint.
- Deploy Firestore rules and Cloud Functions before store review.
