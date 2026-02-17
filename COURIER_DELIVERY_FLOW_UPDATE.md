# Courier Delivery Flow - Updated Implementation

## Changes Made (Courier App Only)

### 1. Auto-Navigation After Acceptance
**File:** `purl_courier_app/lib/screens/home_screen.dart`

**What Changed:**
- After courier accepts a delivery, they are now automatically navigated to the `ActiveDeliveryScreen`
- Snackbar message updated to: "Delivery accepted! Navigate to pickup location."

**Flow:**
```
Accept Delivery → Loading Dialog → Success → Auto-Navigate to ActiveDeliveryScreen
```

### 2. Updated Delivery Flow with Directions
**File:** `purl_courier_app/lib/screens/active_delivery_screen.dart`

**New Flow:**

#### Stage 1: Assigned (Going to Pickup)
- Status: `assigned`
- Shows TWO buttons:
  1. **"Directions to Pickup"** (Outlined, Black) - Opens Google Maps with store location
  2. **"Start Journey"** (Filled, Black) - Updates status to `picked_up`

#### Stage 2: Picked Up (Going to Dropoff)
- Status: `picked_up`
- Shows TWO buttons:
  1. **"Directions to Dropoff"** (Outlined, Green) - Opens Google Maps with buyer location
  2. **"Complete Delivery"** (Filled, Green) - Updates status to `delivered`

#### Stage 3: Delivered
- Status: `delivered`
- Shows completion message with green checkmark
- Auto-closes after 2 seconds

### 3. Google Maps Integration
**New Methods Added:**
- `_openDirectionsToPickup()` - Opens Google Maps with store coordinates
- `_openDirectionsToDropoff()` - Opens Google Maps with buyer coordinates

**How It Works:**
- Uses `url_launcher` package with `LaunchMode.externalApplication`
- Opens Google Maps app (or browser if app not installed)
- URL format: `https://www.google.com/maps/dir/?api=1&destination=LAT,LNG`
- Shows error snackbar if Maps cannot be opened

## Complete User Flow

### Courier Perspective:

1. **See Available Delivery**
   - Courier is online
   - Sees delivery in "Available Deliveries" list
   - Shows: Order number, store name, distance, fee

2. **Accept Delivery**
   - Clicks "Accept" button
   - Confirmation dialog appears
   - Clicks "Accept" in dialog
   - Loading indicator shows

3. **Auto-Navigate to Active Delivery Screen**
   - Screen opens automatically
   - Map shows store (orange marker) and buyer (red marker)
   - Bottom sheet shows package details
   - Buyer contact info displayed (name + phone)

4. **Navigate to Pickup (Status: assigned)**
   - Clicks "Directions to Pickup" → Google Maps opens with store location
   - Courier drives to store
   - Arrives at store, collects package
   - Clicks "Start Journey" button

5. **Navigate to Dropoff (Status: picked_up)**
   - Status updates to `picked_up`
   - Clicks "Directions to Dropoff" → Google Maps opens with buyer location
   - Courier drives to buyer
   - Arrives at buyer location, hands over package
   - Clicks "Complete Delivery" button

6. **Delivery Complete (Status: delivered)**
   - Status updates to `delivered`
   - Green completion message shows
   - Courier earnings updated in Firestore
   - Screen auto-closes after 2 seconds
   - Returns to Home screen

## Buyer Contact Information

**Already Displayed:**
- Buyer's full name (from `buyerName` field)
- Buyer's phone number (from `buyerPhone` field)
- Phone call button to contact buyer directly

**Location in UI:**
- Bottom sheet → "Arrival" section
- Shows buyer name, address, and phone icon button

## Technical Details

### Status Transitions
```
searching → assigned → picked_up → delivered
```

### Firestore Updates
- `assigned`: Sets courier info, assignedAt timestamp
- `picked_up`: Sets pickedUpAt timestamp
- `delivered`: Sets deliveredAt timestamp, updates courier stats

### Location Tracking
- Continues updating courier location every 15 seconds during active delivery
- Updates `courierLocation` field in delivery document
- Seller can see courier movement on their map

## Files Modified

1. `purl_courier_app/lib/screens/home_screen.dart`
   - Added auto-navigation after acceptance
   - Updated success message

2. `purl_courier_app/lib/screens/active_delivery_screen.dart`
   - Changed button labels ("Start Journey", "Complete Delivery")
   - Added directions buttons for pickup and dropoff
   - Added Google Maps integration methods
   - Updated button styling (outlined + filled buttons)

## No Breaking Changes

- All existing functionality preserved
- No changes to Firestore structure
- No changes to seller or buyer apps
- No changes to Cloud Functions
- Uses existing `url_launcher` package (already installed)

## Testing Checklist

- [ ] Accept delivery from available list
- [ ] Verify auto-navigation to Active Delivery Screen
- [ ] Verify buyer name and phone displayed
- [ ] Click "Directions to Pickup" - Google Maps opens with store location
- [ ] Click "Start Journey" - Status updates to picked_up
- [ ] Click "Directions to Dropoff" - Google Maps opens with buyer location
- [ ] Click "Complete Delivery" - Status updates to delivered
- [ ] Verify screen auto-closes after completion
- [ ] Verify courier earnings updated in Firestore
- [ ] Test phone call buttons for store and buyer

## Notes

- Google Maps opens in external app (not in-app browser)
- If Google Maps app not installed, opens in default browser
- Directions use current location as starting point automatically
- No dummy data - all data comes from Firestore in real-time
- Buyer contact info was already in the data model, just displayed properly now
