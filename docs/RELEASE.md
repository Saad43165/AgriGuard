# Release checklist

## 1. Rotate keys and use the proxy
See `functions/README.md`. Release builds must not contain API keys.

## 2. Application ID (Play Store rejects `com.example.*`)
Pick your ID, e.g. `pk.agriguard.app`, then change it in:

1. `android/app/build.gradle.kts` - `namespace` and `applicationId`
2. Move `android/app/src/main/kotlin/com/example/agriguard_fyp/MainActivity.kt`
   to the matching folder and update its `package` line
3. `android/app/src/main/AndroidManifest.xml` - the FileProvider `android:authorities`
   (`<applicationId>.fileprovider`) and the `package` attribute
4. `ios/Runner.xcodeproj` - `PRODUCT_BUNDLE_IDENTIFIER` (iOS only)
5. Firebase console > Project settings > add a new Android app with the new ID
   **and your release SHA-1/SHA-256**, download the new `google-services.json`
   into `android/app/`, then run `flutterfire configure` to refresh `lib/firebase_options.dart`
6. Google Sign-In: add the new SHA-1 in Firebase, otherwise Google login fails

Do this once, before the first Play upload - the ID cannot change afterwards.

## 3. Release signing
```bash
keytool -genkey -v -keystore ~/agriguard-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Create `android/key.properties` (git-ignored):
```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/home/you/agriguard-upload.jks
```
Back up the keystore and passwords somewhere safe. `build.gradle.kts` uses this
file automatically; without it, release builds fall back to the debug key.
Get the fingerprint for Firebase with
`keytool -list -v -keystore ~/agriguard-upload.jks -alias upload`.

## 4. Privacy policy
The text is in `assets/legal/privacy_policy.md` (shown in Settings > Privacy Policy).
Fill in your contact email, have it reviewed, and publish the same text at a
public URL (GitHub Pages works) - Play Console asks for that URL and for the
Data safety form (camera, photos, location, email, device ID).

## 5. Build
```bash
flutter build appbundle --release            # upload to Play Console
flutter build apk --release --split-per-abi  # for sideloading / testing
```

## 6. Final device test
Fresh install > register > verify email > scan (on-device and Advanced) >
History > reinstall and log in again (scans come back) > Urdu mode > airplane
mode (offline banner) > Delete account.
