# Flutterwave V3 Payment Integration Setup Guide

## Overview
Flutterwave Standard payment integration for Purl marketplace. After payment, Flutterwave redirects back to the app with transaction details in the URL.

## Architecture
- **Cloud Functions**: Handle payment initialization and verification (server-side for security)
- **Flutter App**: Opens Flutterwave checkout in webview, captures redirect with transaction ID
- **Firestore**: Stores payment records for tracking

## Prerequisites
1. Flutterwave account with V3 API access
2. Test API keys (Public Key, Secret Key)
3. Firebase project with Cloud Functions enabled
4. Node.js 20+ installed

## Step 1: Configure Environment Variables

### Set Cloud Functions Environment Variables

```bash
# Navigate to functions directory
cd functions

# Set Flutterwave secret key (REQUIRED)
firebase functions:config:set flutterwave.secret_key="YOUR_SECRET_KEY_HERE"

# Set encryption key (REQUIRED for card charges)
firebase functions:config:set flutterwave.encryption_key="YOUR_ENCRYPTION_KEY_HERE"

# View current config
firebase functions:config:get
```

**Important**: 
- Use TEST keys for testing: `FLWSECK_TEST-xxxxx`, `FLWPUBK_TEST-xxxxx`
- Use LIVE keys for production: `FLWSECK-xxxxx`, `FLWPUBK-xxxxx`
- Never commit API keys to version control

## Step 2: Install Dependencies

### Cloud Functions
```bash
cd functions
npm install
```

This installs:
- `axios`: HTTP client for Flutterwave API calls

### Flutter App
```bash
cd purl-stores-app(buyer)
flutter pub get
```

This installs:
- `cloud_functions`: Call Cloud Functions from Flutter
- `webview_flutter`: Display Flutterwave checkout

## Step 3: Deploy Cloud Functions

```bash
# Build TypeScript
cd functions
npm run build

# Deploy payment functions
firebase deploy --only functions:initializeFlutterwavePayment,functions:verifyFlutterwavePayment
```

**Deployed Functions**:
1. `initializeFlutterwavePayment` - Creates payment link
2. `verifyFlutterwavePayment` - Verifies payment after redirect

## Step 4: Test Payment Flow

### Test Mode
1. Use test API keys
2. Use test cards from [Flutterwave Test Cards](https://developer.flutterwave.com/docs/testing)

**Test Card (Successful Payment)**:
- Card Number: `5531886652142950`
- CVV: `564`
- Expiry: `09/32`
- PIN: `3310`
- OTP: `12345`

**Test Card (Failed Payment)**:
- Card Number: `5143010522339965`
- CVV: Any
- Expiry: Any future date

### Testing Steps
1. Add items to cart in buyer app
2. Go to checkout
3. Fill in delivery details
4. Click "Proceed Transactions"
5. Complete payment in Flutterwave webview
6. App automatically verifies payment after redirect
7. Order is created if payment successful

## Payment Flow

```
User clicks "Proceed Transactions"
         ↓
App calls initializeFlutterwavePayment Cloud Function
         ↓
Cloud Function creates payment with Flutterwave API
         ↓
Returns payment link to app
         ↓
App opens payment link in webview
         ↓
User completes payment on Flutterwave
         ↓
Flutterwave redirects with status & transaction_id in URL
         ↓
App captures redirect URL parameters
         ↓
App calls verifyFlutterwavePayment Cloud Function
         ↓
Cloud Function verifies with Flutterwave API
         ↓
If successful, app creates order
```

## Firestore Structure

### /payments/{txRef}
```javascript
{
  userId: "user123",
  txRef: "PURL_abc12345_1234567890",
  amount: 50000,
  currency: "UGX",
  status: "pending" | "approved" | "failed",
  paymentLink: "https://checkout.flutterwave.com/...",
  transactionId: "1234567",
  flwRef: "FLW-MOCK-...",
  metadata: {
    orderCount: 2,
    promoCode: "SAVE10"
  },
  createdAt: timestamp,
  verifiedAt: timestamp
}
```

## Security Best Practices

1. ✅ **Server-side verification**: Always verify payments on the server
2. ✅ **Amount validation**: Verify payment amount matches order total
3. ✅ **Environment variables**: Never hardcode API keys
4. ✅ **HTTPS only**: All API calls use HTTPS
5. ✅ **Transaction verification**: Always verify with Flutterwave API before creating order

## Troubleshooting

### Payment initialization fails
- Check Cloud Functions logs: `firebase functions:log`
- Verify environment variables: `firebase functions:config:get`
- Ensure secret key is correct

### Payment verification fails
- Check transaction ID is correct
- Verify payment was completed on Flutterwave
- Check Flutterwave dashboard for transaction status

### Orders not created after payment
- Check app logs for errors
- Verify payment verification returned success
- Check Firestore rules allow order creation

## Going Live

### Checklist
- [ ] Replace test API keys with live keys
- [ ] Test with real card (small amount)
- [ ] Monitor Cloud Functions logs
- [ ] Set up error alerting
- [ ] Document customer support process for payment issues

### Switch to Live Mode
```bash
# Update environment variables with live keys
firebase functions:config:set flutterwave.secret_key="FLWSECK-your-live-secret-key"

# Redeploy functions
firebase deploy --only functions:initializeFlutterwavePayment,functions:verifyFlutterwavePayment
```

## Cost Considerations

### Flutterwave Fees
- Card payments: 1.4% + UGX 100 (capped at UGX 2,000)
- Mobile money: 1.4% + UGX 100
- Bank transfer: 1.4% + UGX 100

### Cloud Functions Costs
- Invocations: 2 million free/month
- Compute time: 400,000 GB-seconds free/month

Typical cost per transaction: ~$0.0001 (negligible)

## Files Modified/Created

### Cloud Functions
- ✅ `functions/package.json` - Added axios dependency
- ✅ `functions/src/index.ts` - Added payment functions

### Flutter App
- ✅ `purl-stores-app(buyer)/lib/services/payment_service.dart` - Payment service
- ✅ `purl-stores-app(buyer)/lib/screens/payment_screen.dart` - Payment webview
- ✅ `purl-stores-app(buyer)/lib/screens/checkout_screen.dart` - Updated checkout flow
- ✅ `purl-stores-app(buyer)/pubspec.yaml` - Added dependencies

## Next Steps

1. Set environment variables
2. Install dependencies
3. Deploy Cloud Functions
4. Test with test cards
5. Go live when ready

---

**Last Updated**: February 20, 2026
**Integration Version**: Flutterwave V3 Standard
**Status**: Ready for Testing
