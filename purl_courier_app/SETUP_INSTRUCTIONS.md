# Setup Instructions for POP Courier App

## iOS Notifications Setup

### 1. Enable Push Notifications Capability
1. Open the project in Xcode: `open ios/Runner.xcworkspace`
2. Select the Runner target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" and add "Push Notifications"
5. Click "+ Capability" and add "Background Modes"
6. Check "Remote notifications" and "Location updates" under Background Modes

### 2. APNs Authentication Key (Required for Firebase Cloud Messaging)
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles
3. Go to Keys section
4. Create a new key with "Apple Push Notifications service (APNs)" enabled
5. Download the .p8 key file
6. Upload this key to Firebase Console:
   - Go to Project Settings > Cloud Messaging
   - Under iOS app configuration, upload the APNs Authentication Key
   - Enter your Team ID and Key ID

### 3. Test Notifications
After completing the above steps:
1. Run the app on a physical iOS device (notifications don't work on simulator)
2. Grant notification permissions when prompted
3. Send a test notification from Firebase Console

## Splash Screen Setup

### 1. Install Dependencies
```bash
cd purl_courier_app
flutter pub get
```

### 2. Generate Native Splash Screens
```bash
dart run flutter_native_splash:create
```

This will automatically generate:
- Android splash screens (including Android 12+)
- iOS launch screen
- All required configurations

### 3. Verify Setup
The splash screen will show:
- Red background (#fb2a0a)
- POP Rider logo (centered)
- Smooth transitions

## Delete Account Feature

The delete account feature has been added to Profile > Account > Delete Account.

When users tap "Delete Account":
1. A dialog appears confirming their request has been submitted
2. They're informed they'll be notified via email
3. A link to the Privacy Policy is provided
4. They're logged out and redirected to the welcome screen

This feature is required for Apple App Store compliance.

## Terms & Privacy Acceptance

The apply/signup screen now requires users to accept the Privacy Policy and Terms of Service before creating an account.

The links open:
- Privacy Policy: https://purlstores-za.web.app/privacy.html
- Terms of Service: https://purlstores-za.web.app/terms.html

## Production Crash Investigation

### Potential Crash Causes:
1. **Missing Assets**: Verify all images exist in `assets/images/`
2. **Firebase Initialization**: Check if Firebase is properly initialized before any Firebase calls
3. **Location Permissions**: Ensure location permissions are properly requested
4. **Background Location**: iOS requires special handling for background location tracking

### Debug Steps:
1. Check crash logs in Firebase Crashlytics or Xcode
2. Verify all required permissions are in Info.plist
3. Test on physical device (not simulator)
4. Check for null safety issues in production builds
5. Verify all Firebase services are properly configured

### Common Issues:
- **Image Loading**: The splash screen loads `pop_logo.png` - verify this file exists
- **FCM Initialization**: FCM is initialized in main.dart - ensure it doesn't block app startup
- **Location Services**: Background location requires "Always" permission
- **Google Maps**: Verify API key is valid and has proper restrictions

## Common Issues

### iOS Notifications Not Working
1. **Check APNs key**: Make sure it's uploaded to Firebase Console
2. **Check Bundle ID**: Must match in Xcode, Firebase, and Apple Developer Portal
3. **Physical device**: Notifications don't work on iOS simulator
4. **Permissions**: User must grant notification permissions
5. **Background modes**: Must be enabled in Xcode capabilities

### Splash Screen Not Showing Correctly
1. Run `flutter clean`
2. Run `dart run flutter_native_splash:create`
3. Rebuild the app
4. Make sure the logo image exists at `assets/images/pop_rider_logo.png`

### Build Errors
If you get build errors after adding splash screen:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

## Testing Checklist

- [ ] iOS notifications work on physical device
- [ ] Notification permissions are requested
- [ ] Notifications show when app is in foreground
- [ ] Notifications show when app is in background
- [ ] Tapping notification opens the app
- [ ] Splash screen shows on app launch
- [ ] Splash screen has correct branding
- [ ] App transitions smoothly from splash to main screen
- [ ] Delete account feature works and logs user out
- [ ] Terms and Privacy links open correctly
- [ ] Cannot sign up without accepting terms
- [ ] App doesn't crash on production builds
- [ ] Location tracking works in background
