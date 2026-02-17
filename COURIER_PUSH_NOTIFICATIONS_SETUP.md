# Courier App Push Notifications Setup

## Date: February 18, 2026

## Issue
Notifications were being received and stored in Firestore but no sound was playing because:
1. Only in-app notifications were being created (stored in Firestore)
2. No push notifications were being sent through Firebase Cloud Messaging (FCM)
3. FCM was not initialized in the courier app

## Solution Implemented

### 1. Updated Cloud Functions (`functions/src/index.ts`)
Added push notification sending to `onDeliveryAccepted` function:

**When delivery is accepted:**
- Sends push notification with sound to courier
- Creates in-app notification in Firestore
- Uses channel: `purl_courier_delivery_updates`

**When delivery is completed:**
- Sends push notification with sound to courier
- Creates in-app notification in Firestore
- Shows earnings amount

### 2. Created FCM Service (`purl_courier_app/lib/services/fcm_service.dart`)
New service that handles:
- Requesting notification permissions on app start
- Getting and saving FCM tokens to Firestore
- Handling foreground notifications with sound
- Handling background notifications
- Handling notification taps
- Creating Android notification channels:
  - `purl_courier_delivery_requests` - For new delivery requests
  - `purl_courier_delivery_updates` - For delivery status updates
- Removing tokens on logout

### 3. Updated Main App (`purl_courier_app/lib/main.dart`)
- Initializes FCM service on app start
- Requests notification permissions automatically

### 4. Updated Auth Service (`purl_courier_app/lib/services/auth_service.dart`)
- Removes FCM token from Firestore on logout
- Cleans up notification subscriptions

## Notification Channels

### Delivery Requests Channel
- **ID**: `purl_courier_delivery_requests`
- **Name**: Delivery Requests
- **Description**: Notifications for new delivery requests
- **Importance**: High
- **Sound**: notification.mp3

### Delivery Updates Channel
- **ID**: `purl_courier_delivery_updates`
- **Name**: Delivery Updates
- **Description**: Notifications for delivery status updates
- **Importance**: High
- **Sound**: notification.mp3

## Notification Types

1. **delivery_request** - New delivery available nearby
2. **delivery_accepted** - Courier accepted a delivery
3. **delivery_completed** - Delivery was completed successfully

## How It Works

1. **App Start**: FCM service initializes and requests permissions
2. **Permission Granted**: FCM token is generated and saved to Firestore
3. **Cloud Function Triggers**: When delivery status changes
4. **Push Notification Sent**: FCM sends notification to courier's device
5. **Notification Received**: 
   - If app is in foreground: Shows local notification with sound
   - If app is in background: System shows notification with sound
   - If app is closed: System shows notification with sound
6. **User Taps**: Opens app (can add navigation to specific screen)

## Token Management

- Tokens are stored in Firestore at `/couriers/{courierId}/fcmTokens` as an array
- Supports multiple devices per courier
- Tokens are automatically refreshed when they expire
- Tokens are removed on logout

## Deployment

### Deploy Cloud Functions:
```bash
cd functions
npm run build
firebase deploy --only functions
```

### Rebuild Courier App:
```bash
cd purl_courier_app
flutter clean
flutter pub get
flutter run
```

## Testing

1. Login to courier app - permission dialog should appear
2. Accept notification permissions
3. Accept a delivery from another device/app
4. Should hear notification sound and see notification
5. Complete delivery
6. Should hear notification sound and see completion notification

## Android Permissions

The app already has these permissions in `AndroidManifest.xml`:
- `android.permission.POST_NOTIFICATIONS` (Android 13+)
- `android.permission.VIBRATE`
- `android.permission.RECEIVE_BOOT_COMPLETED`

## iOS Permissions

Notification permissions are requested at runtime through FCM service.

## Status: ✅ READY FOR TESTING

All components are in place:
- Cloud Functions send push notifications
- FCM service handles permissions and tokens
- Notification channels are configured
- Sound files are referenced

Deploy the functions and rebuild the app to test!
