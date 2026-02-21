# START HERE - Courier App Setup

## Current Status
The Purl Courier app is 95% complete. All screens, authentication flow, and verification process are implemented. However, **Google Sign-In is not working** because the SHA-256 certificate hasn't been properly added to Firebase.

## Why Google Sign-In Fails
Google Sign-In requires an Android OAuth client with your app's SHA-256 certificate fingerprint. Currently, the `google-services.json` file only has a web client (client_type: 3) but is missing the Android client (client_type: 1).

## What You Need to Do

### Step 1: Add SHA-256 to Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: **purlstores-za**
3. Click gear icon → **Project Settings**
4. Scroll to **Your apps** section
5. Find **Purl Courier** app (package: `com.example.purl_courier_app`)
6. Click **Add fingerprint**
7. Paste this SHA-256:
   ```
   EA:EE:D1:C9:8D:A9:7E:F1:48:06:5C:F2:F3:47:C9:EF:D5:D7:86:D6:4F:BC:CB:DD:6F:94:74:5B:66:9D:C2:12
   ```
8. Click **Save**

### Step 2: Download Updated google-services.json
1. Still in Firebase Console → Project Settings
2. Scroll to **Purl Courier** app
3. Click **Download google-services.json**
4. Replace the file at: `purl_courier_app/android/app/google-services.json`

### Step 3: Verify the File
Open the new `google-services.json` and confirm it has an oauth_client with `"client_type": 1` like this:
```json
"oauth_client": [
  {
    "client_id": "255612064321-XXXXXXXXXX.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.purl_courier_app",
      "certificate_hash": "eaeed1c98da97ef148065cf2f347c9efd5d786d64fbccbdd6f94745b669dc212"
    }
  },
  {
    "client_id": "255612064321-8p09as8bg59k9nph3p7n7dp6p1nk50vg.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

### Step 4: Rebuild and Test
1. Stop the running app completely
2. Run: `flutter clean` (optional but recommended)
3. Run: `flutter run`
4. Test Google Sign-In - it should work now!

## What's Next After Google Sign-In Works

### 1. Phone Verification (Currently Skipped)
- Currently using dummy data that auto-proceeds
- Need to implement real SMS verification
- Options:
  - Firebase Phone Auth (free tier: 10K/month)
  - Africa's Talking (good for African markets)
  - Twilio (popular, reliable)

### 2. Admin Panel for Courier Verification
- Couriers submit documents and wait for approval
- Need admin interface to:
  - View pending courier applications
  - Review ID photos and face scan videos
  - Approve or reject with reason
  - Can be built as:
    - Web admin panel (Flutter Web or React)
    - Seller app feature (add admin role)
    - Firebase Console manual updates (temporary)

### 3. iOS Setup
- Add GoogleService-Info.plist for iOS
- Test on iOS simulator/device
- Add iOS SHA-256 if needed

### 4. Delivery Order System
- Create order assignment logic
- Real-time order notifications
- Route optimization
- Delivery tracking
- Earnings calculation

### 5. Testing & Polish
- Test complete onboarding flow
- Test camera capture on real device
- Test file uploads to Firebase Storage
- Handle edge cases and errors
- Add loading states and animations

## Current Implementation Summary

### ✅ Completed Features
- Black & white theme with Inter font
- Splash screen (4 seconds, black background)
- Welcome screen (rounded square logo)
- Sign In & Apply screens
- Email/Password authentication
- Google Sign-In (needs SHA-256 fix)
- Email verification flow
- Profile completion for Google users
- Phone verification (dummy/skipped)
- Document verification with:
  - ID photos (camera or gallery)
  - Face scan (10s video with circular guide)
  - Vehicle details
  - Next of kin information
- Pending verification screen (real-time updates)
- Main app with 4 tabs (Home, Directions, Earnings, Profile)
- Firebase integration (Auth, Firestore, Storage)
- Onboarding resume logic

### ⏳ Pending Features
- Google Sign-In (waiting for SHA-256 setup)
- Real phone verification
- Admin verification panel
- Delivery order system
- iOS configuration
- Production deployment

## Quick Commands Reference

```bash
# Get SHA-256 certificate
cd purl_courier_app/android && ./gradlew signingReport

# Clean build
flutter clean

# Install dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk --release

# Check for issues
flutter analyze
```

## Important Files
- `purl_courier_app/android/app/google-services.json` - Firebase config (needs update)
- `purl_courier_app/lib/services/auth_service.dart` - Authentication logic
- `purl_courier_app/lib/services/onboarding_service.dart` - Onboarding flow
- `purl_courier_app/lib/screens/verification_screen.dart` - Document verification
- `purl_courier_app/lib/screens/camera_capture_screen.dart` - Camera with face scan

## Contact & Support
If you encounter issues:
1. Check Firebase Console for proper configuration
2. Verify SHA-256 is added correctly
3. Ensure google-services.json is updated
4. Rebuild the app completely (not just hot reload)
5. Check terminal logs for specific error messages
