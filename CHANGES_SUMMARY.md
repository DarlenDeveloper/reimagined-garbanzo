# Changes Summary - Buyer & Seller Apps

## Buyer App (purl-stores-app)

### 1. Data & Privacy Request Feature ✅
**File**: `lib/screens/privacy_security_screen.dart`
- Added delete account/data privacy request functionality
- Shows popup confirming request submission
- Logs user out after confirmation
- Redirects to sign-in screen using GoRouter

### 2. Terms & Privacy Acceptance ✅
**File**: `lib/screens/signup_screen.dart`
- Added checkbox requiring acceptance of Privacy Policy and Terms of Service
- Links open in external browser:
  - Privacy Policy: https://purlstores-za.web.app/privacy.html
  - Terms of Service: https://purlstores-za.web.app/terms.html
- Prevents signup without acceptance

### 3. iOS Notifications Fix ✅
**Files**: 
- `ios/Runner/AppDelegate.swift` - Added notification handlers
- `ios/Runner/Info.plist` - Added background modes for remote notifications

### 4. Splash Screen ✅
**Files**:
- `lib/screens/splash_screen.dart` - Created animated splash screen
- `pubspec.yaml` - Added flutter_native_splash configuration
- `SETUP_INSTRUCTIONS.md` - Complete setup guide

---

## Seller App (purl-admin-app)

### 1. Delete Account Feature ✅
**File**: `lib/screens/settings_screen.dart`
- Added "Delete Account" option in Settings > Account section
- Shows dialog confirming request submission
- Includes link to Privacy Policy
- Logs user out after confirmation
- Required for Apple App Store compliance

### 2. Terms & Privacy Acceptance ✅
**File**: `lib/screens/signup_screen.dart`
- Added checkbox requiring acceptance of Privacy Policy and Terms of Service
- Links open in external browser:
  - Privacy Policy: https://purlstores-za.web.app/privacy.html
  - Terms of Service: https://purlstores-za.web.app/terms.html
- Prevents signup without acceptance

### 3. iOS Notifications Fix ✅
**Files**:
- `ios/Runner/AppDelegate.swift` - Added notification handlers
- `ios/Runner/Info.plist` - Added background modes for remote notifications

### 4. Splash Screen Fix ✅
**Files**:
- `pubspec.yaml` - Added flutter_native_splash configuration
- `SETUP_INSTRUCTIONS.md` - Complete setup guide
- Uses existing `loading_screen.dart` which already has proper animations

---

## Setup Required

### For Both Apps:

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate splash screens**:
   ```bash
   dart run flutter_native_splash:create
   ```

3. **iOS Notifications** (Physical device required):
   - Open Xcode workspace
   - Enable "Push Notifications" capability
   - Enable "Background Modes" capability
   - Check "Remote notifications"
   - Upload APNs key to Firebase Console

4. **Test on physical iOS device** (simulator doesn't support notifications)

### Detailed Instructions:
- Buyer app: `purl-stores-app(buyer)/SETUP_INSTRUCTIONS.md`
- Seller app: `purl-admin-app(seller)/SETUP_INSTRUCTIONS.md`

---

## Key Features

### Apple Compliance
- ✅ Delete account feature (required for App Store)
- ✅ Privacy Policy links
- ✅ Terms of Service acceptance
- ✅ User data request handling

### iOS Notifications
- ✅ Foreground notifications
- ✅ Background notifications
- ✅ Notification tap handling
- ✅ APNs integration ready

### Splash Screen
- ✅ Native splash screens for Android & iOS
- ✅ Android 12+ support
- ✅ Proper positioning and scaling
- ✅ Smooth animations

---

## Testing Checklist

- [ ] Delete account logs user out (both apps)
- [ ] Cannot signup without accepting terms (both apps)
- [ ] Privacy/Terms links open correctly (both apps)
- [ ] iOS notifications work on physical device (both apps)
- [ ] Splash screen displays correctly (both apps)
- [ ] No misalignment issues in production (both apps)
