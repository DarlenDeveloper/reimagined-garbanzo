# Delivery System Testing Guide

## ✅ Deployment Status

**Cloud Function Deployed:** `notifyNearbyCouriers`
- Region: africa-south1
- Trigger: Firestore document created in `deliveries` collection
- Status: Active ✅

## Prerequisites

Before testing, ensure:
1. All three apps are built and installed on devices
2. Google Maps API key is active
3. Location permissions granted on all apps
4. Internet connection available

## Test Setup

### 1. Create Test Courier Account

In Firebase Console → Firestore:

```javascript
// Collection: couriers
// Document ID: [courier_user_uid]
{
  fullName: "Test Courier",
  phone: "+256700000000",
  email: "courier@test.com",
  verified: true,
  isOnline: false,
  currentLocation: new GeoPoint(0.3476, 32.5825), // Kampala coordinates
  fcmTokens: [], // Will be populated by app
  totalDeliveries: 0,
  totalEarnings: 0,
  rating: 5,
  createdAt: [current timestamp]
}
```

### 2. Create Test Order

In Seller App:
- Create a test product
- Place an order as a buyer
- Order should appear in seller's "Orders" tab

## Testing Scenarios

### Scenario 1: Self-Delivery Flow

**Steps:**
1. Open Seller App
2. Go to "Deliveries" tab
3. Find pending order in "Needs Delivery" section
4. Click "Self Deliver" button
5. Fill in delivery person details:
   - Name: "John Doe"
   - Phone: "+256700000001"
   - Vehicle Type: "Motorcycle"
   - Plate Number: "UAH 123A"
6. Click "Assign Delivery"

**Expected Results:**
- ✅ Location permission requested (if first time)
- ✅ Loading dialog shows "Getting location..."
- ✅ Success message: "Self-delivery assigned to John Doe"
- ✅ Order moves to "Active" tab
- ✅ Shows delivery person details
- ✅ Shows vehicle info (Motorcycle UAH 123A)

**Verify in Firestore:**
```javascript
// Collection: deliveries
{
  deliveryType: "self",
  status: "shipped",
  assignedCourierName: "John Doe",
  assignedCourierPhone: "+256700000001",
  vehicleName: "Motorcycle",
  vehiclePlateNumber: "UAH 123A",
  storeLocation: GeoPoint // Current GPS location
}
```

---

### Scenario 2: Courier Request Flow (No Courier Available)

**Steps:**
1. Ensure NO couriers are online in Firestore
2. Open Seller App → Deliveries tab
3. Find pending order
4. Click "Request Rider" button
5. Wait for location to be captured
6. Map screen opens
7. Wait for 3-minute countdown

**Expected Results:**
- ✅ Location permission requested
- ✅ Loading dialog shows "Getting location..."
- ✅ Map screen opens with:
  - Blue marker (store location)
  - Red marker (buyer location)
  - Timer showing 03:00
  - "0 couriers nearby"
- ✅ After 3 minutes:
  - Map closes
  - Message: "No courier available. Please try again later."
  - Delivery status: "no_courier_available"

**Verify in Firestore:**
```javascript
// Collection: deliveries
{
  deliveryType: "purl_courier",
  status: "no_courier_available",
  deliveryFee: [calculated],
  distance: [calculated],
  searchExpiresAt: [timestamp + 3 minutes],
  notificationsSent: 0
}
```

---

### Scenario 3: Courier Request Flow (With Online Courier)

**Setup:**
1. Open Courier App
2. Login with courier account
3. Toggle "Online" switch
4. Verify green indicator shows "You are Online"

**Steps:**
1. Open Seller App → Deliveries tab
2. Find pending order
3. Click "Request Rider" button
4. Map screen opens

**Expected Results - Seller Side:**
- ✅ Map shows blue marker (store) and red marker (buyer)
- ✅ If courier is within 10km, shows green marker for courier
- ✅ Shows "X couriers nearby"
- ✅ Timer counts down from 03:00

**Expected Results - Courier Side:**
- ✅ Push notification received (if FCM configured)
- ✅ Delivery appears in "Available Deliveries" section
- ✅ Shows:
  - Order number
  - Store name
  - Distance (e.g., "2.5 km away")
  - Delivery fee (e.g., "UGX 7,500")
  - "Accept" button

**Verify in Firestore:**
```javascript
// Collection: deliveries
{
  status: "searching",
  deliveryType: "purl_courier",
  notificationsSent: 1, // Number of couriers notified
  notifiedAt: [timestamp]
}
```

**Verify in Cloud Function Logs:**
```
🔍 Finding couriers near [Store Name] for delivery [deliveryId]
✅ Notified courier [courierId]
📤 Sent 1 notifications for delivery [deliveryId]
```

---

### Scenario 4: Courier Accepts Delivery

**Prerequisites:**
- Courier is online
- Delivery request is active (status: "searching")

**Steps:**
1. In Courier App, see delivery in "Available Deliveries"
2. Click "Accept" button
3. Confirmation dialog appears
4. Click "Accept" in dialog

**Expected Results - Courier Side:**
- ✅ Confirmation dialog shows:
  - Order number
  - Delivery fee
  - Description
- ✅ Loading dialog: "Accepting delivery..."
- ✅ Success message: "Delivery accepted! Go to Active Delivery tab."
- ✅ Delivery disappears from "Available Deliveries"
- ✅ Delivery appears in "Active Delivery" card

**Expected Results - Seller Side:**
- ✅ Map screen detects status change
- ✅ "Courier Found!" dialog appears
- ✅ Shows courier name
- ✅ "Done" button closes map
- ✅ Order moves to "Active" tab
- ✅ Shows courier details (name, phone, vehicle if available)

**Verify in Firestore:**
```javascript
// Collection: deliveries
{
  status: "assigned",
  assignedCourierId: "[courier_uid]",
  assignedCourierName: "Test Courier",
  assignedCourierPhone: "+256700000000",
  assignedAt: [timestamp]
}

// Collection: stores/{storeId}/orders/{orderId}
{
  status: "shipped"
}
```

---

### Scenario 5: Active Delivery Tracking

**Prerequisites:**
- Courier has accepted a delivery

**Steps:**
1. In Courier App, tap "Active Delivery" card
2. Active Delivery Screen opens

**Expected Results:**
- ✅ Map shows:
  - Orange marker (store/pickup location)
  - Red marker (buyer/dropoff location)
  - Map auto-fits to show both markers
- ✅ Top bar shows distance (e.g., "2.5 km")
- ✅ Bottom sheet shows:
  - "Package details" header
  - Tracking ID (order number)
  - Departure section:
    - Store name
    - Store address
    - Phone call button (orange)
  - Arrival section:
    - Buyer name
    - Buyer address
    - Phone call button (orange)
  - Package info:
    - Item count
    - Total amount
    - Delivery fee
  - "Mark as Picked Up" button (black)

**Test Phone Call:**
1. Click orange phone button next to store
2. Phone dialer opens with store number

---

### Scenario 6: Mark as Picked Up

**Prerequisites:**
- Courier is on Active Delivery Screen
- Status is "assigned"

**Steps:**
1. Click "Mark as Picked Up" button

**Expected Results:**
- ✅ Loading indicator briefly
- ✅ Success message: "Status updated to Picked Up"
- ✅ Button changes to "Mark as Delivered" (green)
- ✅ Location updates start (every 15 seconds)

**Verify in Firestore:**
```javascript
// Collection: deliveries
{
  status: "picked_up",
  pickedUpAt: [timestamp],
  courierLocation: GeoPoint, // Updated every 15s
  courierLocationUpdatedAt: [timestamp]
}
```

---

### Scenario 7: Mark as Delivered

**Prerequisites:**
- Courier has picked up package
- Status is "picked_up"

**Steps:**
1. Click "Mark as Delivered" button (green)

**Expected Results:**
- ✅ Success message: "Status updated to Delivered"
- ✅ Button changes to "Delivery Completed" indicator (green with checkmark)
- ✅ Screen closes after 2 seconds
- ✅ Delivery disappears from "Active Delivery"

**Expected Results - Seller Side:**
- ✅ Order moves to "Completed" tab
- ✅ Shows "Delivered [time ago]"

**Verify in Firestore:**
```javascript
// Collection: deliveries
{
  status: "delivered",
  deliveredAt: [timestamp]
}

// Collection: stores/{storeId}/orders/{orderId}
{
  status: "delivered"
}

// Collection: couriers/{courierId}
{
  totalDeliveries: [incremented by 1],
  totalEarnings: [increased by deliveryFee]
}
```

---

### Scenario 8: Location Tracking

**Prerequisites:**
- Courier is online

**Steps:**
1. Toggle courier online
2. Wait 30 seconds
3. Check Firestore

**Expected Results:**
- ✅ `currentLocation` field updates every 30 seconds
- ✅ `lastLocationUpdate` timestamp updates
- ✅ Location is accurate (within 10-50 meters)

**During Active Delivery:**
- ✅ `courierLocation` in delivery document updates every 15 seconds
- ✅ More frequent updates for real-time tracking

---

## Common Issues & Solutions

### Issue: Location not updating
**Solution:**
- Check location permissions are granted
- Verify courier is online
- Check device location services are enabled
- Look for errors in app logs

### Issue: No couriers nearby
**Solution:**
- Verify courier `isOnline: true` in Firestore
- Check courier `verified: true`
- Verify courier has `currentLocation` field
- Check distance calculation (must be within 10km)

### Issue: Push notifications not received
**Solution:**
- Check FCM tokens are stored in courier document
- Verify Cloud Function executed (check logs)
- Check notification permissions granted
- Verify internet connection

### Issue: Map not loading
**Solution:**
- Verify Google Maps API key is active
- Check API key has correct restrictions
- Verify Maps SDK for Android/iOS is enabled
- Check internet connection

### Issue: "Courier Found" dialog doesn't appear
**Solution:**
- Check Firestore listener is active
- Verify delivery status changed to "assigned"
- Check for JavaScript errors in console
- Refresh the map screen

---

## Performance Benchmarks

### Expected Response Times:
- Location capture: 2-5 seconds
- Delivery creation: < 1 second
- Cloud Function trigger: < 2 seconds
- Courier notification: < 3 seconds
- Status update: < 1 second
- Map loading: 2-4 seconds

### Battery Usage:
- Location tracking (online): ~5-10% per hour
- Active delivery: ~10-15% per hour
- Offline: Minimal impact

---

## Test Checklist

### Pre-Testing
- [ ] Cloud Function deployed
- [ ] Google Maps API key active
- [ ] Test courier account created
- [ ] All apps installed on devices
- [ ] Location permissions granted

### Self-Delivery
- [ ] Can enter delivery person details
- [ ] Location captured successfully
- [ ] Order moves to Active tab
- [ ] Details displayed correctly
- [ ] Can mark as delivered

### Courier Request
- [ ] Location captured
- [ ] Map opens with markers
- [ ] Timer counts down
- [ ] Timeout works (no courier)
- [ ] Shows nearby couriers count

### Courier Acceptance
- [ ] Delivery appears in available list
- [ ] Can accept delivery
- [ ] Confirmation dialog works
- [ ] Seller sees "Courier Found"
- [ ] Order moves to Active tab

### Active Delivery
- [ ] Map shows both locations
- [ ] Phone call buttons work
- [ ] Can mark as picked up
- [ ] Can mark as delivered
- [ ] Location updates work
- [ ] Earnings updated

### Location Tracking
- [ ] Online toggle works
- [ ] Location updates every 30s
- [ ] Stops when offline
- [ ] Updates every 15s during delivery

---

## Next Steps After Testing

1. **If all tests pass:**
   - Deploy to production
   - Monitor Cloud Function logs
   - Track delivery success rate
   - Gather user feedback

2. **If issues found:**
   - Document issues
   - Check error logs
   - Fix and redeploy
   - Retest affected scenarios

3. **Enhancements to implement:**
   - Push notification UI
   - Route display on map
   - Real-time ETA calculation
   - Courier profile screen
   - Rating system

---

**Testing Date:** _____________
**Tester:** _____________
**Results:** _____________
