# Courier Integration Setup Guide

## ✅ What's Been Done

1. **Delivery Service Created** - `purl_courier_app/lib/services/delivery_service.dart`
2. **Cloud Function Added** - `notifyNearbyCouriers` in `functions/src/index.ts`
3. **Google Maps Added** - To seller app pubspec.yaml

## 🔧 What You Need to Do

### 1. Get Google Maps API Key

```bash
# Go to Google Cloud Console
https://console.cloud.google.com/google/maps-apis

# Enable these APIs:
- Maps SDK for Android
- Maps SDK for iOS

# Create/Get API key
# Copy the key (looks like: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)
```

### 2. Add API Key to Android (Seller App)

Edit: `purl-admin-app(seller)/android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### 3. Deploy Cloud Function

```bash
cd functions
npm install
firebase deploy --only functions:notifyNearbyCouriers
```

### 4. Update Courier App to Track Location

Couriers need to update their `currentLocation` and `isOnline` status in Firestore:

Collection: `couriers/{uid}`
Fields needed:
- `currentLocation`: GeoPoint (latitude, longitude)
- `isOnline`: boolean
- `fcmTokens`: array of FCM tokens
- `verified`: boolean

### 5. Install Packages

```bash
# Seller app
cd purl-admin-app\(seller\)
flutter pub get

# Courier app (already has google_maps)
cd purl_courier_app
flutter pub get
```

## 📱 Features to Implement Next

### Seller App:
1. Map screen showing nearby couriers
2. Search animation while finding couriers
3. Courier count display

### Courier App:
1. Popup notification from top
2. 1-minute acceptance timer
3. Accept/Reject buttons
4. Real-time location updates

## 🔥 Firebase Collections Structure

### `/deliveries/{deliveryId}`
```javascript
{
  orderId: string,
  orderNumber: string,
  storeLocation: GeoPoint,
  buyerLocation: GeoPoint,
  deliveryType: "purl_courier",
  status: "searching" | "assigned" | "picked_up" | "delivered",
  deliveryFee: number,
  distance: number,
  searchExpiresAt: timestamp (3 minutes),
  notificationsSent: number,
  notifiedAt: timestamp
}
```

### `/couriers/{uid}`
```javascript
{
  fullName: string,
  phone: string,
  verified: boolean,
  isOnline: boolean,
  currentLocation: GeoPoint,
  fcmTokens: string[],
  totalDeliveries: number,
  totalEarnings: number,
  rating: number
}
```

## 🚀 Next Steps

1. Get Google Maps API key
2. Add to Android manifest
3. Deploy Cloud Function
4. Test: Create delivery request from seller app
5. Verify: Nearby couriers receive push notification
6. Build: Map UI for seller app
7. Build: Popup notification UI for courier app

## 📝 Notes

- Cloud Function triggers automatically when delivery is created
- Only notifies couriers within 10km radius
- Only notifies verified and online couriers
- Couriers have 1 minute to accept (implement timer in UI)
- First courier to accept gets the delivery
