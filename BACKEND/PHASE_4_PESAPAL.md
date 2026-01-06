# Phase 4: Payment Integration - Pesapal

## Overview

Integrate Pesapal payment gateway for processing payments in the Purl platform. Pesapal supports M-Pesa, Airtel Money, credit/debit cards, and bank transfers - ideal for African markets.

## Pesapal Configuration

### Environment Setup

```typescript
// Environment variables
PESAPAL_CONSUMER_KEY=your_consumer_key
PESAPAL_CONSUMER_SECRET=your_consumer_secret
PESAPAL_API_URL=https://pay.pesapal.com/v3  // Production
// PESAPAL_API_URL=https://cybqa.pesapal.com/pesapalv3  // Sandbox
PESAPAL_IPN_URL=https://your-domain.com/api/pesapal/ipn
```

### Supported Payment Methods

| Method | Type | Countries |
|--------|------|-----------|
| M-Pesa | Mobile Money | Kenya, Tanzania |
| Airtel Money | Mobile Money | Kenya, Uganda, Tanzania |
| Visa/Mastercard | Card | All |
| Bank Transfer | Bank | Kenya |

## Pesapal API Integration

### Authentication

```typescript
// functions/src/payments/pesapal.ts
import axios from 'axios';

const PESAPAL_API = process.env.PESAPAL_API_URL;

async function getAccessToken(): Promise<string> {
  const response = await axios.post(`${PESAPAL_API}/api/Auth/RequestToken`, {
    consumer_key: process.env.PESAPAL_CONSUMER_KEY,
    consumer_secret: process.env.PESAPAL_CONSUMER_SECRET
  });
  
  return response.data.token;
}
```

### Register IPN URL

```typescript
async function registerIPN(): Promise<string> {
  const token = await getAccessToken();
  
  const response = await axios.post(
    `${PESAPAL_API}/api/URLSetup/RegisterIPN`,
    {
      url: process.env.PESAPAL_IPN_URL,
      ipn_notification_type: 'POST'
    },
    { headers: { Authorization: `Bearer ${token}` } }
  );
  
  return response.data.ipn_id;
}
```


### Submit Order Request

```typescript
interface PesapalOrderRequest {
  id: string;
  currency: string;
  amount: number;
  description: string;
  callback_url: string;
  notification_id: string;
  billing_address: {
    email_address: string;
    phone_number: string;
    first_name: string;
    last_name: string;
  };
}

async function submitOrder(order: PesapalOrderRequest): Promise<{
  order_tracking_id: string;
  redirect_url: string;
}> {
  const token = await getAccessToken();
  
  const response = await axios.post(
    `${PESAPAL_API}/api/Transactions/SubmitOrderRequest`,
    order,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  
  return response.data;
}
```

### Get Transaction Status

```typescript
async function getTransactionStatus(orderTrackingId: string): Promise<{
  payment_method: string;
  amount: number;
  status_code: number;
  payment_status_description: string;
  confirmation_code: string;
}> {
  const token = await getAccessToken();
  
  const response = await axios.get(
    `${PESAPAL_API}/api/Transactions/GetTransactionStatus?orderTrackingId=${orderTrackingId}`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  
  return response.data;
}
```

## Cloud Functions

### Initiate Payment

```typescript
// functions/src/payments/initiatePayment.ts
export const initiatePayment = functions.https.onCall(async (data, context) => {
  const { orderId } = data;
  const userId = context.auth?.uid;
  
  // Get order
  const orderRef = db.collection('orders').doc(orderId);
  const order = await orderRef.get();
  
  if (!order.exists) throw new Error('Order not found');
  if (order.data().buyerId !== userId) throw new Error('Unauthorized');
  
  const orderData = order.data();
  const user = await db.collection('users').doc(userId).get();
  const userData = user.data();
  
  // Get IPN ID (register once and store)
  const ipnId = await getOrRegisterIPN();
  
  // Submit to Pesapal
  const pesapalOrder = await submitOrder({
    id: orderId,
    currency: orderData.currency,
    amount: orderData.total,
    description: `Order ${orderData.orderNumber}`,
    callback_url: `https://your-app.com/payment/callback?orderId=${orderId}`,
    notification_id: ipnId,
    billing_address: {
      email_address: userData.email,
      phone_number: userData.phone || '',
      first_name: userData.displayName.split(' ')[0],
      last_name: userData.displayName.split(' ').slice(1).join(' ') || ''
    }
  });
  
  // Update order with Pesapal tracking ID
  await orderRef.update({
    pesapalOrderId: pesapalOrder.order_tracking_id,
    updatedAt: FieldValue.serverTimestamp()
  });
  
  return {
    redirectUrl: pesapalOrder.redirect_url,
    orderTrackingId: pesapalOrder.order_tracking_id
  };
});
```


### IPN Webhook Handler

```typescript
// functions/src/payments/pesapalIPN.ts
export const pesapalIPN = functions.https.onRequest(async (req, res) => {
  const { OrderTrackingId, OrderMerchantReference, OrderNotificationType } = req.body;
  
  // Get transaction status from Pesapal
  const status = await getTransactionStatus(OrderTrackingId);
  
  const orderId = OrderMerchantReference;
  const orderRef = db.collection('orders').doc(orderId);
  
  // Map Pesapal status codes
  // 0 = Invalid, 1 = Completed, 2 = Failed, 3 = Reversed
  let paymentStatus: string;
  switch (status.status_code) {
    case 1:
      paymentStatus = 'completed';
      break;
    case 3:
      paymentStatus = 'refunded';
      break;
    default:
      paymentStatus = 'failed';
  }
  
  // Update order
  await orderRef.update({
    paymentStatus,
    paymentMethod: status.payment_method,
    pesapalTransactionId: status.confirmation_code,
    updatedAt: FieldValue.serverTimestamp()
  });
  
  // Add to order history
  await orderRef.collection('history').add({
    status: paymentStatus === 'completed' ? 'payment_received' : 'payment_failed',
    message: `Payment ${paymentStatus}: ${status.payment_status_description}`,
    actor: 'system',
    createdAt: FieldValue.serverTimestamp()
  });
  
  // If payment completed, notify vendor
  if (paymentStatus === 'completed') {
    const order = await orderRef.get();
    await sendNewOrderNotification(order.data().vendorId, orderId);
  }
  
  res.status(200).json({ status: 'ok' });
});
```

## Firestore Collections

### Transactions Collection

```
/transactions/{transactionId}
├── id: string
├── orderId: string
├── buyerId: string
├── vendorId: string
├── type: 'payment' | 'refund' | 'payout'
├── amount: number
├── commission: number
├── netAmount: number
├── currency: string
├── status: 'pending' | 'completed' | 'failed'
├── paymentMethod: string
├── pesapalOrderId: string?
├── pesapalTransactionId: string?
├── createdAt: timestamp
└── completedAt: timestamp?
```

### Vendor Payouts Collection

```
/payouts/{payoutId}
├── id: string
├── vendorId: string
├── amount: number
├── currency: string
├── status: 'pending' | 'processing' | 'completed' | 'failed'
├── payoutMethod: 'mpesa' | 'bank'
├── payoutDetails: map (encrypted)
├── orderIds: string[]
├── periodStart: timestamp
├── periodEnd: timestamp
├── createdAt: timestamp
└── completedAt: timestamp?
```

## Commission Calculation

```typescript
function calculateCommission(orderTotal: number): {
  commission: number;
  netAmount: number;
} {
  const COMMISSION_RATE = 0.03; // 3%
  const commission = Math.round(orderTotal * COMMISSION_RATE * 100) / 100;
  const netAmount = orderTotal - commission;
  
  return { commission, netAmount };
}
```

## Refund Processing

```typescript
export const processRefund = functions.https.onCall(async (data, context) => {
  const { orderId, reason } = data;
  // Verify admin or vendor authorization
  
  const orderRef = db.collection('orders').doc(orderId);
  const order = await orderRef.get();
  const orderData = order.data();
  
  // Pesapal refunds are manual - create refund record
  const refundRef = db.collection('transactions').doc();
  await refundRef.set({
    id: refundRef.id,
    orderId,
    buyerId: orderData.buyerId,
    vendorId: orderData.vendorId,
    type: 'refund',
    amount: -orderData.total,
    commission: -orderData.commission,
    netAmount: -orderData.netAmount,
    currency: orderData.currency,
    status: 'pending',
    reason,
    createdAt: FieldValue.serverTimestamp()
  });
  
  await orderRef.update({
    status: 'refunded',
    paymentStatus: 'refunded',
    updatedAt: FieldValue.serverTimestamp()
  });
  
  return { refundId: refundRef.id };
});
```

## Implementation Checklist

- [ ] Set up Pesapal merchant account
- [ ] Configure API credentials
- [ ] Register IPN URL
- [ ] Implement payment initiation
- [ ] Implement IPN webhook handler
- [ ] Build payment UI in Flutter
- [ ] Implement transaction logging
- [ ] Implement refund processing
- [ ] Build vendor payout system
- [ ] Test with sandbox environment
- [ ] Go live with production credentials
