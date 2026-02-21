# Delivery System Testing Guide

## Prerequisites

### 1. Install Dependencies

**Buyer App:**
```bash
cd purl-stores-app\(buyer\)
flutter pub get
```

**Seller App:**
```bash
cd purl-admin-app\(seller\)
flutter pub get
```

---

## Phase 1 Testing: Buyer App (Location & Free Delivery)

### Test 1: Free Delivery Badge

**Steps:**
1. Open buyer app
2. Add items to cart
3. Go to Cart screen
4. **Verify:** Delivery shows "ON US FREE" with green badge
5. Go to Checkout
6. **Verify:** Same display in order summary

**Expected Result:**
- ✅ No $9.99 fee
- ✅ Green "ON US" badge visible
- ✅ "FREE" text in green

---

### Test 2: Location Capture

**Steps:**
1. Open buyer app
2. Add items to cart
3. Go to Checkout
4. **Verify:** "Location Required" section shows
5. Click "Allow Location Access"
6. Grant location permission when prompted
7. **Verify:** 
   - Loading spinner appears
   - "Getting your location..." message
   - Success: Green checkmark + coordinates displayed
   - Example: `Lat: 0.347600, Lng: 32.582500`

**Expected Result:**
- ✅ Location permission requested
- ✅ GPS coordinates captured
- ✅ Coordinates displayed in UI
- ✅ Green success state

**Troubleshooting:**
- If permission denied: Red error message with "Try Again" button
- If location services off: Orange snackbar with "Settings" button
- If timeout: Error message after 10 seconds

---

### Test 3: Location Validation

**Steps:**
1. Open buyer app
2. Add items to cart
3. Go to Checkout
4. **DO NOT** allow location
5. Add delivery address
6. Click "Skip Payment (Test Mode)"
7. **Verify:** Orange warning snackbar appears
8. Message: "Please allow location access to continue"
9. Click "Allow" in snackbar
10. Grant permission
11. Try checkout again
12. **Verify:** Order places successfully

**Expected Result:**
- ✅ Cannot checkout without location
- ✅ Clear error message
- ✅ Quick action to allow location
- ✅ Order succeeds after location granted

---

### Test 4: Order with Location

**Steps:**
1. Complete checkout with location
2. Open Firebase Console
3. Go to Firestore
4. Navigate to: `/stores/{storeId}/orders/{orderId}`
5. **Verify:** Order document contains:
   ```
   deliveryLocation: GeoPoint(lat, lng)
   deliveryAddress: {
     label: "Home",
     street: "...",
     city: "..."
   }
   ```

**Expected Result:**
- ✅ `deliveryLocation` field exists
- ✅ Contains GeoPoint with real coordinates
- ✅ Matches captured location

---

## Phase 2 Testing: Seller App (Delivery Service)

### Test 5: Arrange Delivery Button

**Steps:**
1. Open seller app
2. Go to Orders screen
3. Tap on a **pending** order
4. **Verify:** Order details modal opens
5. **Verify:** "Arrange Delivery" button visible
   - Outlined button with truck icon
   - Above "Mark as Shipped" button

**Expected Result:**
- ✅ Button only shows for pending orders
- ✅ Professional styling
- ✅ Truck icon visible

---

### Test 6: Delivery Options

**Steps:**
1. Open pending order
2. Click "Arrange Delivery"
3. **Verify:** Modal opens with 2 options:
   - "Assign My Delivery Person" (User icon)
   - "Request Purl Courier" (Truck icon)
4. Click "Assign My Delivery Person"
5. **Verify:** Placeholder dialog shows
6. Close dialog
7. Click "Arrange Delivery" again
8. Select "Request Purl Courier"

**Expected Result:**
- ✅ Clean modal with 2 clear options
- ✅ Icons and descriptions visible
- ✅ Self-delivery shows placeholder
- ✅ Courier option proceeds to search

---

### Test 7: Courier Search (3-Minute Countdown)

**Steps:**
1. Request Purl Courier
2. **Verify:** Loading indicator appears briefly
3. **Verify:** Search dialog opens with:
   - Title: "Searching for Courier"
   - Circular progress indicator
   - Countdown timer: 3:00
   - Message: "Notifying nearby couriers..."
   - Distance and fee (e.g., "5.2 km • UGX 5,200")
   - Cancel button
4. Watch timer count down: 3:00 → 2:59 → 2:58...
5. **Verify:** Timer updates every second
6. Wait full 3 minutes
7. **Verify:** Dialog auto-closes
8. **Verify:** "No Courier Available" dialog shows

**Expected Result:**
- ✅ Countdown starts at 3:00
- ✅ Updates every second
- ✅ Shows distance and fee
- ✅ Auto-closes at 0:00
- ✅ Timeout dialog appears

---

### Test 8: Cancel Delivery Request

**Steps:**
1. Request Purl Courier
2. Wait 30 seconds
3. Click "Cancel" button
4. **Verify:** Dialog closes immediately
5. Open Firebase Console
6. Check `/deliveries` collection
7. **Verify:** Delivery document has:
   ```
   status: "cancelled"
   cancelledAt: timestamp
   cancellationReason: "Cancelled by store"
   ```

**Expected Result:**
- ✅ Cancel works anytime during search
- ✅ Dialog closes
- ✅ Firestore updated correctly

---

### Test 9: Firestore Delivery Document

**Steps:**
1. Request Purl Courier
2. Open Firebase Console
3. Go to Firestore → `/deliveries`
4. Find the new delivery document
5. **Verify structure:**
   ```
   orderId: "..."
   orderNumber: "ORD-20260216-..."
   storeId: "..."
   storeName: "..."
   storeLocation: GeoPoint(0.3476, 32.5825)
   buyerLocation: GeoPoint(captured from order)
   status: "searching"
   searchExpiresAt: timestamp (3 min from now)
   deliveryType: "purl_courier"
   deliveryFee: number (calculated)
   distance: number (calculated in km)
   items: array
   totalAmount: number
   createdAt: timestamp
   ```

**Expected Result:**
- ✅ Document created in `/deliveries`
- ✅ All required fields present
- ✅ GeoPoints valid
- ✅ Distance calculated correctly
- ✅ Fee calculated (distance * 1000 UGX)

---

### Test 10: Distance Calculation

**Steps:**
1. Note buyer's location from order
2. Note store's location (default: Kampala 0.3476, 32.5825)
3. Request Purl Courier
4. Check delivery document in Firestore
5. **Verify:** `distance` field is reasonable
6. **Verify:** `deliveryFee` = distance * 1000 (min 2000)

**Example:**
- Distance: 5.2 km
- Fee: 5,200 UGX

**Expected Result:**
- ✅ Distance calculated using Haversine formula
- ✅ Fee proportional to distance
- ✅ Minimum fee: 2,000 UGX
- ✅ Maximum fee: 50,000 UGX

---

## Common Issues & Solutions

### Issue 1: Location Permission Denied
**Solution:**
- Go to device Settings → Apps → Purl Stores
- Enable Location permission
- Restart app

### Issue 2: "Order doesn't have delivery location"
**Cause:** Order was placed before Phase 1 implementation
**Solution:** Place a new order with location capture

### Issue 3: Countdown doesn't update
**Cause:** Stream not working
**Solution:** Check Firebase connection, restart app

### Issue 4: No delivery document created
**Cause:** Missing deliveryLocation in order
**Solution:** Ensure buyer app captured location before checkout

---

## Manual Testing Checklist

### Buyer App:
- [ ] Cart shows "ON US FREE" badge
- [ ] Checkout shows "ON US FREE" badge
- [ ] Location permission requested
- [ ] GPS coordinates captured
- [ ] Coordinates displayed in UI
- [ ] Cannot checkout without location
- [ ] Order saves deliveryLocation to Firestore

### Seller App:
- [ ] "Arrange Delivery" button visible on pending orders
- [ ] Delivery options modal opens
- [ ] Self-delivery shows placeholder
- [ ] Courier search starts
- [ ] Countdown timer works (3:00 → 0:00)
- [ ] Distance and fee displayed
- [ ] Cancel button works
- [ ] Timeout dialog shows after 3 minutes
- [ ] Delivery document created in Firestore

### Firestore:
- [ ] Orders have `deliveryLocation` GeoPoint
- [ ] Deliveries collection exists
- [ ] Delivery documents have correct structure
- [ ] Status updates correctly
- [ ] Timestamps are accurate

---

## Next: Add Maps (Optional Enhancement)

### Where to Add Maps:

**1. Buyer App - Checkout Screen:**
- Show map with buyer's location marker
- Visual confirmation of delivery point

**2. Seller App - Delivery Search Dialog:**
- Show map with store and buyer locations
- Visual distance representation
- Route preview

**3. Courier App - Active Delivery:**
- Real-time map with courier location
- Route to pickup/dropoff
- Turn-by-turn navigation

### Map Implementation:
- Use `google_maps_flutter` package (already in courier app)
- Add to buyer and seller apps
- Display markers for store/buyer locations
- Show route polyline

---

## Performance Testing

### Test Scenarios:
1. **Multiple simultaneous searches:** Create 5 delivery requests
2. **Network interruption:** Turn off WiFi during search
3. **App backgrounding:** Background app during countdown
4. **Rapid cancellation:** Cancel immediately after starting

**Expected Behavior:**
- Graceful handling of network issues
- Timer continues in background
- No memory leaks
- Clean state management

---

## Ready to Test!

Follow the tests in order:
1. ✅ Phase 1: Buyer app (Tests 1-4)
2. ✅ Phase 2: Seller app (Tests 5-10)
3. ✅ Verify Firestore data
4. ✅ Test edge cases

After testing, we can:
- Add maps for better visualization
- Proceed to Phase 3 (Courier app)
- Fix any issues found

Good luck! 🚀
