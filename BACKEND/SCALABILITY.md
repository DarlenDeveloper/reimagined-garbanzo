# Purl Platform - Scalability & High-Availability Architecture

## Executive Summary

This document addresses infrastructure scaling for the Purl platform targeting **1 million+ active users** with peak concurrency scenarios of **100K-500K simultaneous users**. We analyze every system component, identify bottlenecks, and prescribe battle-tested solutions used by platforms like Instagram, Uber, and Shopify.

**Target Metrics:**
- 1M+ registered users
- 100K-500K peak concurrent users
- 10K+ concurrent searches
- 50K+ orders/hour during flash sales
- 1M+ push notifications/minute during viral moments
- 99.9% uptime SLA

---

## Table of Contents

1. [Concurrency Scenarios & Load Profiles](#1-concurrency-scenarios--load-profiles)
2. [Firestore Scaling Strategy](#2-firestore-scaling-strategy)
3. [Cloud Functions Architecture](#3-cloud-functions-architecture)
4. [Real-time Feed System](#4-real-time-feed-system)
5. [Search Infrastructure](#5-search-infrastructure)
6. [Payment Processing at Scale](#6-payment-processing-at-scale)
7. [Notification System](#7-notification-system)
8. [Caching Architecture](#8-caching-architecture)
9. [Queue & Async Processing](#9-queue--async-processing)
10. [CDN & Media Delivery](#10-cdn--media-delivery)
11. [Database Sharding Strategy](#11-database-sharding-strategy)
12. [Rate Limiting & Abuse Prevention](#12-rate-limiting--abuse-prevention)
13. [Monitoring & Auto-Scaling](#13-monitoring--auto-scaling)
14. [Disaster Recovery](#14-disaster-recovery)
15. [Cost Optimization](#15-cost-optimization)
16. [Implementation Roadmap](#16-implementation-roadmap)

---

## 1. Concurrency Scenarios & Load Profiles

### 1.1 User Growth Projections

| Phase | Users | DAU | Peak Concurrent | Timeline |
|-------|-------|-----|-----------------|----------|
| Launch | 10K | 3K | 500 | Month 1-3 |
| Growth | 100K | 30K | 5K | Month 4-6 |
| Scale | 500K | 150K | 25K | Month 7-12 |
| Mature | 1M+ | 300K+ | 100K+ | Year 2+ |

### 1.2 Critical Concurrency Scenarios

#### Scenario A: Morning Rush (8-10 AM)
```
- 100K users open app simultaneously
- 80K load home feed
- 50K browse products
- 20K check order status
- 10K active in chat

Peak Load:
- 100K feed requests in 5 minutes = 333 req/sec
- 50K product queries = 167 req/sec
- Database reads: 500+ req/sec sustained
```

#### Scenario B: Flash Sale Event
```
- Vendor announces 70% off sale
- 50K users rush to single vendor page
- 30K add to cart within 60 seconds
- 20K attempt checkout simultaneously

Peak Load:
- Single product document: 50K reads/min (HOT DOCUMENT)
- Cart writes: 500 writes/sec
- Inventory checks: 500 reads/sec on same documents
- Payment initiations: 300/sec
```

#### Scenario C: Viral Post/Story
```
- Popular vendor posts story
- 200K followers receive notification
- 100K view story within 10 minutes
- 50K like/engage with post

Peak Load:
- Push notifications: 200K in <60 seconds
- Story document reads: 170 reads/sec
- Like writes: 83 writes/sec on SAME document
- View counter: 170 increments/sec
```

#### Scenario D: Search Surge
```
- Marketing campaign drives traffic
- 100K users search "shoes" simultaneously
- Each search returns 20 products with filters

Peak Load:
- Search queries: 1,667 req/sec
- Firestore reads: 33K documents/sec
- Filter/sort operations: CPU intensive
```

#### Scenario E: End-of-Day Analytics
```
- 10K vendors check dashboards at 6 PM
- Each dashboard loads 5-10 aggregated queries
- Real-time order updates streaming

Peak Load:
- Aggregation queries: 50K-100K
- Real-time listeners: 10K concurrent
- BigQuery exports running
```

### 1.3 Load Distribution by Feature

| Feature | % of Total Load | Peak Req/Sec | Data Pattern |
|---------|-----------------|--------------|--------------|
| Home Feed | 35% | 500 | Read-heavy, personalized |
| Product Browse | 25% | 350 | Read-heavy, cacheable |
| Search | 15% | 200 | Read-heavy, complex queries |
| Cart/Checkout | 10% | 150 | Write-heavy, transactional |
| Chat | 8% | 120 | Real-time, bidirectional |
| Notifications | 5% | 75 | Write-heavy, bursty |
| Analytics | 2% | 30 | Aggregation-heavy |

---

## 2. Firestore Scaling Strategy

### 2.1 The 1 Write/Second Problem

Firestore has a hard limit: **1 write per second per document**. This becomes critical for:

| Document | Problem Scenario | Writes/Sec Needed |
|----------|------------------|-------------------|
| Product with viral post | 50K users viewing | 500+ reads/sec ✅ OK |
| Post likes counter | 10K likes in 1 min | 166 writes/sec ❌ FAIL |
| Vendor follower count | Viral vendor | 100+ writes/sec ❌ FAIL |
| Story view counter | Popular story | 200+ writes/sec ❌ FAIL |
| Inventory stock | Flash sale | 500 writes/sec ❌ FAIL |

### 2.2 Solution: Distributed (Sharded) Counters

Instead of one counter field, split across N shards:

```
Traditional (BREAKS):
/posts/{postId}
└── likes: 50000  ← All writes hit this one field

Sharded (SCALES):
/posts/{postId}
├── likes: 0  ← Not used directly
└── _shards/
    ├── 0: { count: 5000 }
    ├── 1: { count: 5000 }
    ├── 2: { count: 5000 }
    ...
    └── 9: { count: 5000 }
    
Total = sum of all shards = 50000
```

### 2.3 Sharded Counter Implementation

```typescript
// functions/src/utils/shardedCounter.ts
const NUM_SHARDS = 10; // Supports 10 writes/sec per counter

interface ShardedCounterConfig {
  collection: string;  // e.g., 'posts'
  docId: string;       // e.g., postId
  field: string;       // e.g., 'likes'
}

// Initialize shards (call once when document created)
export async function initializeCounter(config: ShardedCounterConfig) {
  const batch = db.batch();
  
  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = db.collection(config.collection)
      .doc(config.docId)
      .collection(`_shards_${config.field}`)
      .doc(i.toString());
    
    batch.set(shardRef, { count: 0 });
  }
  
  await batch.commit();
}

// Increment counter (randomly picks a shard)
export async function incrementCounter(config: ShardedCounterConfig, delta: number = 1) {
  const shardId = Math.floor(Math.random() * NUM_SHARDS).toString();
  const shardRef = db.collection(config.collection)
    .doc(config.docId)
    .collection(`_shards_${config.field}`)
    .doc(shardId);
  
  await shardRef.update({
    count: FieldValue.increment(delta)
  });
}

// Get total count (sum all shards)
export async function getCount(config: ShardedCounterConfig): Promise<number> {
  const shardsSnapshot = await db.collection(config.collection)
    .doc(config.docId)
    .collection(`_shards_${config.field}`)
    .get();
  
  let total = 0;
  shardsSnapshot.docs.forEach(doc => {
    total += doc.data().count || 0;
  });
  
  return total;
}

// Periodic aggregation (run every 5 min via scheduler)
export async function aggregateCounter(config: ShardedCounterConfig) {
  const total = await getCount(config);
  
  await db.collection(config.collection)
    .doc(config.docId)
    .update({ [config.field]: total });
}
```

### 2.4 Where to Apply Sharded Counters

| Collection | Field | Shards | Max Writes/Sec |
|------------|-------|--------|----------------|
| posts | likes | 20 | 20/sec |
| posts | views | 50 | 50/sec |
| posts | shares | 10 | 10/sec |
| stories | viewCount | 50 | 50/sec |
| vendors | followerCount | 20 | 20/sec |
| products | stock | 30 | 30/sec (flash sales) |

### 2.5 Hot Document Mitigation

Beyond counters, some documents get hammered with reads:

**Problem:** Viral product page = 50K reads/sec on same document

**Solutions:**

1. **Caching Layer** (see Section 8)
```typescript
// Check cache first
const cached = await redis.get(`product:${productId}`);
if (cached) return JSON.parse(cached);

// Cache miss - read from Firestore
const product = await db.collection('products').doc(productId).get();
await redis.setex(`product:${productId}`, 300, JSON.stringify(product.data())); // 5 min TTL
```

2. **CDN for Static Data**
- Product images → Cloud CDN
- Vendor logos → Cloud CDN
- Category icons → Cloud CDN

3. **Denormalization**
- Embed frequently-read data in parent documents
- Reduces joins/lookups

```typescript
// Instead of:
const order = await db.collection('orders').doc(orderId).get();
const vendor = await db.collection('vendors').doc(order.vendorId).get(); // Extra read

// Denormalize:
/orders/{orderId}
├── vendorId: string
├── vendorName: string      ← Embedded
├── vendorLogo: string      ← Embedded
└── ...
```

### 2.6 Query Optimization

**Avoid:**
```typescript
// BAD: Full collection scan
const allProducts = await db.collection('products').get();

// BAD: No index, slow
const products = await db.collection('products')
  .where('category', '==', 'shoes')
  .where('price', '<=', 5000)
  .where('rating', '>=', 4)
  .get();
```

**Do:**
```typescript
// GOOD: Paginated with cursor
const products = await db.collection('products')
  .where('category', '==', 'shoes')
  .where('isActive', '==', true)
  .orderBy('createdAt', 'desc')
  .startAfter(lastDoc)
  .limit(20)
  .get();

// GOOD: Composite index defined
// firestore.indexes.json covers this query
```

### 2.7 Firestore Indexes Strategy

```json
// firestore.indexes.json
{
  "indexes": [
    // Products by category + active + date
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "categoryId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    // Products by vendor + active
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    // Orders by vendor + status + date
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    // Posts feed (active + not expired + date)
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "expiresAt", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    // Posts by vendor for analytics
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 3. Cloud Functions Architecture

### 3.1 Cold Start Problem

Cloud Functions spin down after ~15 min of inactivity. Cold starts add 1-10 seconds latency.

**Impact at Scale:**
- 100K users hit app at 8 AM
- Functions are cold
- First 1000 requests timeout or slow
- Users see errors/loading

### 3.2 Solution: Minimum Instances

```typescript
// functions/src/index.ts
import { onCall, HttpsOptions } from 'firebase-functions/v2/https';

const criticalFunctionConfig: HttpsOptions = {
  minInstances: 5,        // Always keep 5 warm
  maxInstances: 1000,     // Scale up to 1000
  concurrency: 80,        // 80 concurrent requests per instance
  memory: '512MiB',
  timeoutSeconds: 60,
  region: 'africa-south1' // Closest to Kenya
};

// Critical path functions - always warm
export const getPersonalizedFeed = onCall(criticalFunctionConfig, async (request) => {
  // Feed logic
});

export const createOrder = onCall(criticalFunctionConfig, async (request) => {
  // Order logic
});

export const initiatePayment = onCall(criticalFunctionConfig, async (request) => {
  // Payment logic
});

// Non-critical - can cold start
const backgroundConfig: HttpsOptions = {
  minInstances: 0,
  maxInstances: 100,
  memory: '256MiB'
};

export const generateAnalytics = onCall(backgroundConfig, async (request) => {
  // Analytics logic
});
```

### 3.3 Function Categorization

| Category | Min Instances | Max Instances | Examples |
|----------|---------------|---------------|----------|
| Critical Path | 5-10 | 1000 | Feed, Cart, Checkout, Payment |
| User-Facing | 2-5 | 500 | Search, Product details, Chat |
| Background | 0 | 100 | Analytics, Cleanup, Reports |
| Webhooks | 3 | 200 | Pesapal IPN, Uber webhooks |

### 3.4 Concurrency Settings

```typescript
// Gen 2 functions support concurrency (multiple requests per instance)
const highConcurrencyConfig: HttpsOptions = {
  concurrency: 80,  // Handle 80 requests per instance
  cpu: 1,           // 1 vCPU
  memory: '512MiB'
};

// CPU-intensive functions need lower concurrency
const cpuIntensiveConfig: HttpsOptions = {
  concurrency: 10,  // Lower due to CPU work
  cpu: 2,           // 2 vCPUs
  memory: '1GiB'
};
```

### 3.5 Regional Deployment

Deploy functions close to users:

```typescript
// For African market
const regionalConfig: HttpsOptions = {
  region: 'africa-south1',  // Johannesburg - closest to Kenya
  // Fallback regions for redundancy
};

// Multi-region for global (future)
// region: ['africa-south1', 'europe-west1', 'us-central1']
```

### 3.6 Error Handling & Retries

```typescript
// functions/src/utils/resilience.ts
import { HttpsError } from 'firebase-functions/v2/https';

// Retry wrapper for external APIs
export async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  backoffMs: number = 1000
): Promise<T> {
  let lastError: Error;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      
      // Don't retry client errors
      if (error instanceof HttpsError && error.code === 'invalid-argument') {
        throw error;
      }
      
      // Exponential backoff
      if (attempt < maxRetries) {
        await sleep(backoffMs * Math.pow(2, attempt - 1));
      }
    }
  }
  
  throw lastError!;
}

// Circuit breaker for external services
class CircuitBreaker {
  private failures = 0;
  private lastFailure: Date | null = null;
  private readonly threshold = 5;
  private readonly resetTimeout = 30000; // 30 seconds
  
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.isOpen()) {
      throw new HttpsError('unavailable', 'Service temporarily unavailable');
    }
    
    try {
      const result = await fn();
      this.reset();
      return result;
    } catch (error) {
      this.recordFailure();
      throw error;
    }
  }
  
  private isOpen(): boolean {
    if (this.failures >= this.threshold) {
      const timeSinceLastFailure = Date.now() - (this.lastFailure?.getTime() || 0);
      return timeSinceLastFailure < this.resetTimeout;
    }
    return false;
  }
  
  private recordFailure() {
    this.failures++;
    this.lastFailure = new Date();
  }
  
  private reset() {
    this.failures = 0;
    this.lastFailure = null;
  }
}

// Usage
const pesapalCircuit = new CircuitBreaker();
const uberCircuit = new CircuitBreaker();

export async function callPesapal(fn: () => Promise<any>) {
  return pesapalCircuit.execute(() => withRetry(fn));
}
```

### 3.7 Function Size & Dependencies

```typescript
// BAD: One giant index.ts with all functions
// - Slow cold starts (loads everything)
// - Memory bloat

// GOOD: Split by domain
// functions/
// ├── src/
// │   ├── auth/
// │   │   ├── index.ts
// │   │   └── triggers.ts
// │   ├── orders/
// │   │   ├── index.ts
// │   │   └── triggers.ts
// │   ├── payments/
// │   │   └── index.ts
// │   ├── feed/
// │   │   └── index.ts
// │   └── index.ts  ← Re-exports only

// Lazy load heavy dependencies
export const processImage = onObjectFinalized(async (event) => {
  // Only load sharp when needed
  const sharp = await import('sharp');
  // Process image
});
```

---

## 4. Real-time Feed System

### 4.1 The Feed Problem

Current architecture (Phase 8) uses **fan-in on read**:
- User opens app
- Query followed vendors' posts
- Query interest-based posts
- Query trending posts
- Merge, dedupe, return

**At 100K concurrent users:**
- 100K feed requests
- Each does 3-5 Firestore queries
- 300K-500K queries in seconds
- Firestore melts 🔥

### 4.2 Solution: Hybrid Fan-Out/Fan-In

**Fan-out on write** (for followed vendors):
- Vendor posts → write to each follower's feed
- Expensive writes, cheap reads

**Fan-in on read** (for discovery):
- Trending/interest posts queried at read time
- Cached aggressively

### 4.3 Pre-computed Feed Architecture

```
Vendor creates post
        ↓
Cloud Function triggered
        ↓
Get vendor's followers (paginated)
        ↓
Write post reference to each follower's feed
        ↓
User opens app → reads their pre-computed feed
```

### 4.4 Feed Collection Structure

```
/feeds/{userId}/posts/{postId}
├── postId: string
├── vendorId: string
├── createdAt: timestamp
├── expiresAt: timestamp
├── score: number (for ranking)
└── source: 'following' | 'interests' | 'trending'
```

### 4.5 Fan-Out Implementation

```typescript
// functions/src/feed/fanOutPost.ts
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();
const BATCH_SIZE = 500;

export const fanOutNewPost = onDocumentCreated(
  'posts/{postId}',
  async (event) => {
    const post = event.data?.data();
    if (!post || !post.isActive) return;
    
    const postId = event.params.postId;
    const vendorId = post.vendorId;
    
    // Get all followers (paginated)
    let lastDoc = null;
    let hasMore = true;
    
    while (hasMore) {
      let query = db.collection('followers')
        .where('vendorId', '==', vendorId)
        .orderBy('followedAt')
        .limit(BATCH_SIZE);
      
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }
      
      const followers = await query.get();
      
      if (followers.empty) {
        hasMore = false;
        continue;
      }
      
      // Batch write to follower feeds
      const batch = db.batch();
      
      for (const follower of followers.docs) {
        const feedRef = db.collection('feeds')
          .doc(follower.data().buyerId)
          .collection('posts')
          .doc(postId);
        
        batch.set(feedRef, {
          postId,
          vendorId,
          createdAt: post.createdAt,
          expiresAt: post.expiresAt,
          score: calculateScore(post),
          source: 'following'
        });
      }
      
      await batch.commit();
      
      lastDoc = followers.docs[followers.docs.length - 1];
      hasMore = followers.docs.length === BATCH_SIZE;
    }
  }
);

function calculateScore(post: any): number {
  // Higher score = higher in feed
  // Factors: recency, engagement, premium status
  let score = Date.now();
  
  if (post.isPremium) score += 1000000; // Boost premium
  score += (post.likes || 0) * 100;
  score += (post.comments || 0) * 200;
  
  return score;
}
```

### 4.6 Optimized Feed Read

```typescript
// functions/src/feed/getFeed.ts
export const getPersonalizedFeed = onCall(
  { minInstances: 5, region: 'africa-south1' },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) throw new HttpsError('unauthenticated', 'Login required');
    
    const { cursor, limit = 20 } = request.data;
    const now = Timestamp.now();
    
    // 1. Get pre-computed feed (following) - FAST
    let feedQuery = db.collection('feeds')
      .doc(userId)
      .collection('posts')
      .where('expiresAt', '>', now)
      .orderBy('expiresAt')
      .orderBy('score', 'desc')
      .limit(limit);
    
    if (cursor) {
      feedQuery = feedQuery.startAfter(cursor);
    }
    
    const feedDocs = await feedQuery.get();
    const postIds = feedDocs.docs.map(d => d.data().postId);
    
    // 2. Fetch actual post data (batch)
    const posts = await fetchPostsByIds(postIds);
    
    // 3. If not enough, backfill with trending (cached)
    if (posts.length < limit) {
      const trending = await getCachedTrending(limit - posts.length);
      posts.push(...trending);
    }
    
    // 4. Return with next cursor
    const lastDoc = feedDocs.docs[feedDocs.docs.length - 1];
    
    return {
      posts,
      nextCursor: lastDoc?.id || null,
      hasMore: feedDocs.docs.length === limit
    };
  }
);

async function fetchPostsByIds(postIds: string[]): Promise<any[]> {
  if (postIds.length === 0) return [];
  
  // Batch get (max 10 per batch in Firestore)
  const batches = chunk(postIds, 10);
  const results: any[] = [];
  
  for (const batch of batches) {
    const refs = batch.map(id => db.collection('posts').doc(id));
    const docs = await db.getAll(...refs);
    
    docs.forEach(doc => {
      if (doc.exists) {
        results.push({ id: doc.id, ...doc.data() });
      }
    });
  }
  
  return results;
}
```

### 4.7 Feed Cleanup (Expired Posts)

```typescript
// functions/src/feed/cleanupFeeds.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';

export const cleanupExpiredFeedItems = onSchedule(
  { schedule: 'every 1 hours', region: 'africa-south1' },
  async () => {
    const now = Timestamp.now();
    const batchSize = 500;
    
    // Query expired feed items across all users
    const expiredItems = await db.collectionGroup('posts')
      .where('expiresAt', '<', now)
      .limit(batchSize)
      .get();
    
    if (expiredItems.empty) return;
    
    const batch = db.batch();
    expiredItems.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    
    console.log(`Deleted ${expiredItems.size} expired feed items`);
  }
);
```

### 4.8 Stories Feed (Simpler)

Stories are short-lived (24h), so fan-out is less critical:

```typescript
// Stories: Fan-in on read with aggressive caching
export const getStoriesFeed = onCall(async (request) => {
  const userId = request.auth?.uid;
  
  // Check cache first
  const cacheKey = `stories:${userId}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);
  
  // Get followed vendors
  const follows = await db.collection('followers')
    .where('buyerId', '==', userId)
    .select('vendorId')
    .get();
  
  const vendorIds = follows.docs.map(d => d.data().vendorId);
  
  if (vendorIds.length === 0) return { storyGroups: [] };
  
  // Query stories (limited vendors per query)
  const stories = await db.collection('stories')
    .where('vendorId', 'in', vendorIds.slice(0, 10))
    .where('expiresAt', '>', Timestamp.now())
    .orderBy('expiresAt')
    .orderBy('createdAt', 'desc')
    .get();
  
  // Group by vendor
  const grouped = groupStoriesByVendor(stories.docs);
  
  // Cache for 2 minutes
  await redis.setex(cacheKey, 120, JSON.stringify({ storyGroups: grouped }));
  
  return { storyGroups: grouped };
});
```

---

## 5. Search Infrastructure

### 5.1 The Search Problem

Firestore is NOT a search engine:
- No full-text search
- No fuzzy matching
- No relevance scoring
- Limited compound queries

**At 100K concurrent searches:**
- Complex queries timeout
- No typo tolerance ("shooes" → "shoes")
- Poor relevance ranking

### 5.2 Solution: Dedicated Search Service

| Option | Pros | Cons | Cost |
|--------|------|------|------|
| **Algolia** | Best UX, instant, typo-tolerant | Expensive at scale | $1+ per 1K searches |
| **Typesense** | Open source, self-host option | Less features | Free (self-host) or $0.50/1K |
| **Meilisearch** | Fast, easy setup | Newer, less mature | Free (self-host) |
| **Elasticsearch** | Most powerful | Complex, expensive | $$$$ |

**Recommendation:** Start with **Algolia** (best DX), migrate to **Typesense** at scale for cost savings.

### 5.3 Algolia Integration

```typescript
// functions/src/search/algoliaSync.ts
import algoliasearch from 'algoliasearch';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

const algolia = algoliasearch(
  process.env.ALGOLIA_APP_ID!,
  process.env.ALGOLIA_ADMIN_KEY!
);

const productsIndex = algolia.initIndex('products');
const vendorsIndex = algolia.initIndex('vendors');

// Sync products to Algolia
export const syncProductToAlgolia = onDocumentWritten(
  'products/{productId}',
  async (event) => {
    const productId = event.params.productId;
    
    if (!event.data?.after.exists) {
      // Document deleted
      await productsIndex.deleteObject(productId);
      return;
    }
    
    const product = event.data.after.data();
    
    if (!product.isActive || !product.isPublished) {
      // Inactive - remove from search
      await productsIndex.deleteObject(productId);
      return;
    }
    
    // Index product
    await productsIndex.saveObject({
      objectID: productId,
      name: product.name,
      description: product.description,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      vendorId: product.vendorId,
      vendorName: product.vendorName,
      price: product.price,
      currency: product.currency,
      rating: product.rating,
      reviewCount: product.reviewCount,
      imageUrl: product.images?.[0]?.url,
      tags: product.tags,
      inStock: product.stock > 0,
      createdAt: product.createdAt?.toMillis(),
      _geoloc: product.location ? {
        lat: product.location.latitude,
        lng: product.location.longitude
      } : undefined
    });
  }
);

// Sync vendors to Algolia
export const syncVendorToAlgolia = onDocumentWritten(
  'vendors/{vendorId}',
  async (event) => {
    const vendorId = event.params.vendorId;
    
    if (!event.data?.after.exists) {
      await vendorsIndex.deleteObject(vendorId);
      return;
    }
    
    const vendor = event.data.after.data();
    
    if (!vendor.isActive) {
      await vendorsIndex.deleteObject(vendorId);
      return;
    }
    
    await vendorsIndex.saveObject({
      objectID: vendorId,
      storeName: vendor.storeName,
      storeDescription: vendor.storeDescription,
      categoryIds: vendor.categoryIds,
      rating: vendor.rating,
      reviewCount: vendor.reviewCount,
      followerCount: vendor.followerCount,
      productCount: vendor.productCount,
      logoUrl: vendor.logoUrl,
      isVerified: vendor.verification?.status === 'verified',
      badgeType: vendor.verification?.badgeType,
      _geoloc: vendor.location ? {
        lat: vendor.location.latitude,
        lng: vendor.location.longitude
      } : undefined
    });
  }
);
```

### 5.4 Search API

```typescript
// functions/src/search/searchProducts.ts
export const searchProducts = onCall(
  { minInstances: 3, region: 'africa-south1' },
  async (request) => {
    const { 
      query, 
      categoryId, 
      minPrice, 
      maxPrice, 
      sortBy = 'relevance',
      page = 0,
      hitsPerPage = 20,
      location  // { lat, lng, radius }
    } = request.data;
    
    // Build Algolia filters
    const filters: string[] = ['inStock:true'];
    
    if (categoryId) {
      filters.push(`categoryId:${categoryId}`);
    }
    if (minPrice !== undefined) {
      filters.push(`price >= ${minPrice}`);
    }
    if (maxPrice !== undefined) {
      filters.push(`price <= ${maxPrice}`);
    }
    
    // Build search options
    const searchOptions: any = {
      filters: filters.join(' AND '),
      page,
      hitsPerPage,
      attributesToRetrieve: [
        'objectID', 'name', 'price', 'imageUrl', 
        'vendorName', 'rating', 'reviewCount'
      ]
    };
    
    // Geo search if location provided
    if (location) {
      searchOptions.aroundLatLng = `${location.lat}, ${location.lng}`;
      searchOptions.aroundRadius = location.radius || 10000; // 10km default
    }
    
    // Sorting
    const indexName = sortBy === 'price_asc' ? 'products_price_asc'
      : sortBy === 'price_desc' ? 'products_price_desc'
      : sortBy === 'rating' ? 'products_rating_desc'
      : 'products'; // Default relevance
    
    const index = algolia.initIndex(indexName);
    const results = await index.search(query || '', searchOptions);
    
    return {
      hits: results.hits,
      totalHits: results.nbHits,
      page: results.page,
      totalPages: results.nbPages,
      processingTimeMs: results.processingTimeMS
    };
  }
);
```

### 5.5 Algolia Index Configuration

```javascript
// Configure in Algolia Dashboard or via API
{
  "searchableAttributes": [
    "name",
    "description",
    "tags",
    "categoryName",
    "vendorName"
  ],
  "attributesForFaceting": [
    "categoryId",
    "vendorId",
    "price",
    "rating",
    "inStock",
    "filterOnly(categoryName)"
  ],
  "customRanking": [
    "desc(rating)",
    "desc(reviewCount)",
    "desc(createdAt)"
  ],
  "replicas": [
    "products_price_asc",
    "products_price_desc",
    "products_rating_desc"
  ]
}
```

### 5.6 Search Caching

```typescript
// Cache popular searches
const POPULAR_SEARCH_TTL = 300; // 5 minutes

export const searchWithCache = async (query: string, options: any) => {
  const cacheKey = `search:${hashQuery(query, options)}`;
  
  // Check cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    return { ...JSON.parse(cached), fromCache: true };
  }
  
  // Execute search
  const results = await algolia.initIndex('products').search(query, options);
  
  // Cache if popular query (high volume)
  if (isPopularQuery(query)) {
    await redis.setex(cacheKey, POPULAR_SEARCH_TTL, JSON.stringify(results));
  }
  
  return results;
};
```

### 5.7 Autocomplete / Suggestions

```typescript
// functions/src/search/autocomplete.ts
export const getSearchSuggestions = onCall(async (request) => {
  const { query } = request.data;
  
  if (!query || query.length < 2) {
    return { suggestions: [] };
  }
  
  // Query Algolia with minimal attributes
  const results = await productsIndex.search(query, {
    hitsPerPage: 5,
    attributesToRetrieve: ['name', 'categoryName'],
    attributesToHighlight: ['name']
  });
  
  // Also get vendor suggestions
  const vendorResults = await vendorsIndex.search(query, {
    hitsPerPage: 3,
    attributesToRetrieve: ['storeName', 'logoUrl']
  });
  
  return {
    products: results.hits.map(h => ({
      name: h.name,
      category: h.categoryName,
      highlighted: h._highlightResult?.name?.value
    })),
    vendors: vendorResults.hits.map(h => ({
      name: h.storeName,
      logo: h.logoUrl
    }))
  };
});
```

---

## 6. Payment Processing at Scale

### 6.1 Flash Sale Scenario

```
Vendor announces 70% off sale at 12:00 PM
├── 50,000 users add to cart in 60 seconds
├── 30,000 attempt checkout
├── 20,000 initiate payment simultaneously
└── Inventory: 500 units available

Problems:
1. Overselling (500 items, 20K buyers)
2. Payment gateway rate limits
3. Pesapal IPN webhook flood
4. Database write contention
```

### 6.2 Inventory Reservation System

**Problem:** Without reservation, 20K users can "buy" 500 items.

**Solution:** Reserve inventory at cart/checkout, release if payment fails.

```typescript
// functions/src/inventory/reserveStock.ts
const RESERVATION_TTL = 15 * 60 * 1000; // 15 minutes

interface Reservation {
  id: string;
  productId: string;
  variantId?: string;
  quantity: number;
  userId: string;
  expiresAt: Date;
}

export const reserveInventory = onCall(async (request) => {
  const { productId, variantId, quantity } = request.data;
  const userId = request.auth?.uid;
  
  const productRef = db.collection('products').doc(productId);
  const reservationRef = db.collection('reservations').doc();
  
  try {
    await db.runTransaction(async (transaction) => {
      const product = await transaction.get(productRef);
      const productData = product.data()!;
      
      // Get current stock
      const currentStock = variantId
        ? productData.variants.find((v: any) => v.id === variantId)?.stock
        : productData.stock;
      
      // Get active reservations for this product
      const activeReservations = await db.collection('reservations')
        .where('productId', '==', productId)
        .where('variantId', '==', variantId || null)
        .where('expiresAt', '>', new Date())
        .get();
      
      const reservedQuantity = activeReservations.docs
        .reduce((sum, doc) => sum + doc.data().quantity, 0);
      
      const availableStock = currentStock - reservedQuantity;
      
      if (quantity > availableStock) {
        throw new HttpsError('resource-exhausted', 
          `Only ${availableStock} items available`);
      }
      
      // Create reservation
      transaction.set(reservationRef, {
        id: reservationRef.id,
        productId,
        variantId: variantId || null,
        quantity,
        userId,
        expiresAt: new Date(Date.now() + RESERVATION_TTL),
        createdAt: FieldValue.serverTimestamp()
      });
    });
    
    return { 
      reservationId: reservationRef.id,
      expiresAt: new Date(Date.now() + RESERVATION_TTL).toISOString()
    };
    
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', 'Failed to reserve inventory');
  }
});

// Release reservation (on payment failure or timeout)
export const releaseReservation = onCall(async (request) => {
  const { reservationId } = request.data;
  const userId = request.auth?.uid;
  
  const reservationRef = db.collection('reservations').doc(reservationId);
  const reservation = await reservationRef.get();
  
  if (!reservation.exists) return { success: true };
  if (reservation.data()!.userId !== userId) {
    throw new HttpsError('permission-denied', 'Not your reservation');
  }
  
  await reservationRef.delete();
  return { success: true };
});

// Cleanup expired reservations (scheduled)
export const cleanupExpiredReservations = onSchedule(
  { schedule: 'every 5 minutes' },
  async () => {
    const expired = await db.collection('reservations')
      .where('expiresAt', '<', new Date())
      .limit(500)
      .get();
    
    const batch = db.batch();
    expired.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    
    console.log(`Released ${expired.size} expired reservations`);
  }
);
```

### 6.3 Payment Idempotency

**Problem:** Network issues cause duplicate payment attempts.

**Solution:** Idempotency keys prevent double-charging.

```typescript
// functions/src/payments/initiatePayment.ts
export const initiatePayment = onCall(async (request) => {
  const { orderId, idempotencyKey } = request.data;
  const userId = request.auth?.uid;
  
  // Check for existing payment with same idempotency key
  const existingPayment = await db.collection('payments')
    .where('idempotencyKey', '==', idempotencyKey)
    .where('orderId', '==', orderId)
    .limit(1)
    .get();
  
  if (!existingPayment.empty) {
    const payment = existingPayment.docs[0].data();
    
    // Return existing payment if still valid
    if (payment.status === 'pending' || payment.status === 'completed') {
      return {
        paymentId: payment.id,
        redirectUrl: payment.redirectUrl,
        status: payment.status,
        duplicate: true
      };
    }
  }
  
  // Create new payment
  const order = await db.collection('orders').doc(orderId).get();
  const orderData = order.data()!;
  
  // Call Pesapal
  const pesapalResponse = await callPesapal(() => 
    submitOrderToPesapal(orderId, orderData)
  );
  
  // Store payment record
  const paymentRef = db.collection('payments').doc();
  await paymentRef.set({
    id: paymentRef.id,
    orderId,
    userId,
    idempotencyKey,
    amount: orderData.total,
    currency: orderData.currency,
    status: 'pending',
    pesapalOrderId: pesapalResponse.order_tracking_id,
    redirectUrl: pesapalResponse.redirect_url,
    createdAt: FieldValue.serverTimestamp()
  });
  
  return {
    paymentId: paymentRef.id,
    redirectUrl: pesapalResponse.redirect_url,
    status: 'pending'
  };
});
```

### 6.4 Webhook Processing at Scale

**Problem:** 20K payments = 20K IPN webhooks hitting your endpoint.

**Solution:** Queue-based webhook processing.

```typescript
// functions/src/payments/pesapalWebhook.ts
import { onRequest } from 'firebase-functions/v2/https';
import { PubSub } from '@google-cloud/pubsub';

const pubsub = new PubSub();
const TOPIC_NAME = 'pesapal-ipn';

// Webhook receiver - just queues, doesn't process
export const pesapalIPN = onRequest(
  { maxInstances: 100 },
  async (req, res) => {
    const payload = req.body;
    
    // Validate webhook signature (if Pesapal provides one)
    // ...
    
    // Queue for processing
    await pubsub.topic(TOPIC_NAME).publishMessage({
      json: payload,
      attributes: {
        receivedAt: new Date().toISOString()
      }
    });
    
    // Respond immediately
    res.status(200).json({ status: 'queued' });
  }
);

// Actual processor (Pub/Sub triggered)
export const processPaymentWebhook = onMessagePublished(
  { topic: TOPIC_NAME, maxInstances: 50 },
  async (event) => {
    const payload = event.data.message.json;
    const { OrderTrackingId, OrderMerchantReference } = payload;
    
    // Get transaction status from Pesapal
    const status = await getTransactionStatus(OrderTrackingId);
    
    // Update order
    const orderId = OrderMerchantReference;
    const orderRef = db.collection('orders').doc(orderId);
    
    await db.runTransaction(async (transaction) => {
      const order = await transaction.get(orderRef);
      
      // Prevent duplicate processing
      if (order.data()?.paymentStatus === 'completed') {
        console.log(`Order ${orderId} already completed, skipping`);
        return;
      }
      
      const paymentStatus = status.status_code === 1 ? 'completed' : 'failed';
      
      transaction.update(orderRef, {
        paymentStatus,
        paymentMethod: status.payment_method,
        pesapalTransactionId: status.confirmation_code,
        updatedAt: FieldValue.serverTimestamp()
      });
      
      // If completed, decrement inventory
      if (paymentStatus === 'completed') {
        // Queue inventory update
        await pubsub.topic('inventory-updates').publishMessage({
          json: { orderId, action: 'decrement' }
        });
      }
    });
  }
);
```

### 6.5 Payment Rate Limiting

```typescript
// Limit payment attempts per user
const PAYMENT_RATE_LIMIT = {
  maxAttempts: 5,
  windowMs: 15 * 60 * 1000 // 15 minutes
};

async function checkPaymentRateLimit(userId: string): Promise<boolean> {
  const key = `payment_attempts:${userId}`;
  const attempts = await redis.incr(key);
  
  if (attempts === 1) {
    await redis.expire(key, PAYMENT_RATE_LIMIT.windowMs / 1000);
  }
  
  return attempts <= PAYMENT_RATE_LIMIT.maxAttempts;
}
```

---
