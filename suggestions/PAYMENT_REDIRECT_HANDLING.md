# Flutterwave Payment Redirect Handling

## Overview
This document explains how the payment system handles verification redirects for card and mobile money payments.

## Problem Solved
Previously, the payment implementation used the deprecated V3 direct charges API without properly handling verification redirects. This caused payments to appear successful without completing the verification step (captcha, OTP, 3DS, etc.).

## Solution Implemented

### 1. Backend Changes (Cloud Functions)

#### Card Payments (`chargeCard`)
- Added `redirect_url` parameter to Flutterwave API call
- Returns `redirectUrl` and `authMode` in response
- Stores redirect URL in Firestore payment record
- Handles 3DS verification redirects

#### Mobile Money Payments (`chargeMobileMoney`)
- Added `redirect_url` parameter for verification
- Returns `redirectUrl` when captcha verification is needed (test mode)
- Stores payment as "pending" until verified
- Supports both redirect and phone approval flows

### 2. Frontend Changes (Flutter App)

#### Payment Processing Flow

**Card Payment:**
1. User enters card details
2. App calls `chargeCard` Cloud Function
3. If `redirectUrl` is returned:
   - Show verification dialog
   - User confirms they completed verification
   - App verifies payment status with backend
4. If successful, create order and show success screen

**Mobile Money Payment:**
1. User enters phone number
2. App calls `chargeMobileMoney` Cloud Function
3. If `redirectUrl` is returned:
   - Show verification dialog (for test mode captcha)
   - User completes verification
   - App verifies payment status
4. If no redirect (production):
   - Show "Check your phone" message
   - Poll payment status every 3 seconds (max 20 attempts = 60 seconds)
   - When verified, create order and show success screen

#### New Components

**Verification Dialog:**
- Shows when redirect URL is present
- Allows user to confirm verification completion
- Verifies payment status before proceeding

**Polling Dialog:**
- Shows for mobile money payments without redirect
- Polls payment status every 3 seconds
- Shows attempt counter (X of 20)
- Allows user to cancel
- Auto-closes on success or timeout

### 3. Payment Status Flow

```
Initiate Payment
      ↓
Cloud Function Call
      ↓
Flutterwave API Response
      ↓
Has redirectUrl? ──Yes──→ Show Verification Dialog
      ↓                           ↓
      No                    User Completes
      ↓                           ↓
Mobile Money? ──Yes──→ Show Polling Dialog
      ↓                           ↓
      No                    Poll Status (3s intervals)
      ↓                           ↓
Verify Status ←─────────────────┘
      ↓
Success? ──Yes──→ Create Order → Success Screen
      ↓
      No
      ↓
Show Error
```

## Testing

### Test Card (with 3DS)
- Card: 5531886652142950
- CVV: 564
- Expiry: 09/32
- PIN: 3310
- OTP: 12345

### Test Mobile Money
- Network: MTN or AIRTEL
- Phone: Any valid format (e.g., 0700000000)
- In test mode: May show captcha redirect
- In production: User approves on phone

## Firestore Structure

### /payments/{txRef}
```javascript
{
  userId: "user123",
  txRef: "PURL_abc12345_1234567890",
  amount: 50000,
  currency: "UGX",
  status: "pending" | "approved" | "failed",
  paymentMethod: "card" | "mobile_money",
  network: "MTN" | "AIRTEL" | null,
  transactionId: "1234567",
  flwRef: "FLW-...",
  redirectUrl: "https://...", // If verification needed
  authMode: "redirect" | "pin" | "otp" | null,
  createdAt: timestamp,
  verifiedAt: timestamp
}
```

## Key Improvements

1. ✅ Proper redirect handling for verification
2. ✅ Status polling for mobile money payments
3. ✅ Better user feedback during payment process
4. ✅ Timeout handling (60 seconds for mobile money)
5. ✅ Cancel option for users
6. ✅ Proper error messages
7. ✅ Payment status verification before order creation

## Known Limitations

1. **Webview Implementation**: Currently using a simple dialog for verification. In production, implement a proper webview with URL monitoring to automatically detect verification completion.

2. **Polling Interval**: 3-second polling may be too frequent. Consider increasing to 5 seconds in production.

3. **Timeout Duration**: 60 seconds may be too short for some users. Consider increasing to 120 seconds.

## Future Enhancements

1. **Proper Webview**: Implement `webview_flutter` to open redirect URL and monitor for completion
2. **Webhook Support**: Add webhook endpoint to receive real-time payment status updates
3. **Push Notifications**: Notify user when payment is confirmed (for mobile money)
4. **Payment History**: Show pending payments in user's payment history
5. **Retry Logic**: Allow users to retry failed payments

## Deployment

```bash
# Make script executable
chmod +x deploy-payment-functions.sh

# Deploy functions
./deploy-payment-functions.sh
```

## Monitoring

```bash
# View function logs
firebase functions:log

# View specific function logs
firebase functions:log --only chargeCard
firebase functions:log --only chargeMobileMoney
```

## Troubleshooting

### Payment stuck in pending
- Check Flutterwave dashboard for transaction status
- Verify payment with `verifyFlutterwavePayment` function
- Check function logs for errors

### Redirect not working
- Verify redirect URL is returned from Flutterwave
- Check that verification dialog is shown
- Ensure payment verification is called after dialog

### Polling timeout
- Increase max attempts in `_PollingDialog`
- Check if user approved payment on phone
- Verify network connectivity

---

**Last Updated**: February 20, 2026
**Status**: Implemented and Ready for Testing
