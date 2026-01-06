# Phase 5: Delivery Integration - Uber Direct

## Overview

Integrate Uber Direct (Carrier API) for last-mile delivery coordination. Uber Direct allows businesses to request on-demand deliveries using Uber's driver network.

## Uber Direct Configuration

### Environment Setup

```typescript
// Environment variables
UBER_CLIENT_ID=your_client_id
UBER_CLIENT_SECRET=your_client_secret
UBER_CUSTOMER_ID=your_customer_id
UBER_API_URL=https://api.uber.com/v1/customers
// Sandbox: https://sandbox-api.uber.com/v1/customers
```

### API Authentication

```typescript
// functions/src/delivery/uber.ts
import axios from 'axios';

async function getAccessToken(): Promise<string> {
  const response = await axios.post(
    'https://login.uber.com/oauth/v2/token',
    new URLSearchParams({
      client_id: process.env.UBER_CLIENT_ID!,
      client_secret: process.env.UBER_CLIENT_SECRET!,
      grant_type: 'client_credentials',
      scope: 'eats.deliveries'
    }),
    { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
  );
  
  return response.data.access_token;
}
```

## Delivery Flow

```
1. Order marked "ready" by vendor
2. System creates delivery quote
3. Vendor confirms delivery request
4. Uber assigns driver
5. Driver picks up order
6. Driver delivers to customer
7. Delivery completed
```


## API Integration

### Create Delivery Quote

```typescript
interface DeliveryQuoteRequest {
  pickup: {
    address: string;
    latitude: number;
    longitude: number;
  };
  dropoff: {
    address: string;
    latitude: number;
    longitude: number;
  };
}

async function createQuote(request: DeliveryQuoteRequest): Promise<{
  id: string;
  fee: number;
  currency: string;
  eta: number; // minutes
  expires_at: string;
}> {
  const token = await getAccessToken();
  const customerId = process.env.UBER_CUSTOMER_ID;
  
  const response = await axios.post(
    `${process.env.UBER_API_URL}/${customerId}/delivery_quotes`,
    {
      pickup_address: request.pickup.address,
      pickup_latitude: request.pickup.latitude,
      pickup_longitude: request.pickup.longitude,
      dropoff_address: request.dropoff.address,
      dropoff_latitude: request.dropoff.latitude,
      dropoff_longitude: request.dropoff.longitude
    },
    { headers: { Authorization: `Bearer ${token}` } }
  );
  
  return response.data;
}
```

### Create Delivery Request

```typescript
interface DeliveryRequest {
  quote_id: string;
  pickup: {
    name: string;
    phone: string;
    address: string;
    latitude: number;
    longitude: number;
    instructions?: string;
  };
  dropoff: {
    name: string;
    phone: string;
    address: string;
    latitude: number;
    longitude: number;
    instructions?: string;
  };
  manifest: {
    description: string;
    quantity: number;
  };
}

async function createDelivery(request: DeliveryRequest): Promise<{
  id: string;
  status: string;
  tracking_url: string;
  fee: number;
}> {
  const token = await getAccessToken();
  const customerId = process.env.UBER_CUSTOMER_ID;
  
  const response = await axios.post(
    `${process.env.UBER_API_URL}/${customerId}/deliveries`,
    {
      quote_id: request.quote_id,
      pickup: {
        contact: {
          first_name: request.pickup.name,
          phone: { number: request.pickup.phone }
        },
        address: request.pickup.address,
        latitude: request.pickup.latitude,
        longitude: request.pickup.longitude,
        instructions: request.pickup.instructions
      },
      dropoff: {
        contact: {
          first_name: request.dropoff.name,
          phone: { number: request.dropoff.phone }
        },
        address: request.dropoff.address,
        latitude: request.dropoff.latitude,
        longitude: request.dropoff.longitude,
        instructions: request.dropoff.instructions
      },
      manifest: {
        description: request.manifest.description,
        quantity: request.manifest.quantity
      }
    },
    { headers: { Authorization: `Bearer ${token}` } }
  );
  
  return response.data;
}
```

### Get Delivery Status

```typescript
async function getDeliveryStatus(deliveryId: string): Promise<{
  id: string;
  status: string;
  courier?: {
    name: string;
    phone: string;
    vehicle: string;
    location: { latitude: number; longitude: number };
  };
  tracking_url: string;
  eta_minutes?: number;
}> {
  const token = await getAccessToken();
  const customerId = process.env.UBER_CUSTOMER_ID;
  
  const response = await axios.get(
    `${process.env.UBER_API_URL}/${customerId}/deliveries/${deliveryId}`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  
  return response.data;
}
```


## Cloud Functions

### Request Delivery Quote

```typescript
// functions/src/delivery/requestQuote.ts
export const requestDeliveryQuote = functions.https.onCall(async (data, context) => {
  const { orderId } = data;
  const vendorId = context.auth?.uid;
  
  const orderRef = db.collection('orders').doc(orderId);
  const order = await orderRef.get();
  
  if (!order.exists) throw new Error('Order not found');
  if (order.data().vendorId !== vendorId) throw new Error('Unauthorized');
  
  const orderData = order.data();
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const vendorData = vendor.data();
  
  const quote = await createQuote({
    pickup: {
      address: vendorData.address.formatted,
      latitude: vendorData.location.latitude,
      longitude: vendorData.location.longitude
    },
    dropoff: {
      address: `${orderData.deliveryAddress.street}, ${orderData.deliveryAddress.city}`,
      latitude: orderData.deliveryAddress.latitude,
      longitude: orderData.deliveryAddress.longitude
    }
  });
  
  // Store quote for later use
  await orderRef.update({
    deliveryQuote: {
      id: quote.id,
      fee: quote.fee,
      currency: quote.currency,
      eta: quote.eta,
      expiresAt: quote.expires_at
    },
    updatedAt: FieldValue.serverTimestamp()
  });
  
  return quote;
});
```

### Confirm Delivery Request

```typescript
// functions/src/delivery/confirmDelivery.ts
export const confirmDelivery = functions.https.onCall(async (data, context) => {
  const { orderId } = data;
  const vendorId = context.auth?.uid;
  
  const orderRef = db.collection('orders').doc(orderId);
  const order = await orderRef.get();
  const orderData = order.data();
  
  if (orderData.vendorId !== vendorId) throw new Error('Unauthorized');
  if (!orderData.deliveryQuote) throw new Error('No delivery quote');
  
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const vendorData = vendor.data();
  
  const delivery = await createDelivery({
    quote_id: orderData.deliveryQuote.id,
    pickup: {
      name: vendorData.storeName,
      phone: vendorData.contactPhone,
      address: vendorData.address.formatted,
      latitude: vendorData.location.latitude,
      longitude: vendorData.location.longitude,
      instructions: 'Please call upon arrival'
    },
    dropoff: {
      name: orderData.buyerName,
      phone: orderData.buyerPhone,
      address: `${orderData.deliveryAddress.street}, ${orderData.deliveryAddress.city}`,
      latitude: orderData.deliveryAddress.latitude,
      longitude: orderData.deliveryAddress.longitude,
      instructions: orderData.deliveryNotes
    },
    manifest: {
      description: `Order ${orderData.orderNumber}`,
      quantity: orderData.items.length
    }
  });
  
  await orderRef.update({
    uberDeliveryId: delivery.id,
    uberTrackingUrl: delivery.tracking_url,
    deliveryFee: delivery.fee,
    status: 'ready',
    updatedAt: FieldValue.serverTimestamp()
  });
  
  // Notify buyer
  await sendDeliveryNotification(orderData.buyerId, orderId, delivery.tracking_url);
  
  return delivery;
});
```

### Webhook Handler for Status Updates

```typescript
// functions/src/delivery/uberWebhook.ts
export const uberWebhook = functions.https.onRequest(async (req, res) => {
  const { event_type, delivery_id, data } = req.body;
  
  // Find order by delivery ID
  const ordersSnapshot = await db.collection('orders')
    .where('uberDeliveryId', '==', delivery_id)
    .limit(1)
    .get();
  
  if (ordersSnapshot.empty) {
    return res.status(404).json({ error: 'Order not found' });
  }
  
  const orderRef = ordersSnapshot.docs[0].ref;
  const orderData = ordersSnapshot.docs[0].data();
  
  // Map Uber status to order status
  const statusMap: Record<string, string> = {
    'delivery.pickup': 'picked_up',
    'delivery.dropoff': 'delivered',
    'delivery.cancelled': 'cancelled'
  };
  
  const newStatus = statusMap[event_type];
  if (!newStatus) return res.status(200).json({ status: 'ignored' });
  
  const updates: any = {
    status: newStatus,
    updatedAt: FieldValue.serverTimestamp()
  };
  
  if (newStatus === 'picked_up') {
    updates.pickedUpAt = FieldValue.serverTimestamp();
  } else if (newStatus === 'delivered') {
    updates.deliveredAt = FieldValue.serverTimestamp();
  }
  
  // Store courier info if available
  if (data.courier) {
    updates.courier = {
      name: data.courier.name,
      phone: data.courier.phone,
      vehicle: data.courier.vehicle_type
    };
  }
  
  await orderRef.update(updates);
  
  // Add history entry
  await orderRef.collection('history').add({
    status: newStatus,
    message: `Delivery ${newStatus.replace('_', ' ')}`,
    actor: 'system',
    createdAt: FieldValue.serverTimestamp()
  });
  
  // Notify buyer and vendor
  await sendDeliveryStatusNotification(orderData.buyerId, orderData.vendorId, newStatus);
  
  res.status(200).json({ status: 'ok' });
});
```

## Delivery Status Tracking

### Real-time Location Updates

```dart
// Flutter: Track delivery in real-time
Stream<DeliveryStatus> trackDelivery(String orderId) {
  return FirebaseFirestore.instance
    .collection('orders')
    .doc(orderId)
    .snapshots()
    .map((doc) => DeliveryStatus.fromFirestore(doc));
}
```

## Implementation Checklist

- [ ] Set up Uber Direct business account
- [ ] Configure API credentials
- [ ] Register webhook URL
- [ ] Implement quote request
- [ ] Implement delivery creation
- [ ] Implement webhook handler
- [ ] Build delivery UI in vendor app
- [ ] Build tracking UI in buyer app
- [ ] Test with sandbox environment
- [ ] Go live with production
