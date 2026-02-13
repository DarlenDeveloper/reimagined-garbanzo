# Purl Firestore Database Structure

## Overview
All data is isolated by `storeId`. Users can only access data for stores they're authorized to view.

---

## Collections

### 1. `stores`
Main store information.

```
stores/{storeId}
├── name: string
├── category: string
├── description: string
├── logoUrl: string
├── ownerId: string (uid of creator)
├── authorizedUsers: array [uid1, uid2, ...]
├── createdAt: timestamp
├── subscription: string ("free" | "pro" | "business")
├── address: map
│   ├── country: string
│   ├── street: string
│   ├── city: string
│   ├── state: string
│   └── postalCode: string
├── contact: map
│   ├── phone: string
│   ├── email: string
│   └── website: string
├── businessHours: map
│   ├── Monday: {isOpen: bool, open: string, close: string}
│   └── ... (all days)
├── paymentMethods: map
│   ├── cashOnDelivery: bool
│   ├── mobileMoney: bool
│   ├── momoNumber: string
│   ├── bankTransfer: bool
│   ├── bankName: string
│   ├── accountName: string
│   ├── accountNumber: string
│   └── cardPayments: bool
├── shipping: map
│   ├── localDelivery: bool
│   ├── localDeliveryFee: string
│   ├── nationwide: bool
│   ├── nationwideFee: string
│   └── storePickup: bool
└── inviteCode: map (temporary, deleted after use)
    ├── code: string
    └── expiresAt: timestamp
```

---

### 2. `stores/{storeId}/products`
Store inventory - subcollection under each store.

```
stores/{storeId}/products/{productId}
├── name: string
├── description: string
├── price: number
├── compareAtPrice: number (original price for discounts)
├── category: string
├── subcategory: string
├── images: array [url1, url2, ...]
├── stock: number
├── sku: string
├── barcode: string
├── weight: number
├── unit: string ("kg" | "g" | "lb" | "pcs")
├── isActive: bool
├── isFeatured: bool
├── tags: array [tag1, tag2, ...]
├── variants: array
│   └── {name: "Size", options: ["S", "M", "L"], prices: [10, 12, 15]}
├── createdAt: timestamp
└── updatedAt: timestamp
```

---

### 3. `stores/{storeId}/orders`
Customer orders - subcollection under each store.

```
stores/{storeId}/orders/{orderId}
├── orderNumber: string (human readable: "ORD-001234")
├── customerId: string (buyer's uid)
├── customerName: string
├── customerPhone: string
├── customerEmail: string
├── items: array
│   └── {productId, name, price, quantity, variant, imageUrl}
├── subtotal: number
├── deliveryFee: number
├── discount: number
├── total: number
├── status: string ("pending" | "confirmed" | "preparing" | "ready" | "shipped" | "delivered" | "cancelled")
├── paymentMethod: string
├── paymentStatus: string ("pending" | "paid" | "failed" | "refunded")
├── deliveryMethod: string ("local" | "nationwide" | "pickup")
├── deliveryAddress: map
│   ├── street: string
│   ├── city: string
│   ├── state: string
│   ├── postalCode: string
│   └── instructions: string
├── deliveryTracking: map
│   ├── provider: string ("uber_direct" | "custom")
│   ├── trackingId: string
│   └── trackingUrl: string
├── notes: string
├── createdAt: timestamp
└── updatedAt: timestamp
```

---

### 4. `stores/{storeId}/posts`
Social feed posts by the store.

```
stores/{storeId}/posts/{postId}
├── type: string ("image" | "video" | "product" | "story")
├── mediaUrls: array [url1, url2, ...]
├── thumbnailUrl: string (for videos)
├── caption: string
├── hashtags: array [tag1, tag2, ...]
├── productIds: array (linked products)
├── likes: number
├── comments: number
├── shares: number
├── isActive: bool
├── expiresAt: timestamp (for stories)
├── createdAt: timestamp
└── updatedAt: timestamp
```

---

### 5. `stores/{storeId}/team`
Store team members with roles.

```
stores/{storeId}/team/{oderId}
├── role: string ("admin" | "manager" | "runner" | "viewer")
├── permissions: array ["orders", "products", "analytics", "settings"]
├── addedBy: string (uid)
├── addedAt: timestamp
└── isActive: bool
```

---

### 6. `stores/{storeId}/analytics`
Daily analytics snapshots.

```
stores/{storeId}/analytics/{date}  // e.g., "2026-01-07"
├── views: number
├── orders: number
├── revenue: number
├── newCustomers: number
├── topProducts: array [{productId, name, sold, revenue}]
└── hourlyViews: map {0: 10, 1: 5, ...}
```

---

### 7. `stores/{storeId}/discounts`
Promotional codes and discounts.

```
stores/{storeId}/discounts/{discountId}
├── code: string ("SAVE20")
├── type: string ("percentage" | "fixed")
├── value: number (20 for 20% or 20 for $20)
├── minOrder: number
├── maxUses: number
├── usedCount: number
├── validFrom: timestamp
├── validUntil: timestamp
├── isActive: bool
└── createdAt: timestamp
```

---

### 8. `stores/{storeId}/reviews`
Customer reviews.

```
stores/{storeId}/reviews/{reviewId}
├── customerId: string
├── customerName: string
├── productId: string (optional, for product reviews)
├── orderId: string
├── rating: number (1-5)
├── comment: string
├── images: array [url1, url2, ...]
├── reply: string (store's response)
├── repliedAt: timestamp
├── isVerifiedPurchase: bool
└── createdAt: timestamp
```

---

### 9. `users`
Global user profiles (not store-specific).

```
users/{oderId}
├── displayName: string
├── email: string
├── phone: string
├── photoUrl: string
├── role: string ("buyer" | "seller")
├── storeIds: array [storeId1, storeId2, ...] (stores user has access to)
├── defaultStoreId: string
├── fcmTokens: array (for push notifications)
├── createdAt: timestamp
└── lastLoginAt: timestamp
```

---

### 10. `customers`
Buyer profiles (for the buyer app).

```
customers/{oderId}
├── displayName: string
├── email: string
├── phone: string
├── photoUrl: string
├── addresses: array
│   └── {label, street, city, state, postalCode, isDefault}
├── favoriteStores: array [storeId1, storeId2, ...]
├── wishlist: array [{storeId, productId}]
├── fcmTokens: array
├── createdAt: timestamp
└── lastLoginAt: timestamp
```

---

## Firebase Storage Structure

```
store_logos/{storeId}/logo.jpg
store_media/{storeId}/products/{productId}/{filename}
store_media/{storeId}/posts/{postId}/{filename}
user_avatars/{oderId}/avatar.jpg
```

---

## Security Rules Pattern

All store data access checks:
1. User is authenticated
2. User's UID is in `stores/{storeId}/authorizedUsers` array

```javascript
match /stores/{storeId}/{document=**} {
  allow read, write: if request.auth != null 
    && request.auth.uid in get(/databases/$(database)/documents/stores/$(storeId)).data.authorizedUsers;
}
```

---

## Query Examples

**Get user's store:**
```dart
firestore.collection('stores')
  .where('authorizedUsers', arrayContains: uid)
  .limit(1)
  .get();
```

**Get store products:**
```dart
firestore.collection('stores')
  .doc(storeId)
  .collection('products')
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .get();
```

**Get store orders:**
```dart
firestore.collection('stores')
  .doc(storeId)
  .collection('orders')
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
  .get();
```

---

## Key Points

1. **Store isolation**: All store data lives under `stores/{storeId}/...`
2. **No cross-store access**: Security rules enforce authorization
3. **Subcollections**: Products, orders, posts are subcollections (better scaling)
4. **Denormalization**: Some data duplicated for faster reads (e.g., customerName in orders)
5. **Timestamps**: All documents have `createdAt` for sorting/auditing
