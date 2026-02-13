# Phase 12: Additional Systems

## Overview

This document covers additional systems identified in the apps: Store Verification Badges, User Interests/Personalization, Rewards System, Receipts, FAQ/Help System, Audit Logs, Shipping Management, and Vendor Subscription Plans.

---

## 1. Store Verification Badges

### Badge Types

| Badge | Color | Criteria |
|-------|-------|----------|
| Blue | #1DA1F2 | Standard verified - Identity confirmed |
| Gold | #FFD700 | Premium/Top seller - High sales volume |
| Black | #000000 | Official/Brand - Authorized brand seller |

### Firestore Schema

```
/vendors/{vendorId}
├── ...existing fields...
├── verification: map
│   ├── status: 'unverified' | 'pending' | 'verified'
│   ├── badgeType: 'blue' | 'gold' | 'black' | null
│   ├── verifiedAt: timestamp?
│   ├── verifiedBy: string? (admin userId)
│   ├── documents: map
│   │   ├── businessLicense: string (storage URL)
│   │   ├── taxId: string
│   │   └── brandAuthorization: string? (for black badge)
│   ├── metrics: map (for gold badge eligibility)
│   │   ├── totalSales: number
│   │   ├── totalOrders: number
│   │   ├── avgRating: number
│   │   └── accountAge: number (days)
│   └── lastReviewedAt: timestamp?
```

### Verification Request Collection

```
/verificationRequests/{requestId}
├── id: string
├── vendorId: string
├── vendorName: string
├── requestedBadge: 'blue' | 'gold' | 'black'
├── status: 'pending' | 'approved' | 'rejected'
├── documents: map
│   ├── businessLicense: string
│   ├── taxId: string
│   └── additionalDocs: string[]
├── notes: string?
├── reviewedBy: string?
├── reviewedAt: timestamp?
├── rejectionReason: string?
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Badge Eligibility Criteria

```typescript
const BADGE_CRITERIA = {
  blue: {
    // Basic verification
    requiresBusinessLicense: true,
    requiresTaxId: true,
    minAccountAge: 30, // days
    minOrders: 10
  },
  gold: {
    // Top seller
    requiresBlueVerification: true,
    minTotalSales: 50000, // USD equivalent
    minOrders: 500,
    minRating: 4.5,
    minAccountAge: 180 // days
  },
  black: {
    // Official brand
    requiresBrandAuthorization: true,
    requiresBlueVerification: true,
    manualApprovalRequired: true
  }
};

// Auto-upgrade to Gold badge
export const checkGoldBadgeEligibility = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const vendors = await db.collection('vendors')
      .where('verification.badgeType', '==', 'blue')
      .get();
    
    for (const vendor of vendors.docs) {
      const data = vendor.data();
      const metrics = data.verification?.metrics || {};
      
      if (
        metrics.totalSales >= BADGE_CRITERIA.gold.minTotalSales &&
        metrics.totalOrders >= BADGE_CRITERIA.gold.minOrders &&
        metrics.avgRating >= BADGE_CRITERIA.gold.minRating &&
        metrics.accountAge >= BADGE_CRITERIA.gold.minAccountAge
      ) {
        await vendor.ref.update({
          'verification.badgeType': 'gold',
          'verification.upgradedAt': FieldValue.serverTimestamp()
        });
        
        // Notify vendor
        await sendNotification(data.ownerId, {
          title: '🏆 Congratulations!',
          body: 'Your store has been upgraded to Gold status!',
          type: 'badge_upgrade'
        });
      }
    }
  });
```

---

## 2. User Interests & Personalization

### Interests Collection

```
/users/{userId}/profile
├── ...existing fields...
├── interests: string[] (category IDs)
├── interestsUpdatedAt: timestamp
└── onboardingCompleted: boolean
```

### Available Interests

```
/settings/interests
├── categories: array
│   ├── id: string
│   ├── name: string
│   ├── icon: string
│   └── color: string
```

### Personalized Feed Algorithm

```typescript
// functions/src/feed/getPersonalizedFeed.ts
export const getPersonalizedFeed = functions.https.onCall(async (data, context) => {
  const { page = 1, limit = 20 } = data;
  const userId = context.auth?.uid;
  
  // Get user interests
  const userProfile = await db.collection('users').doc(userId)
    .collection('profile').doc('preferences').get();
  
  const interests = userProfile.data()?.interests || [];
  
  // Get followed vendors
  const follows = await db.collection('followers')
    .where('buyerId', '==', userId)
    .get();
  
  const followedVendorIds = follows.docs.map(d => d.data().vendorId);
  
  let posts = [];
  
  // Priority 1: Posts from followed vendors
  if (followedVendorIds.length > 0) {
    const followedPosts = await db.collection('posts')
      .where('vendorId', 'in', followedVendorIds.slice(0, 10))
      .where('isActive', '==', true)
      .where('expiresAt', '>', Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('createdAt', 'desc')
      .limit(limit / 2)
      .get();
    
    posts.push(...followedPosts.docs.map(d => ({ ...d.data(), source: 'following' })));
  }
  
  // Priority 2: Posts matching interests
  if (interests.length > 0) {
    const interestPosts = await db.collection('posts')
      .where('category', 'in', interests.slice(0, 10))
      .where('isActive', '==', true)
      .where('expiresAt', '>', Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('likes', 'desc')
      .limit(limit / 2)
      .get();
    
    posts.push(...interestPosts.docs.map(d => ({ ...d.data(), source: 'interests' })));
  }
  
  // Priority 3: Trending posts (fallback)
  if (posts.length < limit) {
    const trendingPosts = await db.collection('posts')
      .where('isActive', '==', true)
      .where('expiresAt', '>', Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('likes', 'desc')
      .limit(limit - posts.length)
      .get();
    
    posts.push(...trendingPosts.docs.map(d => ({ ...d.data(), source: 'trending' })));
  }
  
  // Deduplicate and shuffle
  const uniquePosts = [...new Map(posts.map(p => [p.id, p])).values()];
  
  return { posts: uniquePosts.slice(0, limit) };
});
```

---

## 3. Rewards System

### Rewards Configuration

```
/settings/rewards
├── enabled: boolean
├── pointsPerDollar: number (e.g., 10 points per $1)
├── redemptionRate: number (e.g., 100 points = $1)
├── welcomeBonus: number
├── referralBonus: number
├── reviewBonus: number
├── tiers: array
│   ├── name: string (Bronze, Silver, Gold, Platinum)
│   ├── minPoints: number
│   ├── multiplier: number (1x, 1.5x, 2x, 3x)
│   └── perks: string[]
```

### User Rewards Collection

```
/users/{userId}/rewards
├── totalPoints: number
├── availablePoints: number
├── lifetimePoints: number
├── tier: 'bronze' | 'silver' | 'gold' | 'platinum'
├── tierProgress: number (percentage to next tier)
├── referralCode: string
├── referralCount: number
└── updatedAt: timestamp
```

### Points Transactions

```
/users/{userId}/pointsHistory/{transactionId}
├── id: string
├── type: 'earned' | 'redeemed' | 'expired' | 'bonus'
├── source: 'purchase' | 'review' | 'referral' | 'welcome' | 'redemption'
├── points: number (positive for earned, negative for redeemed)
├── orderId: string?
├── description: string
├── expiresAt: timestamp?
├── createdAt: timestamp
```

### Earn Points on Purchase

```typescript
// functions/src/rewards/earnPoints.ts
export const earnPointsOnPurchase = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only when order is delivered
    if (before.status !== 'delivered' && after.status === 'delivered') {
      const buyerId = after.buyerId;
      const orderTotal = after.total;
      
      // Get rewards settings
      const settings = await db.collection('settings').doc('rewards').get();
      const rewardsConfig = settings.data();
      
      if (!rewardsConfig?.enabled) return;
      
      // Get user tier for multiplier
      const userRewards = await db.collection('users').doc(buyerId)
        .collection('rewards').doc('summary').get();
      
      const tier = userRewards.data()?.tier || 'bronze';
      const tierConfig = rewardsConfig.tiers.find(t => t.name.toLowerCase() === tier);
      const multiplier = tierConfig?.multiplier || 1;
      
      // Calculate points
      const basePoints = Math.floor(orderTotal * rewardsConfig.pointsPerDollar);
      const earnedPoints = Math.floor(basePoints * multiplier);
      
      // Add points
      await db.runTransaction(async (transaction) => {
        const rewardsRef = db.collection('users').doc(buyerId)
          .collection('rewards').doc('summary');
        
        const current = (await transaction.get(rewardsRef)).data() || {
          totalPoints: 0,
          availablePoints: 0,
          lifetimePoints: 0
        };
        
        transaction.set(rewardsRef, {
          totalPoints: current.totalPoints + earnedPoints,
          availablePoints: current.availablePoints + earnedPoints,
          lifetimePoints: current.lifetimePoints + earnedPoints,
          updatedAt: FieldValue.serverTimestamp()
        }, { merge: true });
        
        // Log transaction
        const historyRef = db.collection('users').doc(buyerId)
          .collection('pointsHistory').doc();
        
        transaction.set(historyRef, {
          id: historyRef.id,
          type: 'earned',
          source: 'purchase',
          points: earnedPoints,
          orderId: context.params.orderId,
          description: `Earned ${earnedPoints} points from order #${after.orderNumber}`,
          expiresAt: Timestamp.fromDate(new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)),
          createdAt: FieldValue.serverTimestamp()
        });
      });
      
      // Check tier upgrade
      await checkTierUpgrade(buyerId);
    }
  });
```

---

## 4. Receipts System

### Receipts Collection

```
/users/{userId}/receipts/{receiptId}
├── id: string
├── orderId: string
├── orderNumber: string
├── vendorId: string
├── vendorName: string
├── items: array
│   ├── name: string
│   ├── quantity: number
│   ├── price: number
│   └── total: number
├── subtotal: number
├── tax: number
├── shipping: number
├── discount: number
├── total: number
├── currency: string
├── paymentMethod: string
├── transactionId: string
├── status: 'success' | 'refunded' | 'partial_refund'
├── paidAt: timestamp
├── createdAt: timestamp
└── exportedAt: timestamp?
```

### Generate Receipt

```typescript
// functions/src/receipts/generateReceipt.ts
export const generateReceipt = functions.firestore
  .document('payments/{paymentId}')
  .onCreate(async (snapshot, context) => {
    const payment = snapshot.data();
    
    if (payment.status !== 'completed') return;
    
    const order = await db.collection('orders').doc(payment.orderId).get();
    const orderData = order.data();
    
    const receiptRef = db.collection('users').doc(payment.buyerId)
      .collection('receipts').doc();
    
    await receiptRef.set({
      id: receiptRef.id,
      orderId: payment.orderId,
      orderNumber: orderData.orderNumber,
      vendorId: orderData.vendorId,
      vendorName: orderData.vendorName,
      items: orderData.items.map(item => ({
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        total: item.price * item.quantity
      })),
      subtotal: orderData.subtotal,
      tax: orderData.tax || 0,
      shipping: orderData.shippingCost || 0,
      discount: orderData.discount || 0,
      total: payment.amount,
      currency: payment.currency,
      paymentMethod: payment.method,
      transactionId: payment.transactionId,
      status: 'success',
      paidAt: payment.completedAt,
      createdAt: FieldValue.serverTimestamp()
    });
  });
```

---

## 5. FAQ & Help System

### FAQ Collection

```
/faqs/{faqId}
├── id: string
├── question: string
├── answer: string
├── category: 'orders' | 'payments' | 'delivery' | 'returns' | 'account' | 'general'
├── order: number (display order)
├── isActive: boolean
├── viewCount: number
├── helpfulCount: number
├── notHelpfulCount: number
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Support Tickets

```
/supportTickets/{ticketId}
├── id: string
├── userId: string
├── userEmail: string
├── userName: string
├── subject: string
├── category: string
├── priority: 'low' | 'medium' | 'high' | 'urgent'
├── status: 'open' | 'in_progress' | 'waiting_customer' | 'resolved' | 'closed'
├── orderId: string? (if order-related)
├── messages: array
│   ├── id: string
│   ├── senderId: string
│   ├── senderType: 'customer' | 'support' | 'ai'
│   ├── content: string
│   ├── attachments: string[]
│   └── sentAt: timestamp
├── assignedTo: string?
├── resolvedAt: timestamp?
├── satisfactionRating: number? (1-5)
├── createdAt: timestamp
└── updatedAt: timestamp
```

---

## 6. Audit Logs

### Audit Log Collection

```
/auditLogs/{logId}
├── id: string
├── entityType: 'vendor' | 'product' | 'order' | 'user' | 'payment' | 'settings'
├── entityId: string
├── action: 'create' | 'update' | 'delete' | 'login' | 'logout' | 'export'
├── actorId: string
├── actorEmail: string
├── actorRole: string
├── vendorId: string? (for vendor-scoped actions)
├── changes: map
│   ├── field: string
│   ├── oldValue: any
│   └── newValue: any
├── metadata: map
│   ├── ipAddress: string
│   ├── userAgent: string
│   └── location: string?
├── timestamp: timestamp
```

### Audit Log Function

```typescript
// functions/src/audit/logAction.ts
export async function logAuditAction(params: {
  entityType: string;
  entityId: string;
  action: string;
  actorId: string;
  vendorId?: string;
  changes?: any;
  metadata?: any;
}) {
  const actor = await db.collection('users').doc(params.actorId).get();
  
  await db.collection('auditLogs').add({
    id: db.collection('auditLogs').doc().id,
    entityType: params.entityType,
    entityId: params.entityId,
    action: params.action,
    actorId: params.actorId,
    actorEmail: actor.data()?.email,
    actorRole: actor.data()?.role,
    vendorId: params.vendorId,
    changes: params.changes,
    metadata: params.metadata,
    timestamp: FieldValue.serverTimestamp()
  });
}

// Usage in product update
export const onProductUpdate = functions.firestore
  .document('products/{productId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    const changes = [];
    for (const key of Object.keys(after)) {
      if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) {
        changes.push({
          field: key,
          oldValue: before[key],
          newValue: after[key]
        });
      }
    }
    
    if (changes.length > 0) {
      await logAuditAction({
        entityType: 'product',
        entityId: context.params.productId,
        action: 'update',
        actorId: after.updatedBy,
        vendorId: after.vendorId,
        changes
      });
    }
  });
```

---

## 7. Vendor Subscription Plans

### Subscription Tiers

| Plan | Price | Features |
|------|-------|----------|
| Starter | Free | 10 products, 5% fee, basic analytics |
| Pro | $9.99/mo | Unlimited products, 2.5% fee, AI features, marketing |
| Business | $24.99/mo | Everything + API, 1% fee, dedicated manager |

### Subscription Collection

```
/vendors/{vendorId}/subscription
├── plan: 'starter' | 'pro' | 'business'
├── status: 'active' | 'past_due' | 'cancelled' | 'trialing'
├── currentPeriodStart: timestamp
├── currentPeriodEnd: timestamp
├── cancelAtPeriodEnd: boolean
├── trialEnd: timestamp?
├── paymentMethod: map
│   ├── type: string
│   ├── last4: string
│   └── expiryDate: string
├── billingHistory: array
│   ├── invoiceId: string
│   ├── amount: number
│   ├── currency: string
│   ├── status: string
│   └── paidAt: timestamp
├── features: map
│   ├── maxProducts: number
│   ├── transactionFee: number
│   ├── aiFeatures: boolean
│   ├── marketingTools: boolean
│   ├── apiAccess: boolean
│   └── dedicatedSupport: boolean
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Plan Features Configuration

```typescript
const SUBSCRIPTION_PLANS = {
  starter: {
    name: 'Starter',
    price: 0,
    features: {
      maxProducts: 10,
      transactionFee: 0.05, // 5%
      aiFeatures: false,
      marketingTools: false,
      apiAccess: false,
      dedicatedSupport: false,
      staffAccounts: 1
    }
  },
  pro: {
    name: 'Pro',
    price: 9.99,
    features: {
      maxProducts: -1, // unlimited
      transactionFee: 0.025, // 2.5%
      aiFeatures: true,
      marketingTools: true,
      apiAccess: false,
      dedicatedSupport: false,
      staffAccounts: 5
    }
  },
  business: {
    name: 'Business',
    price: 24.99,
    features: {
      maxProducts: -1,
      transactionFee: 0.01, // 1%
      aiFeatures: true,
      marketingTools: true,
      apiAccess: true,
      dedicatedSupport: true,
      staffAccounts: -1 // unlimited
    }
  }
};
```

---

## 8. Shipping Management (Non-Uber Direct)

For vendors who handle their own shipping or use other carriers.

### Shipments Collection

```
/vendors/{vendorId}/shipments/{shipmentId}
├── id: string
├── orderId: string
├── orderNumber: string
├── trackingNumber: string
├── carrier: string (Skynet, DHL, FedEx, etc.)
├── status: 'processing' | 'shipped' | 'in_transit' | 'delivered' | 'failed'
├── weight: number (kg)
├── dimensions: map
│   ├── length: number
│   ├── width: number
│   └── height: number
├── origin: map
│   ├── address: string
│   ├── city: string
│   └── country: string
├── destination: map
│   ├── address: string
│   ├── city: string
│   ├── country: string
│   └── recipientName: string
├── shippingCost: number
├── labelUrl: string?
├── estimatedDelivery: timestamp?
├── actualDelivery: timestamp?
├── trackingHistory: array
│   ├── status: string
│   ├── location: string
│   ├── description: string
│   └── timestamp: timestamp
├── createdAt: timestamp
└── updatedAt: timestamp
```

---

## Implementation Checklist

- [ ] Implement store verification system
- [ ] Build verification request flow
- [ ] Implement user interests selection
- [ ] Build personalized feed algorithm
- [ ] Implement rewards points system
- [ ] Build tier progression logic
- [ ] Implement receipts generation
- [ ] Build FAQ management system
- [ ] Implement audit logging
- [ ] Build subscription management
- [ ] Implement shipping management
- [ ] Test all systems end-to-end
