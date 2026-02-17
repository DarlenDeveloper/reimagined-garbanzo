# Manual Deployment Guide - Buyer App Fixes

## Network Issue Detected

The automatic deployment is failing due to network timeouts when connecting to Firebase APIs. This could be due to:
- Firewall blocking Google APIs
- Network connectivity issues
- VPN or proxy interference

## Manual Deployment Steps

### Option 1: Fix Network and Retry

1. **Check your internet connection**
2. **Disable VPN if active**
3. **Try from a different network**
4. **Retry deployment**:
   ```bash
   ./deploy-buyer-fixes.sh
   ```

### Option 2: Manual Deployment via Firebase Console

#### Step 1: Create Firestore Index Manually

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `purlstores-za`
3. Navigate to **Firestore Database** → **Indexes** tab
4. Click **Create Index**
5. Configure the index:
   - **Collection ID**: Leave as "Collection group"
   - **Collection group ID**: `orders`
   - **Query scope**: `Collection group`
   - **Fields to index**:
     - Field: `orderNumber`, Order: `Ascending`
   - Click **Create**

6. Wait 5-10 minutes for the index to build
7. Status will change from "Building" to "Enabled"

#### Step 2: Deploy Cloud Functions Manually

**Option A: Using Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `purlstores-za`
3. Navigate to **Functions**
4. You'll need to upload the function code manually or use Cloud Shell

**Option B: Using Google Cloud Shell**

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project: `purlstores-za`
3. Click the **Activate Cloud Shell** button (top right)
4. In Cloud Shell, run:
   ```bash
   # Clone or upload your code
   git clone <your-repo-url>
   cd reimagined-garbanzo
   
   # Deploy functions
   firebase deploy --only functions:onDeliveryStatusChanged
   ```

**Option C: Try from Different Machine/Network**

If you have access to another machine or network:
```bash
firebase deploy --only functions:onDeliveryStatusChanged
```

#### Step 3: Rebuild Buyer App

This can be done locally regardless of network issues:

```bash
cd purl-stores-app\(buyer\)
flutter clean
flutter pub get
flutter run
```

## What the Cloud Function Does

The `onDeliveryStatusChanged` function (in `functions/src/index.ts`) automatically syncs delivery status to order status:

```typescript
Delivery Status → Order Status
- searching/assigned → confirmed
- picked_up/in_transit → shipped
- delivered → delivered
- cancelled/no_courier_available → pending
```

It updates both:
- `/stores/{storeId}/orders/{orderId}`
- `/users/{userId}/orders/{orderId}`

## Testing Without Cloud Function (Temporary)

If you can't deploy the Cloud Function immediately, you can test the buyer app with the index fix:

1. **Create the Firestore index manually** (Step 1 above)
2. **Rebuild the buyer app** (Step 3 above)
3. The app will work, but order status won't auto-update when delivery status changes
4. You'll need to manually update order status from the seller app

## Verifying the Fixes

### 1. Check Firestore Index
- Go to Firebase Console → Firestore → Indexes
- Look for index on `orders` collection group with `orderNumber` field
- Status should be "Enabled"

### 2. Check Cloud Function
- Go to Firebase Console → Functions
- Look for `onDeliveryStatusChanged` function
- Should show as "Active"

### 3. Test Buyer App
- Open buyer app
- Navigate to Deliveries
- Prices should show as numbers (e.g., $154.97) not template literals
- Tap an order - should load without errors
- Create a test order and track delivery status updates

## Troubleshooting

### If prices still show as template literals:
```bash
cd purl-stores-app\(buyer\)
flutter clean
rm -rf build/
flutter pub get
flutter run
```

### If order details won't load:
- Check if Firestore index is "Enabled" (not "Building")
- Wait a few more minutes for index to complete
- Check Firebase Console → Firestore → Indexes

### If order status doesn't update:
- Verify Cloud Function is deployed and active
- Check Cloud Function logs in Firebase Console
- Manually update order status from seller app as workaround

## Alternative: Deploy from Cloud Shell

If local deployment keeps failing, use Firebase Cloud Shell:

1. Go to https://console.firebase.google.com
2. Select your project
3. Click the terminal icon (Cloud Shell)
4. Run:
   ```bash
   git clone <your-repo>
   cd reimagined-garbanzo
   firebase deploy --only firestore:indexes,functions:onDeliveryStatusChanged
   ```

## Files to Deploy

If manually uploading:
- `firestore.indexes.json` - Contains the new index definition
- `functions/src/index.ts` - Contains the updated Cloud Function
- `functions/lib/index.js` - Compiled JavaScript (run `npm run build` in functions folder)

## Contact Support

If issues persist:
- Check Firebase Status: https://status.firebase.google.com
- Firebase Support: https://firebase.google.com/support
- Check your Firebase project billing status
