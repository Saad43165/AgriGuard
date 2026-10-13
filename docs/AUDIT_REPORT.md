# AgriGuard — Full App Audit & Recommendations

Audit date: 2026-10-13 · Branch: `claude/modest-cori-nwfk79`

Legend: ✅ = fixed on this branch · ⬜ = recommended (not yet done)
Priority: **P0** blocker · **P1** fix before release / demo · **P2** important · **P3** polish

How it was checked: `flutter analyze` + `flutter test` on Flutter stable, plus a
manual read of auth, database, repository, AI services, settings, capture and
screen code. **Not** checked: running on a real phone/emulator (no Android SDK in
the review environment) — every item below still needs a manual test on device.

---

## Round 2 status (follow-up work)

| Item | Status |
|------|--------|
| API keys out of the APK | ✅ **Code done, deploy needed.** `functions/` is a Cloud Functions proxy (token check, per-user rate limits, keys as server secrets); the app uses it as soon as `API_PROXY_URL` is set (`lib/core/services/api_gateway.dart`). You must deploy it and then **delete the keys from `.env`** - see `functions/README.md`. Until then the app still works in direct mode. |
| Urdu right-to-left + font | ✅ Locale/direction follow the language switch; 28 padding, 44 alignment and 29 `Positioned` usages now mirror automatically; Noto Nastaliq Urdu loaded through `google_fonts` (downloads on first Urdu use, then cached - **bundle the .ttf in `assets/fonts` if Urdu must work offline on first launch**). ⬜ Still needs a screen-by-screen visual check on a phone. |
| History restored on a new phone / reinstall | ✅ `ScanRepository.restoreFromCloud()` runs from Home; unsynced scans are uploaded first. Note: a scan deleted while offline could reappear. |
| Photos as files, not SQLite text | ✅ Compressed JPEGs (max 1024 px) in `scan_images/`; old rows are migrated automatically; cloud backup reads from the file. |
| Play Store prep | ✅ Release-signing config + `docs/RELEASE.md` (package-name steps), in-app Privacy Policy (`assets/legal/privacy_policy.md`). ⬜ **You** still must: pick the real application ID, create the keystore, fill in the policy contact email and publish it at a URL. Gradle changes are untested (no Android SDK here). |
| Low-confidence result | ✅ Under 60% confidence: "not sure, retake photo" alert, and treatment advice is hidden. |
| AI-guidance warning | ✅ On the on-device and Advanced result screens next to treatments. |
| Offline banner | ✅ Enabled app-wide, translated, appears after ~40 s offline. |
| Icon-button accessibility | ✅ 26 `IconButton`s got tooltips (screen-reader labels). ⬜ Tap-only icons built with `GestureDetector`, and Urdu tooltips, remain. |
| Hardcoded colours | 🟡 241 of 478 hex values replaced by `AppColors` tokens (no visual change). ⬜ The remaining ~237 one-off shades and dark-mode variants need design decisions. |
| Inline Urdu/English text | 🟡 230 of 261 ternaries moved into `en.json`/`ur.json` (as `ui_*` keys). ⬜ 31 more (strings with `$` interpolation, escapes or multi-line) remain. |
| Tests + CI | ✅ Translation-key test (found 2 missing keys), API gateway tests, proxy tests, GitHub Actions workflow. |

---

## 0. Things YOU must do now (cannot be done from code)

| # | Pri | Action |
|---|-----|--------|
| 0.1 | **P0** | **Rotate all API keys.** `.env` (Groq key, Plant.id keys, 2 spare Plant.id keys in comments) was committed to git, and a WeatherAPI key was hardcoded in `weather_service.dart`. They stay readable in the git history forever. Generate new keys in the Groq, Plant.id and WeatherAPI dashboards and revoke the old ones. |
| 0.2 | **P0** | **Back up your local `.env` before pulling this branch.** This branch stops tracking `.env`, so `git pull` will delete your local copy. Copy it somewhere first, then restore it (or rebuild it from `.env.example`). Add `WEATHER_API_KEY=` to it — the weather key now comes from `.env`. |
| 0.3 | **P0** | **Deploy the Firebase security rules** added in `firestore.rules` / `storage.rules`: `firebase deploy --only firestore:rules,storage`. Without rules, Firestore is either wide open (test mode) or locked (production mode). The new rules let each user read/write only their own data. |
| 0.4 | P1 | Change the Android `applicationId` / `namespace` from `com.example.agriguard_fyp` (Play Store rejects `com.example.*`). Requires re-registering the app in Firebase and a new `google-services.json`. |
| 0.5 | P1 | Create a real release keystore. `android/app/build.gradle.kts` signs release builds with the **debug** key. |

---

## 1. Build / Compile — ✅ fixed

| Pri | Issue | Status |
|-----|-------|--------|
| **P0** | **The app did not compile on Linux/macOS/CI (27 errors).** Folders were named `Profile/`, `Profile/Components/`, `Settings/`, `Settings/presentation/Tiles/`, `Navbar/`, but imports used lowercase paths. It only built on Windows because Windows ignores case. | ✅ Folders renamed to lowercase (also the Dart convention). `flutter analyze` → **0 errors**. |
| P2 | 49 imports like `'../../../../../core/...'` climbed above `lib/` and only worked because Dart clamps the path. | ✅ Converted to `package:agriguard_fyp/...` imports. |
| P2 | `sqflite` and `path` were used directly but not declared in `pubspec.yaml`. | ✅ Declared. |
| P3 | Stray empty file `libcoreservicesanalysisai_analysis_service.dart` in repo root. | ✅ Removed. |

---

## 2. Security & Privacy

| Pri | Issue | Status |
|-----|-------|--------|
| **P0** | `.env` with live keys tracked in git (despite being in `.gitignore`). | ✅ Untracked; added `.env.example`. ⬜ Rotate keys (0.1). |
| **P0** | **API keys are bundled into the APK** *(proxy code added in Round 2 - deploy it)* (`.env` is listed under `flutter: assets:`). Anyone can unzip the APK and use your Groq/Plant.id credit. | ⬜ **Move the Groq/Plant.id/Weather calls behind a backend** (Firebase Cloud Functions or a small server). The app calls your function with the user's Firebase ID token; the function holds the keys and enforces per-user rate limits. This is the only real fix — obfuscation does not help. |
| **P0** | No Firestore/Storage rules in the repo. | ✅ Added `firestore.rules` + `storage.rules`. ⬜ Deploy them (0.3). |
| P1 | WeatherAPI key hardcoded in Dart source. | ✅ Now read from `WEATHER_API_KEY` in `.env`. |
| P1 | Requested `MANAGE_EXTERNAL_STORAGE` ("All files access") on every PDF save because of a hardcoded `androidVersion = 33`. Google Play rejects apps that use this without a strong reason, and users see a scary settings screen. | ✅ Removed. PDF save now tries to write first and asks for legacy storage permission only on Android ≤ 9. Storage permissions are capped with `maxSdkVersion`. |
| P1 | `android:usesCleartextTraffic="true"` allowed plain HTTP (no HTTP URLs are used). | ✅ Removed. |
| P1 | iOS `Info.plist` had **no** camera/photo/location usage strings — iOS kills the app the moment the camera or gallery opens. | ✅ Added `NSCameraUsageDescription`, photo library, location, microphone strings. |
| P2 | Account deletion left data behind: farm crops (`users/{uid}/crops`), cloud scan backups (`onDeviceScans`, `advancedScans`) and local SQLite scans. Also crashed for users with more than ~500 scans (a Firestore `WriteBatch` was re-used after `commit()`). | ✅ All of these are deleted now, in fresh batches. |
| P2 | Firebase `apiKey` values in `firebase_options.dart` / `google-services.json` are public by design, but should be restricted. | ⬜ In Google Cloud Console → Credentials, restrict the Android key to your package name + SHA-1, and turn on **Firebase App Check**. |
| P2 | 379 `debugPrint`/`print` calls log user IDs, emails, API error bodies. | ⬜ Replace with a small logger that does nothing in release builds (`if (kDebugMode)`), and remove `print(` (49 `avoid_print` lints). |
| P3 | Guest scan limit (5) is stored in SharedPreferences, so clearing app data resets it. | ⬜ Acceptable for an FYP; for production use Firebase Anonymous Auth + a server-side counter. |
| P3 | Privacy policy / terms screens. | ⬜ Play Store requires a hosted privacy policy URL because you use the camera, location and accounts. Link it from Settings → Privacy. |

---

## 3. Backend / Data Logic

| Pri | Issue | Status |
|-----|-------|--------|
| **P1** | **Google sign-in wiped user data on every login.** `_upsertUserProfileFromAuth` re-wrote `fullName`, `profileImageUrl`, `createdAt` and `crops: []` each time, so edited names/photos reset and "Member since" moved to today. | ✅ Creates the profile once; on later logins it only updates `lastUpdated`/`emailVerified` and fills fields that are empty. |
| **P1** | **Google users could not delete their account** — the flow always asked for a password they don't have. | ✅ Google users now re-authenticate with Google; email users with their password. Also handles the newer `invalid-credential` error code. |
| P1 | "Clear history" reset counters but **left all real cloud scans** (`onDeviceScans`, `advancedScans`) and wiped **every** account's local scans on a shared device. Cloud delete was capped at 500 docs. | ✅ Deletes this user's scans in all three locations, page by page; local delete is per-user. |
| P1 | Scans are synced with the full photo as base64 in the Firestore document. Firestore documents are limited to **1 MiB**, so large photos made the sync fail silently. | ✅ Large images are left out of the cloud copy. ⬜ Better: upload a compressed image/thumbnail to Firebase Storage and save only its URL. |
| P1 | **Cloud sync is write-only.** Scans are written to Firestore but never read back, so reinstalling the app or logging in on a new phone shows an empty history. | ⬜ On login, when SQLite is empty, download `onDeviceScans`/`advancedScans` where `userId == uid` into SQLite. |
| P2 | Full-size images stored as base64 `TEXT` in SQLite. Android's cursor window is ~2 MB, so a very large image row can throw "Row too big to fit into CursorWindow" and break History. Decoding base64 on every card build also makes scrolling slow. | ⬜ Store images as files under the app documents folder and keep only the path (plus a small thumbnail) in SQLite. |
| P2 | Three overlapping scan stores: `users/{uid}/scans` (legacy), top-level `onDeviceScans`, top-level `advancedScans`. | ⬜ Settle on one layout, ideally `users/{uid}/scans/{scanId}` with a `type` field — simpler rules, simpler deletion. |
| P2 | `scanCount` on the user document is only incremented by legacy code and reset by "Clear history", so it can drift. | ⬜ Compute counts from the scans (SQLite already does) or keep the counter in a Cloud Function. |
| P2 | Unsynced scans are retried only when `syncUnsyncedScans()` is called. | ⬜ Call it on app start and when connectivity returns. |
| P2 | Groq/Plant.id calls have timeouts but no retry/back-off and no 429 handling; several errors are matched by searching the error *text*. | ⬜ Check `statusCode` (401/403/429/5xx) explicitly, show a friendly message, and retry 5xx once. |
| P3 | Chatbot history (last 20 messages) is sent with every request. | ⬜ Fine for now; summarise older turns if token cost grows. |

---

## 4. App Logic / Bugs

| Pri | Issue | Status |
|-----|-------|--------|
| P1 | Theme "System" mode was computed once at start and ignored the phone switching light/dark. | ✅ `MaterialApp` now uses `theme` + `darkTheme` + `themeMode`. |
| P1 | `BuildContext` used after `await` in the capture flow and Settings ("Clear cache") — can crash if the user leaves the screen during processing. | ✅ Guarded with `context.mounted`. |
| P2 | Two language systems: `TranslationService` (pref key `app_language`) and `LocalizationService` (pref key `isUrdu`). Only the first is used. | ✅ The unused service is no longer registered. ⬜ Delete `localization_service.dart`. |
| P2 | FAQ screen showed literal `result`/`results`/`clear_filters` in Urdu (missing translation keys). Duplicate keys `top_diseases` and `crop_calendar` in `en.json`/`ur.json`. | ✅ Keys added; duplicates removed. |
| P2 | `t.get(key)` returns the key itself when a translation is missing, so code like `t.get('x') ?? 'Fallback'` never shows the fallback. | ⬜ Make `get` return `null` on miss (or add `get(key, fallback:)`) and add a test that checks all keys exist in both files. |
| P2 | "Clear Cache" in Settings only clears the in-memory image cache (frees no storage) and shows a fake 500 ms delay. | ⬜ Also delete temporary files (`getTemporaryDirectory()`), the `flutter_cache_manager` cache and old PDF exports, and show how many MB were freed. |
| P2 | README advertised 52 classes / 12+ species and the "PlantHealth API"; the model actually has **35 classes**, and the cloud API is Plant.id. | ✅ README corrected. |
| P3 | ~4,000 lines of unreachable code (see §8). | ⬜ Delete. |

---

## 5. UI / UX

| Pri | Recommendation |
|-----|----------------|
| **P1** | **Urdu is shown left-to-right.** No `Directionality`/`locale` is set anywhere, so Urdu text aligns left, back arrows and list icons sit on the wrong side, and mixed text wraps badly. Set `locale: Locale('ur')` + `supportedLocales` + `GlobalMaterialLocalizations.delegates` in `MaterialApp` (or wrap the app in `Directionality(textDirection: TextDirection.rtl)` when Urdu is on), then replace `EdgeInsets.only(left/right)` with `EdgeInsetsDirectional.only(start/end)` and `Alignment.centerLeft` with `AlignmentDirectional.centerStart`. Test every screen in Urdu. |
| **P1** | **Use a proper Urdu font.** The system font renders Urdu in Naskh with poor spacing. Bundle *Noto Nastaliq Urdu* (or *Jameel Noori Nastaleeq*) and apply it when Urdu is on; increase line height (~1.6–1.8). |
| P1 | **Offline experience.** `ConnectivityBanner` exists but is never used. Wrap the app with it (via `MaterialApp.builder`) and, when offline, disable Advanced Scan / Chatbot with a clear "needs internet" message instead of a long timeout. On-device scan should be presented as the offline option. |
| P1 | **Result trust & safety.** Show the confidence clearly and, below ~60%, say "Not sure — retake photo or try Advanced Scan" instead of showing a diagnosis. Add a short disclaimer on results/treatments ("AI guidance — confirm with a local agriculture officer before using chemicals") and show pesticide safety notes (PPE, waiting period). |
| P2 | **Photo guidance before capture.** Show the existing help images (`assets/images/help/*`) as a one-time tip on the camera screen: one leaf, fills the frame, daylight, no blur. Add a blur/darkness check before running the model. |
| P2 | **Supported crops.** The model only knows 35 classes; tell users which crops are supported on the capture screen and send unsupported crops to Advanced Scan automatically. |
| P2 | **Empty, loading and error states.** Make them consistent: skeleton loaders for lists (History, Farm Diary, Profile), one shared error widget with a Retry button, and friendly text instead of `'Error: ${e.toString()}'` (several screens print raw exceptions to users). |
| P2 | **Destructive actions.** "Clear history" and "Delete account" should say exactly what will be deleted (local + cloud) and offer an export first. Add an *Undo* snackbar for single-scan deletion in History. |
| P2 | **Accessibility.** There are **0** `Semantics` widgets and only 11 tooltips. Add `tooltip`/`semanticLabel` to every icon-only button (camera, flash, share, language toggle), make tap targets at least 48×48, check contrast of green-on-green text, and make sure layouts survive font scale 1.3–2.0 (many fixed heights). |
| P2 | **Notifications.** `NotificationService.initialize()` asks for notification permission on first launch, before the user knows why. Ask when the user turns on reminders instead. |
| P3 | Haptics are used in some places only; use them consistently for capture, success and destructive actions. |
| P3 | Onboarding: add a "Skip" and a final screen that asks for language + camera permission with an explanation. |
| P3 | Add pull-to-refresh on Home, History and Farm Diary. |

---

## 6. Visual Design / Design System

| Pri | Recommendation |
|-----|----------------|
| P2 | **398 hardcoded `Color(0x…)` values and 49 `Colors.green/red/…`** outside `app_themes.dart`. Many dialogs define their own greens/blues/oranges, so screens look slightly different and dark mode breaks in places. Use `AppColors` / `Theme.of(context).colorScheme` everywhere and add the missing semantic colours (e.g. `severityLow/Medium/High`). |
| P2 | Dark theme: complete `appBarTheme`, `cardTheme`, `dialogTheme`, `inputDecorationTheme`, `snackBarTheme`, `bottomSheetTheme` so widgets don't need per-screen `isDark ? … : …` checks. |
| P2 | **241 inline `isUrdu ? 'اردو' : 'English'` strings** bypass the translation files. Move them into `en.json`/`ur.json` so texts are consistent and easy to edit. |
| P2 | Typography: define a text scale in the theme (`displaySmall`, `titleMedium`, `bodyMedium`, `labelSmall`) and use it instead of ad-hoc `fontSize:` values. |
| P3 | Spacing: `app_measurements.dart` exists — use it consistently (4/8/12/16/24 spacing scale, one corner radius set). |
| P3 | Severity colours: use the same green → amber → red scale in Results, History cards, Analytics and the PDF report. |
| P3 | App icon / splash: add a monochrome icon for Android 13 themed icons, and use `flutter_native_splash` so the native splash matches the Flutter splash. |

---

## 7. Architecture & Code Quality

| Pri | Recommendation |
|-----|----------------|
| P2 | Several files are 800–1,100 lines (`add_crop_sheet.dart`, `farm_diary_screen.dart`, `chatbot_widgets.dart`, `translation_service.dart`). Split UI into smaller widgets and move Firestore calls out of screens (`farm_diary_screen.dart` talks to Firestore directly) into a `CropRepository`. |
| P2 | Services are created with `new` in many places (`ScanRepository()`, `AuthService()`, `GuestService()`). Provide them once via `Provider` so they can be mocked in tests. |
| P2 | Scan data travels as `Map<String, dynamic>` with many alternative keys (`plantName`/`plant`/`data.plant`…). Use the `ScanModel`/`DiagnosisResult` classes end-to-end. |
| P2 | `TranslationService` still has large hardcoded legacy maps in Dart in addition to the JSON files. Move everything into JSON. |
| P3 | Rename PascalCase file names to snake_case (8 `file_names` lints, e.g. `AdvancedOptionCard.dart`, `SeverityResult.dart`). |
| P3 | Remaining analyzer findings (102, all warnings/infos): unused variables/methods (e.g. `home_screen.dart` `_getGreeting`, `results_screen.dart` `_buildTop3Alternatives`), 49 `avoid_print`, 6 missing braces, 3 deprecated `geolocator`/`Switch` APIs. |
| P3 | Add `flutter_lints` stricter rules once warnings are cleared (e.g. `prefer_const_constructors`, `use_build_context_synchronously` as error). |
| P3 | `.kiro/specs/agriguard-issues/tasks.md` is out of date (most items are already fixed) — update or remove it. |

---

## 8. Dead code to delete (unreachable from `main.dart`)

These files are never imported by the running app (I was not permitted to delete
them from this environment — please remove them yourself):

```
lib/core/services/scan_service.dart
lib/core/services/localization_service.dart
lib/features/result_screen/presentation/utils/scan_manager.dart
lib/features/result_screen/presentation/utils/results_helper.dart
lib/features/result_screen/presentation/components/section_header.dart
lib/features/advance_result_screen/utils/advance_pdf_generator.dart
lib/features/advance_result_screen/utils/advance_share_handler.dart
lib/features/advance_result_screen/widgets/result_action_button.dart   (1,144 lines)
lib/features/advance_result_screen/widgets/additional_info_card.dart
lib/features/advance_result_screen/widgets/section_card.dart
lib/features/advance_search_screen/service/plantnet_service.dart
lib/features/advance_search_screen/widgets/AdvancedOption.dart
lib/features/auth/forgot_password/widgets/app_bar.dart
lib/features/auth/register/utils/snackbar_utils.dart
lib/features/help_support/widgets/section_header.dart
lib/features/home/screens/weather/models/weather_types.dart
lib/features/settings/presentation/components/settings_header.dart
lib/features/settings/presentation/profile_screen.dart                 (duplicate ProfileScreen)
assets/models/plant_species_final_quantized.tflite                    (8.6 MB, unused)
assets/models/labels.txt                                               (unused)
```

Keep but wire in: `lib/core/widgets/connectivity_banner.dart` (see §5) and
`lib/features/settings/presentation/diagnostics/diagnostics_screen.dart`
(show only in debug builds).

---

## 9. Testing

| Pri | Recommendation |
|-----|----------------|
| P1 | There is **one** smoke test. Add unit tests for the logic that decides results: `DiseaseLabelParser`, `DiseaseOutputProcessor` (top-k, thresholds), `LeafDetector` decision rule, `SeverityPixelAnalyzer`, `ScanModel.fromMap/toMap` round-trip, `ScanDatabase` migrations (use `sqflite_common_ffi`). |
| P1 | Add a test that every translation key used in code exists in both `en.json` and `ur.json`. |
| P2 | Widget tests for Login validation, History filtering, Farm Diary add/delete (with `fake_cloud_firestore` + `firebase_auth_mocks`). |
| P2 | Model accuracy check: keep a small labelled test image set and record top-1/top-3 accuracy each time the model changes — useful for your FYP report too. |
| P2 | Add GitHub Actions CI: `flutter analyze` + `flutter test` on every push. (This would have caught the case-sensitivity build break.) |

---

## 10. Release Readiness Checklist

- [ ] Keys rotated, backend proxy for AI/Weather APIs (§2)
- [ ] Firestore/Storage rules deployed, App Check on (§2)
- [ ] Real `applicationId`, release keystore, version bumped (`pubspec.yaml` is still `1.0.0+1`)
- [ ] Privacy policy URL + Play Console Data Safety form (camera, location, email, photos)
- [ ] Urdu RTL + Urdu font (§5)
- [ ] Cloud restore of history on new device (§3)
- [ ] Tested on: low-end Android (2–3 GB RAM), Android 10, 13, 14/15; iPhone if shipping iOS
- [ ] Debug-only tiles hidden; logs silenced in release
- [ ] `flutter build apk --release --split-per-abi` (smaller downloads; TFLite models are ~22 MB)
