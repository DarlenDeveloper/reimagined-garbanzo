# Quick Fix Steps - Buyer App Delivery Issues

## Network Issue Detected
Your network has 50% packet loss to Firebase APIs. Follow these manual steps:

## Step 1: Create Firestore Index (2 minutes)

**Click this link to create the index automatically:**

https://console.firebase.google.com/project/purlstores-za/firestore/indexes?create_composite=ClRwcm9qZWN0cy9wdXJsc3RvcmVzLXphL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9vcmRlcnMvaW5kZXhlcy9fEAEaCwoPb3JkZXJOdW1iZXIQARoMCgZfX25hbWVfXxAB

**Or create manually:**
1. Go to: https://console.firebase.google.com/project/purlstores-za/firestore/indexes
2. Click "Create Index"
3. Set:
   - Collection group ID: `orders`
   - Query scope: `Collection group`
   - Fields: `orderNumber` (Ascending)
4. Click "Create"
5. Wait 5-10 minutes for it to build

## Step 2: Deploy Cloud Function (When Network Improves)

Try again later when network is stable:
```bash
firebase deploy --only functions:onDeliveryStatusChanged
```

Or use Google Cloud Shell (always works):
1. Go to: https://console.cloud.google.com/home/dashboard?project=purlstores-za
2. Click Cloud Shell icon (top right)
3. Run:
   ```bash
   cd ~/reimagined-garbanzo
   firebase deploy --only functions:onDeliveryStatusChanged
   ```

## Step 3: Rebuild Buyer App (Do This Now)

```bash
cd purl-stores-app\(buyer\)
flutter clean
flutter pub get  
flutter run
```

## What Gets Fixed

✅ **Immediately (after Step 1 + 3):**
- Order details screen will load without errors
- Prices will display correctly (not as template literals)

⏳ **After Step 2 (Cloud Function deployed):**
- Order status will auto-update when delivery status changes
- Delivery flow: confirmed → shipped → delivered will sync properly

## Test It

1. Open buyer app
2. Go to Deliveries
3. Tap an order
4. Should load successfully and show real prices

## Temporary Workaround

Until Cloud Function is deployed, manually update order status from seller app when delivery status changes.

## Files Changed

- ✅ `firestore.indexes.json` - Index definition ready
- ✅ `functions/src/index.ts` - Cloud Function code ready
- ✅ Buyer app code - Already correct, just needs rebuild

## Need Help?

Check the detailed guides:
- `MANUAL_DEPLOYMENT_GUIDE.md` - Complete manual steps
- `BUYER_APP_DELIVERY_FIXES.md` - Technical details
