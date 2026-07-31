# TimeBox — Dev Notes & Setup

---

## ⬜ Outstanding Tasks

### App Display Name
- [ ] `android/app/src/main/AndroidManifest.xml` → change `android:label="timebox"` to `"TimeBox"`
- [ ] `ios/Runner/Info.plist` → set `CFBundleDisplayName` and `CFBundleName` to `TimeBox`

---

### Secrets / Credentials
- [ ] `lib/main.dart` line 29 — replace `'recaptcha_secret_key'` with the real reCAPTCHA v3 site key from Google Cloud Console (only needed if you ship a web build with App Check)
- [ ] Confirm `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present and listed in `.gitignore`

---

### Permissions

**Android** — add to `AndroidManifest.xml` inside `<manifest>`:
```xml
<!-- Required for notifications on Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**iOS** — add to `ios/Runner/Info.plist`:
```xml
<key>NSUserNotificationUsageDescription</key>
<string>TimeBox notifies you when a time block starts and to keep your streak alive.</string>
```

---

### iOS Home Screen Widget (WidgetKit)
- [ ] Xcode → add target **Widget Extension** → name `TimeBoxWidget`
- [ ] Add App Group `group.com.personal.timebox` to both `Runner` and `TimeBoxWidget` targets
- [ ] Flutter side: write current/next task JSON to the shared App Group container on every block change
- [ ] SwiftUI `TimeBoxWidgetEntryView`: task title, time range, progress bar
- [ ] Support sizes: `systemSmall`, `systemMedium`
- [ ] Call `WidgetCenter.shared.reloadAllTimelines()` from the Flutter → native channel after any block update

---

### watchOS Companion
- [ ] Xcode → add target **Watch App for iOS App** → name `TimeBoxWatch`
- [ ] `watch_connectivity` is already in `pubspec.yaml` — wire `WatchConnectivity().sendMessage({...})` from Flutter when the active block changes
- [ ] SwiftUI `ContentView`: task title, countdown timer, complete button that sends a reply message back to Flutter

---

### Android Home Screen Widget (AppWidget)
- [ ] Create `android/app/src/main/res/xml/timebox_widget_info.xml`
- [ ] Create `android/app/src/main/res/layout/timebox_widget.xml` (task title + time label)
- [ ] Create `android/app/src/main/kotlin/.../TimeBoxWidget.kt` extending `AppWidgetProvider`
- [ ] Flutter writes current task to `SharedPreferences`; widget reads on `ACTION_APPWIDGET_UPDATE`
- [ ] Register the widget receiver in `AndroidManifest.xml`

---

### Wear OS Companion
- [ ] Android Studio → new module `wearapp` (`compileSdk = 35`, add `wearable` dependency)
- [ ] Use `DataClient` / `ChannelClient` for Flutter ↔ Wear communication
- [ ] Single screen: current task card with title, time remaining, tick-off button

---

## Firebase Setup (required before first run)

### Step 1 — Create a Firebase project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `timebox` → Create project

### Step 2 — Add your platforms

**iOS**
1. Console → Project settings → Add app → Apple (iOS)
2. Bundle ID: `com.personal.timebox`
3. Download `GoogleService-Info.plist` → place it in `ios/Runner/`

**Android**
1. Console → Project settings → Add app → Android
2. Package name: `com.personal.timebox`
3. Download `google-services.json` → place it in `android/app/`

### Step 3 — Enable Authentication

1. Console → Build → **Authentication** → Get started
2. Sign-in method tab → Enable **Email/Password**

### Step 4 — Create Firestore database

1. Console → Build → **Firestore Database** → Create database
2. Start in **production mode** → choose a region close to your users
3. Go to **Rules** tab and paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

### Step 5 — Run FlutterFire configure

```bash
# Install CLI once (globally)
dart pub global activate flutterfire_cli

# Inside this project root
flutterfire configure --project=<your-firebase-project-id>
```

This generates `lib/firebase_options.dart` automatically.

### Step 6 — Update main.dart

Open `lib/main.dart` and follow the two-line instructions in the **STEP 6** comment block
(add the import and replace the try/catch with `Firebase.initializeApp`).

---

## Firestore data structure

```
/users/{uid}/
  timeBlocks/{blockId}   ← Timeline + Planner blocks
  goals/{goalId}         ← Goals screen items
  settings/app           ← App preferences
```

---

## Running the app

```bash
flutter pub get
flutter run
```

---

## Calendar sync (optional)

Calendar sync is scaffolded but not wired. Follow the steps below for your target platform(s), then create `lib/services/calendar_service.dart` that calls the relevant package APIs.

---

### iOS / Android — `device_calendar`

#### 1. Add the package

```yaml
# pubspec.yaml
dependencies:
  device_calendar: ^4.3.0
```

#### 2. iOS permissions

Add both keys to `ios/Runner/Info.plist`:

```xml
<key>NSCalendarsUsageDescription</key>
<string>TimeBox adds your scheduled blocks to Calendar.</string>
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>TimeBox adds your scheduled blocks to Calendar.</string>
```

#### 3. Android permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.READ_CALENDAR"/>
<uses-permission android:name="android.permission.WRITE_CALENDAR"/>
```

#### 4. Usage skeleton

```dart
import 'package:device_calendar/device_calendar.dart';

final _plugin = DeviceCalendarPlugin();

// Request permission
final permResult = await _plugin.requestPermissions();

// Retrieve writable calendars
final cals = await _plugin.retrieveCalendars();
final calendar = cals.data!.firstWhere((c) => !c.isReadOnly!);

// Create an event from a TimeBlock
await _plugin.createOrUpdateEvent(Event(
  calendar.id,
  title: block.title,
  start: TZDateTime.from(block.startTime, local),
  end:   TZDateTime.from(block.endTime,   local),
));
```

---

### Web — Google Calendar API via `googleapis`

#### 1. Google Cloud Console

1. Go to [https://console.cloud.google.com](https://console.cloud.google.com)
2. Create (or select) a project → **APIs & Services → Library**
3. Search **Google Calendar API** → Enable it
4. **APIs & Services → OAuth consent screen**
    - User type: **External** → fill App name, support email, developer contact
    - Scopes: add `https://www.googleapis.com/auth/calendar.events`
    - Add your email as a test user (while in Testing mode)
5. **APIs & Services → Credentials → Create credentials → OAuth client ID**
    - Application type: **Web application**
    - Authorised JavaScript origins: `http://localhost` (dev) + your production domain
    - Copy the **Client ID** — you will need it below

#### 2. Add packages

```yaml
dependencies:
  googleapis: ^13.2.0
  google_sign_in: ^6.2.0          # already in this project
```

#### 3. Wire the Client ID

In `web/index.html` add inside `<head>`:

```html
<meta name="google-signin-client_id"
      content="YOUR_CLIENT_ID.apps.googleusercontent.com">
```

And pass the same value when constructing `GoogleSignIn`:

```dart
GoogleSignIn(
  clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
  scopes: ['https://www.googleapis.com/auth/calendar.events'],
)
```

#### 4. Usage skeleton

```dart
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

final _gsi = GoogleSignIn(scopes: [gcal.CalendarApi.calendarEventsScope]);

Future<void> addBlockToCalendar(TimeBlock block) async {
  final account = await _gsi.signIn();
  if (account == null) return;

  final client = await _gsi.authenticatedClient();
  final api = gcal.CalendarApi(client!);

  await api.events.insert(
    gcal.Event(
      summary: block.title,
      start: gcal.EventDateTime(dateTime: block.startTime, timeZone: 'UTC'),
      end:   gcal.EventDateTime(dateTime: block.endTime,   timeZone: 'UTC'),
    ),
    'primary',
  );
}
```

> **Note:** `extension_google_sign_in_as_googleapis_auth` provides the
> `authenticatedClient()` helper — add it to `pubspec.yaml` too:
> ```yaml
> extension_google_sign_in_as_googleapis_auth: ^2.0.12
> ```

---

### Firestore data structure update

Once calendar sync is implemented, store the resulting Google/Apple event ID on the block so you can update or delete it later:

```
/users/{uid}/timeBlocks/{blockId}
  ...existing fields...
  calendarEventId: String?   ← store after successful calendar write
```
