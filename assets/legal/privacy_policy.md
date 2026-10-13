# AgriGuard Privacy Policy

Last updated: 13 October 2026

> DRAFT: This policy describes how the app works today. Replace the contact
> details below and have it reviewed before publishing to an app store.

## 1. What we collect

**Account details.** When you register: name, email address and password
(handled by Firebase Authentication; we never see your password). Optional
profile details: phone number, location (text you type), farm size and
profile photo. If you sign in with Google we receive your name, email and
profile photo from Google.

**Plant photos and results.** Photos you take or choose for diagnosis, the
result (plant, disease, severity, confidence, advice) and the date. They are
stored on your phone. If you are signed in, a backup copy of each scan,
including a compressed copy of the photo, is stored in your private area of
Google Firebase (Cloud Firestore) so it can be restored on a new phone.

**Farm diary.** Fields and crops you add are stored in your Firebase account.

**Location.** If you allow location access, your approximate position is used
to show local weather. It is sent to the weather provider and is not stored by us.

**Chat messages.** Messages and photos you send to the AgriBot assistant.

**Notifications.** A device token so reminders can be delivered.

**Guest mode.** Guests can scan without an account. Guest scans stay on the phone.

## 2. Who receives data

| Service | Data sent | Purpose |
|---|---|---|
| Google Firebase (Auth, Firestore, Messaging) | Account details, backups of scans, farm diary, device token | Sign-in, backup, reminders |
| Plant.id | Plant photo (Advanced Scan, chat photo analysis) | Plant and disease identification |
| Groq | Text of your questions and scan results; photos for AI analysis | AI advice and chat |
| WeatherAPI.com | City name or coordinates | Local weather |

On-device scans run entirely on your phone; the photo is not uploaded for the
diagnosis itself. We do not sell your data or use it for advertising.

## 3. Your choices

* **Delete scan history:** Settings > Clear History removes your scans from the phone and from the cloud backup.
* **Delete your account:** Settings > Delete Account permanently removes your profile, farm diary, cloud scan backups and local scans.
* **Permissions:** you can withdraw camera, photo, location and notification permissions at any time in your phone settings.

## 4. Security

Data is sent over encrypted connections. Cloud data is protected by Firebase
security rules so that each user can only access their own records. No method
of storage is perfectly secure.

## 5. Important notice about advice

Diagnoses and treatment suggestions are automated and may be wrong. Confirm
with a local agriculture officer before applying chemicals, and follow product labels.

## 6. Children

AgriGuard is not directed at children under 13.

## 7. Contact

Questions or deletion requests: **[your-email@example.com]**
