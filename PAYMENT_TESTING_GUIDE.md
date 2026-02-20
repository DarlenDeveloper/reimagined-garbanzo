# Flutterwave Payment Testing Guide

## Prerequisites

1. ✅ Flutterwave test API keys configured in Secret Manager
2. ✅ Cloud Functions deployed
3. ✅ Flutter app built and running
4. ✅ Test user account created

## Setup

### 1. Deploy Cloud Functions

```bash
# Make script executable
chmod +x deploy-payment-functions.sh

# Deploy
./deploy-payment-functions.sh
```

### 2. Verify Secrets

```bash
# Check if secrets exist
firebase functions:secrets:access FLUTTERWAVE_SECRET_KEY
firebase functions:secrets:access FLUTTERWAVE_ENCRYPTION_KEY
```

If not set:
```bash
firebase functions:secrets:set FLUTTERWAVE_SECRET_KEY
# Enter: FLWSECK_TEST-e170249e1d2af65ea82d89bb1805b398-X

firebase functions:secrets:set FLUTTERWAVE_ENCRYPTION_KEY
# Enter: FLWSECK_TEST60f68ae50579
```

## Test Scenarios

### Scenario 1: Card Payment (Successful)

**Test Card Details:**
- Card Number: `5531886652142950`
- CVV: `564`
- Expiry: `09/32`
- PIN: `3310`
- OTP: `12345` (if prompted)

**Steps:**
1. Add items to cart
2. Go to checkout
3. Fill delivery details
4. Click "Proceed to Payment"
5. Select Visa or Mastercard logo
6. Enter test card details above
7. Click "Pay"
8. If redirect dialog appears:
   - Click "I Completed It"
9. Verify order is created
10. Check success screen shows correct details

**Expected Result:**
- ✅ Payment processes successfully
- ✅ Order created in Firestore
- ✅ Payment record in `/payments` collection
- ✅ Success screen displayed
- ✅ Cart cleared

**Check Firestore:**
```
/payments/{txRef}
  - status: "approved"
  - paymentMethod: "card"
  - transactionId: "..."
  
/stores/{storeId}/orders/{orderId}
  - paymentId: "..."
  - paymentMethod: "Card"
  - status: "pending"
```

### Scenario 2: Card Payment (Failed)

**Test Card Details:**
- Card Number: `5143010522339965`
- CVV: Any 3 digits
- Expiry: Any future date
- PIN: Any 4 digits

**Steps:**
1. Follow same steps as Scenario 1
2. Use failed test card

**Expected Result:**
- ❌ Payment fails
- ❌ Error message shown
- ❌ No order created
- ❌ User stays on payment screen

### Scenario 3: Mobile Money (MTN)

**Test Details:**
- Network: MTN (select MTN logo)
- Phone: `0700000000` (any valid format)

**Steps:**
1. Add items to cart
2. Go to checkout
3. Fill delivery details
4. Click "Proceed to Payment"
5. Select MTN logo
6. Enter phone number
7. Click "Pay"
8. If redirect dialog appears (test mode):
   - Complete captcha verification
   - Click "I Completed It"
9. If polling dialog appears:
   - Wait for verification (up to 60 seconds)
   - Or cancel to abort

**Expected Result (Test Mode):**
- ⚠️ May show redirect for captcha verification
- ⚠️ May show polling dialog
- ✅ Eventually succeeds or times out
- ✅ If successful, order created

**Expected Result (Production):**
- 📱 User receives prompt on phone
- ⏳ Polling dialog shows while waiting
- ✅ User approves on phone
- ✅ Payment verified
- ✅ Order created

### Scenario 4: Mobile Money (Airtel)

Same as Scenario 3, but select Airtel logo instead.

### Scenario 5: Payment Timeout

**Steps:**
1. Start mobile money payment
2. Don't approve on phone
3. Wait for polling timeout (60 seconds)

**Expected Result:**
- ⏱️ Polling dialog shows attempts (1-20)
- ⏱️ After 60 seconds, dialog closes
- ❌ Error message: "Payment not completed"
- ❌ No order created
- ✅ User can retry

### Scenario 6: Payment Cancellation

**Steps:**
1. Start mobile money payment
2. Click "Cancel" in polling dialog

**Expected Result:**
- ❌ Polling stops
- ❌ Dialog closes
- ❌ No order created
- ✅ User stays on payment screen

## Verification Checklist

After each test, verify:

### Firestore
- [ ] Payment record created in `/payments/{txRef}`
- [ ] Payment status correct (`pending`, `approved`, or `failed`)
- [ ] Order created in `/stores/{storeId}/orders/{orderId}` (if successful)
- [ ] Order created in `/users/{userId}/orders/{orderId}` (if successful)
- [ ] Cart cleared (if successful)

### Cloud Functions Logs
```bash
firebase functions:log --only chargeCard
firebase functions:log --only chargeMobileMoney
firebase functions:log --only verifyFlutterwavePayment
```

Check for:
- [ ] No errors in logs
- [ ] Correct API calls to Flutterwave
- [ ] Proper response handling
- [ ] Payment verification called

### Flutterwave Dashboard
1. Go to [Flutterwave Test Dashboard](https://dashboard.flutterwave.com/dashboard/transactions)
2. Check transactions list
3. Verify:
   - [ ] Transaction appears
   - [ ] Amount correct
   - [ ] Status correct
   - [ ] Customer details correct

### App UI
- [ ] Loading states show correctly
- [ ] Error messages are clear
- [ ] Success screen shows correct details
- [ ] Navigation works properly
- [ ] No crashes or freezes

## Common Issues

### Issue: "Flutterwave keys not configured"
**Solution:** Set up secrets in Secret Manager
```bash
firebase functions:secrets:set FLUTTERWAVE_SECRET_KEY
firebase functions:secrets:set FLUTTERWAVE_ENCRYPTION_KEY
```

### Issue: Payment stuck in "pending"
**Solution:** 
1. Check Flutterwave dashboard for actual status
2. Manually verify payment:
```dart
await _paymentService.verifyPayment(txRef: 'PURL_...');
```

### Issue: Redirect dialog doesn't appear
**Solution:**
1. Check function logs for redirect URL
2. Verify Flutterwave returns redirect URL
3. Check if `redirectUrl` is null in response

### Issue: Polling never completes
**Solution:**
1. Check if user approved payment on phone
2. Verify network connectivity
3. Check function logs for verification errors
4. Increase timeout if needed

### Issue: Order not created after successful payment
**Solution:**
1. Check app logs for order creation errors
2. Verify Firestore rules allow order creation
3. Check if cart data is valid

## Performance Testing

### Load Test
1. Process 10 payments in quick succession
2. Verify all complete successfully
3. Check for rate limiting issues

### Network Test
1. Test with slow network (3G)
2. Test with intermittent connectivity
3. Verify timeout handling

### Edge Cases
1. Very large amounts (> 1,000,000 UGX)
2. Very small amounts (< 100 UGX)
3. Special characters in names
4. Long phone numbers
5. Invalid card numbers

## Test Data Summary

### Successful Card
- Number: 5531886652142950
- CVV: 564
- Expiry: 09/32
- PIN: 3310

### Failed Card
- Number: 5143010522339965
- CVV: Any
- Expiry: Any future

### Mobile Money
- MTN: 0700000000
- Airtel: 0750000000

## Monitoring

### Real-time Logs
```bash
# Watch all payment function logs
firebase functions:log --only chargeCard,chargeMobileMoney,verifyFlutterwavePayment

# Watch with auto-refresh
watch -n 2 'firebase functions:log --only chargeCard --limit 10'
```

### Firestore Console
Monitor these collections:
- `/payments` - Payment records
- `/stores/{storeId}/orders` - Store orders
- `/users/{userId}/orders` - User orders

### Flutterwave Dashboard
- Transactions: https://dashboard.flutterwave.com/dashboard/transactions
- Logs: https://dashboard.flutterwave.com/dashboard/logs

## Success Criteria

A successful test should have:
- ✅ Payment initiated without errors
- ✅ Proper redirect/polling handling
- ✅ Payment verified successfully
- ✅ Order created in Firestore
- ✅ Success screen displayed
- ✅ Cart cleared
- ✅ No errors in logs
- ✅ Transaction visible in Flutterwave dashboard

## Next Steps After Testing

1. ✅ Test all scenarios above
2. ✅ Fix any issues found
3. ✅ Document any edge cases
4. ✅ Update error messages if needed
5. ✅ Prepare for production deployment

## Production Deployment

Before going live:
1. Replace test API keys with live keys
2. Update redirect URLs to production domain
3. Test with real small amounts
4. Set up monitoring and alerts
5. Document customer support process

---

**Last Updated**: February 20, 2026
**Status**: Ready for Testing
