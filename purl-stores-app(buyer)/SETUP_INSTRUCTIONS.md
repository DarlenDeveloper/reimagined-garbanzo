# Setup Instructions for POP Buyer App

## iOS Notifications Setup

### 1. Enable Push Notifications Capability
1. Open the project in Xcode: `open ios/Runner.xcworkspace`
2. Select the Runner target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" and add "Push Notifications"
5. Click "+ Capability" and add "Background Modes"
6. Check "Remote notifications" under Background Modes

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

### 3. Add Notification Sound (Optional)
If you want custom notification sounds:
1. Add `notification.mp3` to `ios/Runner/` directory
2. Open Xcode and add the file to the Runner target
3. Make sure "Copy items if needed" is checked

### 4. Test Notifications
After completing the above steps:
1. Run the app on a physical iOS device (notifications don't work on simulator)
2. Grant notification permissions when prompted
3. Send a test notification from Firebase Console

## Splash Screen Setup

### 1. Install Dependencies
```bash
cd purl-stores-app\(buyer\)
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
- White background
- POP logo (centered)
- Smooth fade-in animation

## Common Issues

### iOS Notifications Not Working
1. **Check APNs key**: Make sure it's uploaded to Firebase Console
2. **Check Bundle ID**: Must match in Xcode, Firebase, and Apple Developer Portal
3. **Physical device**: Notifications don't work on iOS simulator
4. **Permissions**: User must grant notification permissions
5. **Background modes**: Must be enabled in Xcode capabilities

### Splash Screen Not Showing
1. Run `flutter clean`
2. Run `dart run flutter_native_splash:create`
3. Rebuild the app

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
