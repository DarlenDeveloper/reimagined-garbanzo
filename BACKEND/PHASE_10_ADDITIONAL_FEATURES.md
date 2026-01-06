# Phase 10: Additional Features (BNPL, Coupons, Reviews, Wishlist)

## Overview

This document covers additional features identified in the apps: BNPL (Buy Now Pay Later), Coupons/Discounts, Social Feed/Stories, Marketing Campaigns, Wishlist, and Reviews.

---

## 1. Buy Now Pay Later (BNPL)

### Firestore Collections

```
/bnplPlans/{planId}
├── id: string
├── buyerId: string
├── orderId: string
├── orderNumber: string
├── vendorId: string
├── productName: string
├── productImage: string
├── originalAmount: number
├── totalPayable: number (with interest/fees)
├── currency: string
├── installments: number (total)
├── paidInstallments: number
├── installmentAmount: number
├── status: 'active' | 'completed' | 'overdue' | 'defaulted'
├── nextPaymentDate: timestamp
├── schedule: array
│   ├── installmentNumber: number
│   ├── amount: number
│   ├── dueDate: timestamp
│   ├── paidDate: timestamp?
│   ├── status: 'pending' | 'paid' | 'overdue'
│   └── transactionId: string?
├── createdAt: timestamp
└── completedAt: timestamp?
```

### BNPL Settings (Platform Level)

```
/settings/bnpl
├── enabled: boolean
├── minOrderAmount: number
├── maxOrderAmount: number
├── interestRate: number (percentage)
├── availablePlans: array
│   ├── installments: number (3, 6, 12)
│   ├── interestRate: number
│   └── minAmount: number
└── eligibilityCriteria: map
```


### BNPL Cloud Functions

```typescript
// Create BNPL Plan
export const createBnplPlan = functions.https.onCall(async (data, context) => {
  const { orderId, installments } = data;
  const buyerId = context.auth?.uid;
  
  // Get order
  const order = await db.collection('orders').doc(orderId).get();
  if (!order.exists) throw new Error('Order not found');
  
  const orderData = order.data();
  
  // Get BNPL settings
  const settings = await db.collection('settings').doc('bnpl').get();
  const bnplSettings = settings.data();
  
  // Validate eligibility
  if (orderData.total < bnplSettings.minOrderAmount) {
    throw new Error('Order amount too low for BNPL');
  }
  
  // Calculate plan
  const plan = bnplSettings.availablePlans.find(p => p.installments === installments);
  const interest = orderData.total * (plan.interestRate / 100);
  const totalPayable = orderData.total + interest;
  const installmentAmount = totalPayable / installments;
  
  // Generate schedule
  const schedule = [];
  for (let i = 1; i <= installments; i++) {
    const dueDate = new Date();
    dueDate.setMonth(dueDate.getMonth() + i);
    schedule.push({
      installmentNumber: i,
      amount: installmentAmount,
      dueDate: Timestamp.fromDate(dueDate),
      status: 'pending'
    });
  }
  
  // Create plan
  const planRef = db.collection('bnplPlans').doc();
  await planRef.set({
    id: planRef.id,
    buyerId,
    orderId,
    orderNumber: orderData.orderNumber,
    vendorId: orderData.vendorId,
    productName: orderData.items[0].name,
    productImage: orderData.items[0].imageUrl,
    originalAmount: orderData.total,
    totalPayable,
    currency: orderData.currency,
    installments,
    paidInstallments: 0,
    installmentAmount,
    status: 'active',
    nextPaymentDate: schedule[0].dueDate,
    schedule,
    createdAt: FieldValue.serverTimestamp()
  });
  
  return { planId: planRef.id };
});

// Process BNPL Payment
export const processBnplPayment = functions.https.onCall(async (data, context) => {
  const { planId, installmentNumber } = data;
  const buyerId = context.auth?.uid;
  
  const planRef = db.collection('bnplPlans').doc(planId);
  const plan = await planRef.get();
  
  if (!plan.exists) throw new Error('Plan not found');
  if (plan.data().buyerId !== buyerId) throw new Error('Unauthorized');
  
  // Process payment via Pesapal
  // ... payment logic ...
  
  // Update plan
  const schedule = plan.data().schedule;
  schedule[installmentNumber - 1].status = 'paid';
  schedule[installmentNumber - 1].paidDate = FieldValue.serverTimestamp();
  
  const paidInstallments = plan.data().paidInstallments + 1;
  const isCompleted = paidInstallments === plan.data().installments;
  
  await planRef.update({
    schedule,
    paidInstallments,
    status: isCompleted ? 'completed' : 'active',
    nextPaymentDate: isCompleted ? null : schedule[installmentNumber]?.dueDate,
    completedAt: isCompleted ? FieldValue.serverTimestamp() : null
  });
  
  return { success: true };
});
```

---

## 2. Coupons & Discounts

### Firestore Collections

```
/coupons/{couponId}
├── id: string
├── vendorId: string
├── code: string (uppercase, unique per vendor)
├── type: 'percentage' | 'fixed'
├── value: number
├── minOrderAmount: number?
├── maxDiscount: number? (for percentage)
├── usageLimit: number?
├── usedCount: number
├── perUserLimit: number?
├── applicableProducts: string[]? (empty = all)
├── applicableCategories: string[]?
├── startDate: timestamp
├── endDate: timestamp
├── isActive: boolean
├── createdAt: timestamp
└── createdBy: string
```

### Coupon Usage Tracking

```
/coupons/{couponId}/usage/{usageId}
├── id: string
├── userId: string
├── orderId: string
├── discountAmount: number
└── usedAt: timestamp
```

### Coupon Validation Function

```typescript
export const validateCoupon = functions.https.onCall(async (data, context) => {
  const { code, vendorId, orderTotal, productIds } = data;
  const userId = context.auth?.uid;
  
  // Find coupon
  const couponSnapshot = await db.collection('coupons')
    .where('vendorId', '==', vendorId)
    .where('code', '==', code.toUpperCase())
    .where('isActive', '==', true)
    .limit(1)
    .get();
  
  if (couponSnapshot.empty) {
    return { valid: false, error: 'Invalid coupon code' };
  }
  
  const coupon = couponSnapshot.docs[0].data();
  const now = new Date();
  
  // Validate dates
  if (coupon.startDate.toDate() > now) {
    return { valid: false, error: 'Coupon not yet active' };
  }
  if (coupon.endDate.toDate() < now) {
    return { valid: false, error: 'Coupon expired' };
  }
  
  // Validate usage limit
  if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) {
    return { valid: false, error: 'Coupon usage limit reached' };
  }
  
  // Validate per-user limit
  if (coupon.perUserLimit) {
    const userUsage = await db.collection('coupons').doc(couponSnapshot.docs[0].id)
      .collection('usage').where('userId', '==', userId).get();
    if (userUsage.size >= coupon.perUserLimit) {
      return { valid: false, error: 'You have already used this coupon' };
    }
  }
  
  // Validate minimum order
  if (coupon.minOrderAmount && orderTotal < coupon.minOrderAmount) {
    return { valid: false, error: `Minimum order amount is ${coupon.minOrderAmount}` };
  }
  
  // Calculate discount
  let discount = coupon.type === 'percentage'
    ? orderTotal * (coupon.value / 100)
    : coupon.value;
  
  if (coupon.maxDiscount && discount > coupon.maxDiscount) {
    discount = coupon.maxDiscount;
  }
  
  return {
    valid: true,
    couponId: couponSnapshot.docs[0].id,
    discount,
    type: coupon.type,
    value: coupon.value
  };
});
```

---

## 3. Social Feed & Stories

### Stories Collection

```
/stories/{storyId}
├── id: string
├── vendorId: string
├── vendorName: string
├── vendorLogo: string
├── type: 'image' | 'video' | 'text' | 'promo'
├── mediaUrl: string?
├── thumbnailUrl: string?
├── backgroundColor: string? (for text stories)
├── textContent: string?
├── caption: string?
├── productId: string? (linked product)
├── promoCode: string?
├── discountPercent: number?
├── ctaText: string? (call to action)
├── ctaLink: string?
├── viewCount: number
├── viewedBy: string[] (user IDs, for analytics)
├── isActive: boolean
├── createdAt: timestamp
└── expiresAt: timestamp (24 hours for regular, 7 days for premium)
```

### Social Posts Collection

```
/posts/{postId}
├── id: string
├── vendorId: string
├── vendorName: string
├── vendorLogo: string
├── content: string
├── mediaUrls: string[]
├── type: 'promo' | 'announcement' | 'restock' | 'new_arrival' | 'general'
├── linkedProducts: string[]
├── promoCode: string?
├── discountPercent: number?
├── likes: number
├── likedBy: string[] (for small counts, use subcollection for large)
├── commentCount: number
├── shareCount: number
├── isPremium: boolean (7 days vs 24 hours)
├── isActive: boolean
├── createdAt: timestamp
└── expiresAt: timestamp
```

### Post Comments Subcollection

```
/posts/{postId}/comments/{commentId}
├── id: string
├── userId: string
├── userName: string
├── userAvatar: string?
├── content: string
├── likes: number
├── createdAt: timestamp
└── updatedAt: timestamp?
```

### Feed Generation

```typescript
// Get personalized feed for buyer
export const getFeed = functions.https.onCall(async (data, context) => {
  const { page = 1, limit = 20 } = data;
  const userId = context.auth?.uid;
  
  // Get followed vendors
  const followsSnapshot = await db.collection('followers')
    .where('buyerId', '==', userId)
    .get();
  
  const followedVendorIds = followsSnapshot.docs.map(d => d.data().vendorId);
  
  if (followedVendorIds.length === 0) {
    // Return trending posts if not following anyone
    const trending = await db.collection('posts')
      .where('isActive', '==', true)
      .where('expiresAt', '>', Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('likes', 'desc')
      .limit(limit)
      .get();
    
    return { posts: trending.docs.map(d => d.data()) };
  }
  
  // Get posts from followed vendors
  const posts = await db.collection('posts')
    .where('vendorId', 'in', followedVendorIds.slice(0, 10)) // Firestore limit
    .where('isActive', '==', true)
    .where('expiresAt', '>', Timestamp.now())
    .orderBy('expiresAt')
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();
  
  return { posts: posts.docs.map(d => d.data()) };
});
```

---

## 4. Marketing Campaigns

### Campaigns Collection

```
/campaigns/{campaignId}
├── id: string
├── vendorId: string
├── name: string
├── type: 'sms' | 'email' | 'push' | 'call'
├── status: 'draft' | 'scheduled' | 'running' | 'completed' | 'paused'
├── isAiPowered: boolean
├── content: map
│   ├── subject: string? (email)
│   ├── body: string
│   ├── template: string?
│   └── aiPrompt: string? (for AI campaigns)
├── audience: map
│   ├── type: 'all' | 'segment' | 'custom'
│   ├── segmentId: string?
│   └── customIds: string[]?
├── schedule: map
│   ├── sendAt: timestamp?
│   ├── timezone: string
│   └── recurring: boolean
├── stats: map
│   ├── sent: number
│   ├── delivered: number
│   ├── opened: number
│   ├── clicked: number
│   ├── converted: number
│   └── revenue: number
├── createdAt: timestamp
├── updatedAt: timestamp
└── completedAt: timestamp?
```

### Marketing Stats (Daily Aggregation)

```
/vendors/{vendorId}/marketingStats/{date}
├── date: string (YYYY-MM-DD)
├── sms: map { sent, delivered, responses }
├── email: map { sent, delivered, opened, clicked }
├── push: map { sent, delivered, opened }
├── calls: map { made, answered, converted }
├── totalReach: number
├── totalConversions: number
└── roi: number
```

---

## 5. Reviews & Ratings

### Reviews Collection (Extended)

```
/products/{productId}/reviews/{reviewId}
├── id: string
├── userId: string
├── userName: string
├── userAvatar: string?
├── orderId: string
├── rating: number (1-5)
├── title: string?
├── content: string
├── images: string[]
├── isVerifiedPurchase: boolean
├── helpfulCount: number
├── helpfulBy: string[]
├── vendorResponse: map?
│   ├── content: string
│   ├── respondedAt: timestamp
│   └── respondedBy: string
├── status: 'pending' | 'approved' | 'rejected' | 'flagged'
├── createdAt: timestamp
└── updatedAt: timestamp?
```

### Review Aggregation (on Product)

```typescript
// Trigger on review create/update
export const updateProductRating = functions.firestore
  .document('products/{productId}/reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const { productId } = context.params;
    
    const reviews = await db.collection('products').doc(productId)
      .collection('reviews')
      .where('status', '==', 'approved')
      .get();
    
    const totalRating = reviews.docs.reduce((sum, doc) => sum + doc.data().rating, 0);
    const avgRating = reviews.size > 0 ? totalRating / reviews.size : 0;
    
    await db.collection('products').doc(productId).update({
      rating: Math.round(avgRating * 10) / 10,
      reviewCount: reviews.size
    });
  });
```

---

## 6. Wishlist & Favorites

### Wishlist Collection

```
/buyers/{buyerId}/wishlist/{itemId}
├── productId: string
├── vendorId: string
├── productName: string
├── productImage: string
├── price: number
├── originalPrice: number?
├── addedAt: timestamp
├── notifyOnSale: boolean
└── notifyOnRestock: boolean
```

### Wishlist Notifications

```typescript
// Trigger when product price changes
export const notifyWishlistPriceChange = functions.firestore
  .document('products/{productId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if price decreased
    if (after.price < before.price) {
      // Find users with this product in wishlist
      const wishlistItems = await db.collectionGroup('wishlist')
        .where('productId', '==', context.params.productId)
        .where('notifyOnSale', '==', true)
        .get();
      
      for (const item of wishlistItems.docs) {
        const buyerId = item.ref.parent.parent.id;
        await sendPushNotification({
          userId: buyerId,
          title: 'Price Drop Alert! 🎉',
          body: `${after.name} is now ${after.price} (was ${before.price})`,
          type: 'wishlist_price_drop',
          data: { productId: context.params.productId }
        });
      }
    }
  });
```

## Implementation Checklist

- [ ] Implement BNPL plan creation and management
- [ ] Implement coupon/discount system
- [ ] Build social feed and stories
- [ ] Implement marketing campaign system
- [ ] Build review and rating system
- [ ] Implement wishlist with notifications
- [ ] Build all related UIs in both apps
- [ ] Test all features end-to-end
