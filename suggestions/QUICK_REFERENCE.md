# 🚀 Quick Reference - Delivery System

## Deployment Status
✅ **DEPLOYED** - Cloud Function active in africa-south1

---

## Quick Commands

### View Function Logs
```bash
firebase functions:log --only notifyNearbyCouriers
```

### Check Function Status
```bash
firebase functions:list
```

### Redeploy Function
```bash
cd functions
npm run build
firebase deploy --only functions:notifyNearbyCouriers
```

### Build Apps
```bash
# Seller App
cd purl-admin-app\(seller\)
flutter pub get
flutter build apk

# Courier App
cd purl_courier_app
flutter pub get
flutter build apk

# Buyer App
cd purl-stores-app\(buyer\)
flutter pub get
flutter build apk
```

---

## Quick Test Setup

### 1. Create Test Courier (Firestore Console)
```javascript
Collection: couriers
Document ID: [your_courier_uid]

{
  fullName: "Test Courier",
  phone: "+256700000000",
  email: "courier@test.com",
  verified: true,
  isOnline: false,
  currentLocation: new GeoPoint(0.3476, 32.5825),
  fcmTokens: [],
  totalDeliveries: 0,
  totalEarnings: 0,
  rating: 5,
  createdAt: [timestamp]
}
```

### 2. Test Flow
1. **Courier App:** Toggle Online ✅
2. **Seller App:** Request Rider 🚗
3. **Courier App:** Accept Delivery ✅
4. **Courier App:** Mark as Picked Up 📦
5. **Courier App:** Mark as Delivered ✅

---

## Key Features

### Seller App
- ✅ Self-delivery with vehicle details
- ✅ Courier request with map
- ✅ 3-minute search timer
- ✅ Real-time courier acceptance
- ✅ Active delivery tracking

### Courier App
- ✅ Online/offline toggle
- ✅ Location tracking (30s)
- ✅ Available deliveries list
- ✅ Active delivery screen
- ✅ Status updates
- ✅ Phone call integration

### Cloud Function
- ✅ Auto-notify nearby couriers
- ✅ 10km radius filtering
- ✅ Verified & online check
- ✅ Push notifications

---

## Important Firestore Fields

### Courier Must Have:
- `verified: true`
- `isOnline: true`
- `currentLocation: GeoPoint`

### Delivery Statuses:
- `searching` → Looking for courier
- `assigned` → Courier accepted
- `picked_up` → Package picked up
- `delivered` → Delivery complete

---

## Troubleshooting

### No Couriers Found?
- Check `isOnline: true`
- Check `verified: true`
- Check `currentLocation` exists
- Verify within 10km

### Function Not Triggering?
```bash
firebase functions:log --only notifyNearbyCouriers
```

### Location Not Updating?
- Check permissions granted
- Verify courier is online
- Check device location enabled

---

## Documentation Files

- 📋 `DEPLOYMENT_COMPLETE.md` - Full deployment details
- 🧪 `TESTING_GUIDE.md` - Complete testing scenarios
- 📦 `IMPLEMENTATION_SUMMARY.md` - Full feature list
- 🚚 `COURIER_APP_UPDATES.md` - Courier app changes
- 🔗 `DELIVERY_INTEGRATION_COMPLETE.md` - Integration details

---

## API Keys

**Google Maps:** AIzaSyAkTfLh7iFXsGJ4baSpRtzglNvlHhNmRHY

**Enabled APIs:**
- Maps SDK for Android ✅
- Maps SDK for iOS ✅
- Directions API ✅
- Distance Matrix API ✅

---

## Delivery Fee Calculation

```
Base Fee: UGX 5,000
Per KM: UGX 1,000
Formula: 5000 + (distance * 1000)

Example:
2.5 km = UGX 7,500
5.0 km = UGX 10,000
10 km = UGX 15,000
```

---

## Next Steps

1. ✅ Cloud Function deployed
2. ⏳ Build and install apps
3. ⏳ Create test courier
4. ⏳ Run test scenarios
5. ⏳ Implement push notification UI
6. ⏳ Add route display

---

**Status:** READY FOR TESTING 🎉
