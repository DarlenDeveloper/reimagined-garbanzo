# Phase 3: Shopping Flow - Cart, Orders & Inventory

## Overview

Implement shopping cart, checkout process, order management, and inventory tracking using Cloud Firestore with real-time updates.

## Firestore Collections

### Cart Collection

```
/carts/{userId}
├── userId: string
├── items: array
│   ├── productId: string
│   ├── vendorId: string
│   ├── name: string
│   ├── imageUrl: string
│   ├── price: number
│   ├── quantity: number
│   ├── variantId: string?
│   ├── variantName: string?
│   └── addedAt: timestamp
├── itemCount: number
├── subtotal: number
└── updatedAt: timestamp
```

### Orders Collection

```
/orders/{orderId}
├── id: string
├── orderNumber: string (human-readable: PRL-20260106-XXXX)
├── buyerId: string
├── buyerName: string
├── buyerEmail: string
├── buyerPhone: string
├── vendorId: string
├── vendorName: string
├── items: array
│   ├── productId: string
│   ├── name: string
│   ├── imageUrl: string
│   ├── price: number
│   ├── quantity: number
│   ├── variantId: string?
│   ├── variantName: string?
│   └── subtotal: number
├── subtotal: number
├── deliveryFee: number
├── discount: number
├── couponCode: string?
├── total: number
├── commission: number (3% of total)
├── netAmount: number (total - commission)
├── currency: string
├── status: OrderStatus
├── paymentStatus: PaymentStatus
├── paymentMethod: string
├── pesapalOrderId: string?
├── pesapalTransactionId: string?
├── deliveryAddress: map
│   ├── street: string
│   ├── city: string
│   ├── state: string
│   ├── postalCode: string
│   ├── country: string
│   ├── latitude: number?
│   └── longitude: number?
├── deliveryNotes: string?
├── uberDeliveryId: string?
├── estimatedDelivery: timestamp?
├── createdAt: timestamp
├── updatedAt: timestamp
├── acceptedAt: timestamp?
├── readyAt: timestamp?
├── pickedUpAt: timestamp?
├── deliveredAt: timestamp?
└── cancelledAt: timestamp?
```

### Order Status Enum

```typescript
enum OrderStatus {
  PENDING = 'pending',           // Order placed, awaiting vendor
  ACCEPTED = 'accepted',         // Vendor accepted
  PROCESSING = 'processing',     // Being prepared
  READY = 'ready',               // Ready for pickup
  PICKED_UP = 'picked_up',       // Driver picked up
  IN_TRANSIT = 'in_transit',     // On the way
  DELIVERED = 'delivered',       // Completed
  CANCELLED = 'cancelled',       // Cancelled
  REFUNDED = 'refunded'          // Refunded
}

enum PaymentStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  REFUNDED = 'refunded'
}
```

### Order History Subcollection

```
/orders/{orderId}/history/{historyId}
├── id: string
├── status: string
├── message: string
├── actor: 'system' | 'vendor' | 'buyer' | 'driver'
├── actorId: string?
└── createdAt: timestamp
```

### Inventory Transactions Collection

```
/inventoryTransactions/{transactionId}
├── id: string
├── productId: string
├── vendorId: string
├── variantId: string?
├── type: 'sale' | 'restock' | 'adjustment' | 'return'
├── quantity: number (negative for sales)
├── previousStock: number
├── newStock: number
├── orderId: string?
├── reason: string?
└── createdAt: timestamp
```

## Cart Operations

### Add to Cart

```typescript
// Cloud Function: addToCart
export const addToCart = functions.https.onCall(async (data, context) => {
  const { productId, quantity, variantId } = data;
  const userId = context.auth?.uid;
  
  // Validate product exists and has stock
  const product = await db.collection('products').doc(productId).get();
  if (!product.exists) throw new Error('Product not found');
  
  const productData = product.data();
  const availableStock = variantId 
    ? productData.variants.find(v => v.id === variantId)?.stock 
    : productData.stock;
  
  if (productData.trackInventory && quantity > availableStock) {
    throw new Error('Insufficient stock');
  }
  
  // Update cart
  const cartRef = db.collection('carts').doc(userId);
  await db.runTransaction(async (transaction) => {
    const cart = await transaction.get(cartRef);
    const items = cart.exists ? cart.data().items : [];
    
    // Check if item already in cart
    const existingIndex = items.findIndex(
      i => i.productId === productId && i.variantId === variantId
    );
    
    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.push({
        productId,
        vendorId: productData.vendorId,
        name: productData.name,
        imageUrl: productData.images[0]?.url,
        price: productData.price,
        quantity,
        variantId,
        variantName: variantId ? productData.variants.find(v => v.id === variantId)?.name : null,
        addedAt: FieldValue.serverTimestamp()
      });
    }
    
    const subtotal = items.reduce((sum, i) => sum + (i.price * i.quantity), 0);
    
    transaction.set(cartRef, {
      userId,
      items,
      itemCount: items.reduce((sum, i) => sum + i.quantity, 0),
      subtotal,
      updatedAt: FieldValue.serverTimestamp()
    });
  });
});
```

### Update Cart Item

```typescript
// Cloud Function: updateCartItem
export const updateCartItem = functions.https.onCall(async (data, context) => {
  const { productId, variantId, quantity } = data;
  const userId = context.auth?.uid;
  
  const cartRef = db.collection('carts').doc(userId);
  
  await db.runTransaction(async (transaction) => {
    const cart = await transaction.get(cartRef);
    if (!cart.exists) throw new Error('Cart not found');
    
    let items = cart.data().items;
    
    if (quantity <= 0) {
      // Remove item
      items = items.filter(
        i => !(i.productId === productId && i.variantId === variantId)
      );
    } else {
      // Update quantity
      const index = items.findIndex(
        i => i.productId === productId && i.variantId === variantId
      );
      if (index >= 0) {
        items[index].quantity = quantity;
      }
    }
    
    const subtotal = items.reduce((sum, i) => sum + (i.price * i.quantity), 0);
    
    transaction.update(cartRef, {
      items,
      itemCount: items.reduce((sum, i) => sum + i.quantity, 0),
      subtotal,
      updatedAt: FieldValue.serverTimestamp()
    });
  });
});
```

## Order Operations

### Create Order

```typescript
// Cloud Function: createOrder
export const createOrder = functions.https.onCall(async (data, context) => {
  const { deliveryAddress, deliveryNotes, couponCode } = data;
  const userId = context.auth?.uid;
  
  // Get cart
  const cart = await db.collection('carts').doc(userId).get();
  if (!cart.exists || cart.data().items.length === 0) {
    throw new Error('Cart is empty');
  }
  
  const cartData = cart.data();
  const buyer = await db.collection('users').doc(userId).get();
  const buyerData = buyer.data();
  
  // Group items by vendor
  const itemsByVendor = groupBy(cartData.items, 'vendorId');
  
  const orders = [];
  
  // Create separate order for each vendor
  for (const [vendorId, items] of Object.entries(itemsByVendor)) {
    const vendor = await db.collection('vendors').doc(vendorId).get();
    const vendorData = vendor.data();
    
    const subtotal = items.reduce((sum, i) => sum + (i.price * i.quantity), 0);
    const deliveryFee = 200; // Calculate based on distance
    const discount = 0; // Apply coupon if valid
    const total = subtotal + deliveryFee - discount;
    const commission = total * 0.03; // 3% commission
    
    const orderNumber = generateOrderNumber();
    
    const orderRef = db.collection('orders').doc();
    const order = {
      id: orderRef.id,
      orderNumber,
      buyerId: userId,
      buyerName: buyerData.displayName,
      buyerEmail: buyerData.email,
      buyerPhone: buyerData.phone,
      vendorId,
      vendorName: vendorData.storeName,
      items,
      subtotal,
      deliveryFee,
      discount,
      couponCode,
      total,
      commission,
      netAmount: total - commission,
      currency: 'KES',
      status: 'pending',
      paymentStatus: 'pending',
      deliveryAddress,
      deliveryNotes,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    };
    
    await orderRef.set(order);
    
    // Add initial history entry
    await orderRef.collection('history').add({
      status: 'pending',
      message: 'Order placed',
      actor: 'system',
      createdAt: FieldValue.serverTimestamp()
    });
    
    orders.push(order);
  }
  
  // Clear cart
  await db.collection('carts').doc(userId).delete();
  
  return { orders };
});
```

### Update Order Status (Vendor)

```typescript
// Cloud Function: updateOrderStatus
export const updateOrderStatus = functions.https.onCall(async (data, context) => {
  const { orderId, status, message } = data;
  const vendorId = context.auth?.uid;
  
  const orderRef = db.collection('orders').doc(orderId);
  const order = await orderRef.get();
  
  if (!order.exists) throw new Error('Order not found');
  if (order.data().vendorId !== vendorId) throw new Error('Unauthorized');
  
  const updates: any = {
    status,
    updatedAt: FieldValue.serverTimestamp()
  };
  
  // Set timestamp based on status
  switch (status) {
    case 'accepted':
      updates.acceptedAt = FieldValue.serverTimestamp();
      break;
    case 'ready':
      updates.readyAt = FieldValue.serverTimestamp();
      break;
    case 'cancelled':
      updates.cancelledAt = FieldValue.serverTimestamp();
      break;
  }
  
  await orderRef.update(updates);
  
  // Add history entry
  await orderRef.collection('history').add({
    status,
    message: message || `Order ${status}`,
    actor: 'vendor',
    actorId: vendorId,
    createdAt: FieldValue.serverTimestamp()
  });
  
  // Send notification to buyer
  await sendOrderNotification(order.data().buyerId, orderId, status);
  
  return { success: true };
});
```

## Inventory Management

### Decrement Stock on Order

```typescript
// Triggered when order payment is completed
export const decrementInventory = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only process when payment becomes completed
    if (before.paymentStatus !== 'completed' && after.paymentStatus === 'completed') {
      const batch = db.batch();
      
      for (const item of after.items) {
        const productRef = db.collection('products').doc(item.productId);
        const product = await productRef.get();
        const productData = product.data();
        
        if (productData.trackInventory) {
          const previousStock = item.variantId
            ? productData.variants.find(v => v.id === item.variantId)?.stock
            : productData.stock;
          
          const newStock = previousStock - item.quantity;
          
          if (item.variantId) {
            // Update variant stock
            const variants = productData.variants.map(v => 
              v.id === item.variantId ? { ...v, stock: newStock } : v
            );
            batch.update(productRef, { variants });
          } else {
            batch.update(productRef, { stock: newStock });
          }
          
          // Log transaction
          const txRef = db.collection('inventoryTransactions').doc();
          batch.set(txRef, {
            id: txRef.id,
            productId: item.productId,
            vendorId: after.vendorId,
            variantId: item.variantId,
            type: 'sale',
            quantity: -item.quantity,
            previousStock,
            newStock,
            orderId: context.params.orderId,
            createdAt: FieldValue.serverTimestamp()
          });
          
          // Check low stock alert
          if (newStock <= productData.lowStockThreshold) {
            await sendLowStockAlert(after.vendorId, item.productId, newStock);
          }
        }
      }
      
      await batch.commit();
    }
  });
```

## API Endpoints

### Cart APIs

```typescript
POST   /api/cart/add              // Add item to cart
PUT    /api/cart/update           // Update item quantity
DELETE /api/cart/remove           // Remove item from cart
GET    /api/cart                  // Get cart contents
DELETE /api/cart/clear            // Clear entire cart
```

### Order APIs

```typescript
POST   /api/orders                // Create order
GET    /api/orders                // Get user's orders
GET    /api/orders/{orderId}      // Get order details
PUT    /api/orders/{orderId}/status  // Update order status (vendor)
POST   /api/orders/{orderId}/cancel  // Cancel order
GET    /api/vendors/{vendorId}/orders // Get vendor's orders
```

## Security Rules

```javascript
// Carts
match /carts/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// Orders
match /orders/{orderId} {
  allow read: if request.auth.uid == resource.data.buyerId ||
              request.auth.uid == resource.data.vendorId;
  allow create: if request.auth != null;
  allow update: if request.auth.uid == resource.data.vendorId;
}

// Order History
match /orders/{orderId}/history/{historyId} {
  allow read: if request.auth.uid == get(/databases/$(database)/documents/orders/$(orderId)).data.buyerId ||
              request.auth.uid == get(/databases/$(database)/documents/orders/$(orderId)).data.vendorId;
}

// Inventory Transactions
match /inventoryTransactions/{txId} {
  allow read: if request.auth.uid == resource.data.vendorId;
  allow write: if false; // Only via Cloud Functions
}
```

## Implementation Checklist

- [ ] Create Firestore collections
- [ ] Implement cart Cloud Functions
- [ ] Implement order Cloud Functions
- [ ] Implement inventory management
- [ ] Build cart UI in buyer app
- [ ] Build checkout flow in buyer app
- [ ] Build order management in vendor app
- [ ] Build order tracking in buyer app
- [ ] Implement real-time order updates
- [ ] Test complete shopping flow
