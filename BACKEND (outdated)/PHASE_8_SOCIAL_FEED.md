# Phase 8: Store Social Feed & Stories

## Overview

This document covers the complete social feed system where vendors create posts and stories that appear on buyers' home feed. This is a core engagement feature similar to Instagram/Twitter for e-commerce.

---

## 1. Feature Summary

| Feature | Seller App | Buyer App |
|---------|------------|-----------|
| Create Posts | ✅ socials_screen.dart | - |
| Create Stories | ✅ socials_screen.dart | - |
| View Feed | - | ✅ home_screen.dart |
| View Stories | - | ✅ story_view_screen.dart |
| Like/Save Posts | - | ✅ home_screen.dart |
| Follow Stores | - | ✅ home_screen.dart |
| Share Posts | - | ✅ home_screen.dart |
| DM from Post | - | ✅ home_screen.dart |
| Post Analytics | ✅ socials_screen.dart | - |
| Scheduled Posts | ✅ socials_screen.dart | - |

---

## 2. Firestore Collections

### Posts Collection (Global)

```
/posts/{postId}
├── id: string
├── vendorId: string
├── vendorName: string
├── vendorLogo: string
├── isVendorVerified: boolean
├── vendorBadgeType: 'blue' | 'gold' | 'black' | null
├── content: string
├── imageUrl: string?
├── videoUrl: string?
├── type: 'promo' | 'announcement' | 'restock' | 'new_arrival' | 'general'
├── category: string? (for interest-based feed)
├── productIds: string[] (linked products)
├── promoCode: string?
├── discountPercent: number?
├── isPremium: boolean (7 days vs 24h expiry)
├── likes: number
├── comments: number
├── shares: number
├── views: number
├── saves: number
├── isActive: boolean
├── isScheduled: boolean
├── scheduledAt: timestamp?
├── createdAt: timestamp
├── expiresAt: timestamp (24h for regular, 7d for premium)
└── updatedAt: timestamp
```

### Post Interactions Collection

```
/posts/{postId}/likes/{oderId}
├── oderId: string
├── likedAt: timestamp

/posts/{postId}/saves/{oderId}
├── oderId: string
├── savedAt: timestamp

/posts/{postId}/comments/{commentId}
├── id: string
├── oderId: string
├── oderName: string
├── content: string
├── createdAt: timestamp
```

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
├── content: map
│   ├── title: string
│   ├── subtitle: string?
│   ├── emoji: string?
│   ├── discount: string?
│   └── gradientColors: string[] (hex colors)
├── productId: string? (linked product)
├── promoCode: string?
├── viewCount: number
├── replyCount: number
├── createdAt: timestamp
└── expiresAt: timestamp (24 hours from creation)
```

### Story Views Collection

```
/stories/{storyId}/views/{oderId}
├── oderId: string
├── viewedAt: timestamp
```

### Followers Collection

```
/followers/{id}
├── id: string (oderId_vendorId)
├── oderId: string
├── vendorId: string
├── followedAt: timestamp
├── notificationsEnabled: boolean
```

### User Saved Posts Collection

```
/users/{userId}/savedPosts/{postId}
├── postId: string
├── vendorId: string
├── savedAt: timestamp
```

---

## 3. Cloud Functions - Post Management

### Create Post

```typescript
// functions/src/social/createPost.ts
import * as functions from 'firebase-functions';
import { FieldValue } from 'firebase-admin/firestore';

export const createPost = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { vendorId, content, imageUrl, videoUrl, type, productIds, promoCode, discountPercent, isPremium, isScheduled, scheduledAt, category } = data;
  
  // Verify user has permission to post for this vendor
  await requirePermission(userId, vendorId, 'social:create');
  
  // Get vendor info
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const vendorData = vendor.data();
  
  // Check subscription for premium posts
  if (isPremium) {
    const subscription = await db.collection('vendors').doc(vendorId)
      .collection('subscription').doc('current').get();
    if (!subscription.exists || subscription.data()?.plan === 'starter') {
      throw new functions.https.HttpsError('permission-denied', 'Premium posts require Pro or Business plan');
    }
  }
  
  // Calculate expiry (24h regular, 7d premium)
  const now = new Date();
  const expiresAt = isPremium 
    ? new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
    : new Date(now.getTime() + 24 * 60 * 60 * 1000);
  
  const postRef = db.collection('posts').doc();
  
  const postData = {
    id: postRef.id,
    vendorId,
    vendorName: vendorData.storeName,
    vendorLogo: vendorData.logoUrl,
    isVendorVerified: vendorData.verification?.status === 'verified',
    vendorBadgeType: vendorData.verification?.badgeType || null,
    content,
    imageUrl: imageUrl || null,
    videoUrl: videoUrl || null,
    type: type || 'general',
    category: category || null,
    productIds: productIds || [],
    promoCode: promoCode || null,
    discountPercent: discountPercent || null,
    isPremium: isPremium || false,
    likes: 0,
    comments: 0,
    shares: 0,
    views: 0,
    saves: 0,
    isActive: !isScheduled,
    isScheduled: isScheduled || false,
    scheduledAt: isScheduled ? Timestamp.fromDate(new Date(scheduledAt)) : null,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(expiresAt),
    updatedAt: FieldValue.serverTimestamp()
  };
  
  await postRef.set(postData);
  
  // If not scheduled, notify followers
  if (!isScheduled) {
    await notifyFollowersOfNewPost(vendorId, postRef.id, vendorData.storeName, content);
  }
  
  return { postId: postRef.id, expiresAt: expiresAt.toISOString() };
});
```


### Publish Scheduled Posts

```typescript
// functions/src/social/publishScheduledPosts.ts
export const publishScheduledPosts = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const now = Timestamp.now();
    
    const scheduledPosts = await db.collection('posts')
      .where('isScheduled', '==', true)
      .where('isActive', '==', false)
      .where('scheduledAt', '<=', now)
      .get();
    
    const batch = db.batch();
    
    for (const doc of scheduledPosts.docs) {
      const post = doc.data();
      
      // Calculate new expiry from publish time
      const expiresAt = post.isPremium
        ? new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        : new Date(Date.now() + 24 * 60 * 60 * 1000);
      
      batch.update(doc.ref, {
        isActive: true,
        isScheduled: false,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromDate(expiresAt)
      });
      
      // Notify followers
      await notifyFollowersOfNewPost(post.vendorId, doc.id, post.vendorName, post.content);
    }
    
    await batch.commit();
  });
```

### Delete Expired Posts

```typescript
// functions/src/social/cleanupExpiredPosts.ts
export const cleanupExpiredPosts = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async () => {
    const now = Timestamp.now();
    
    const expiredPosts = await db.collection('posts')
      .where('expiresAt', '<', now)
      .where('isActive', '==', true)
      .get();
    
    const batch = db.batch();
    
    for (const doc of expiredPosts.docs) {
      batch.update(doc.ref, { isActive: false });
    }
    
    await batch.commit();
    
    console.log(`Deactivated ${expiredPosts.size} expired posts`);
  });
```

---

## 4. Cloud Functions - Stories

### Create Story

```typescript
// functions/src/social/createStory.ts
export const createStory = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { vendorId, type, mediaUrl, content, productId, promoCode } = data;
  
  await requirePermission(userId, vendorId, 'social:create');
  
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const vendorData = vendor.data();
  
  // Stories expire in 24 hours
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
  
  const storyRef = db.collection('stories').doc();
  
  await storyRef.set({
    id: storyRef.id,
    vendorId,
    vendorName: vendorData.storeName,
    vendorLogo: vendorData.logoUrl,
    type,
    mediaUrl: mediaUrl || null,
    thumbnailUrl: type === 'video' ? await generateThumbnail(mediaUrl) : mediaUrl,
    content: content || {},
    productId: productId || null,
    promoCode: promoCode || null,
    viewCount: 0,
    replyCount: 0,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(expiresAt)
  });
  
  return { storyId: storyRef.id };
});
```

### Record Story View

```typescript
// functions/src/social/recordStoryView.ts
export const recordStoryView = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { storyId } = data;
  
  const viewRef = db.collection('stories').doc(storyId)
    .collection('views').doc(userId);
  
  const existingView = await viewRef.get();
  
  if (!existingView.exists) {
    await viewRef.set({
      oderId: userId,
      viewedAt: FieldValue.serverTimestamp()
    });
    
    // Increment view count
    await db.collection('stories').doc(storyId).update({
      viewCount: FieldValue.increment(1)
    });
  }
  
  return { success: true };
});
```

### Cleanup Expired Stories

```typescript
// functions/src/social/cleanupExpiredStories.ts
export const cleanupExpiredStories = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async () => {
    const now = Timestamp.now();
    
    const expiredStories = await db.collection('stories')
      .where('expiresAt', '<', now)
      .get();
    
    const batch = db.batch();
    
    for (const doc of expiredStories.docs) {
      batch.delete(doc.ref);
    }
    
    await batch.commit();
    
    console.log(`Deleted ${expiredStories.size} expired stories`);
  });
```

---

## 5. Cloud Functions - Feed & Interactions

### Get Personalized Feed

```typescript
// functions/src/social/getPersonalizedFeed.ts
export const getPersonalizedFeed = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const { page = 1, limit = 20, lastPostId } = data;
  
  const now = Timestamp.now();
  let posts = [];
  
  // Get user's followed vendors
  const follows = await db.collection('followers')
    .where('oderId', '==', userId)
    .get();
  
  const followedVendorIds = follows.docs.map(d => d.data().vendorId);
  
  // Get user interests
  const userProfile = await db.collection('users').doc(userId).get();
  const interests = userProfile.data()?.interests || [];
  
  // Priority 1: Posts from followed vendors (50% of feed)
  if (followedVendorIds.length > 0) {
    // Firestore 'in' query limited to 10 items
    const vendorBatches = chunkArray(followedVendorIds, 10);
    
    for (const batch of vendorBatches) {
      let query = db.collection('posts')
        .where('vendorId', 'in', batch)
        .where('isActive', '==', true)
        .where('expiresAt', '>', now)
        .orderBy('expiresAt')
        .orderBy('createdAt', 'desc')
        .limit(Math.ceil(limit / 2));
      
      const followedPosts = await query.get();
      posts.push(...followedPosts.docs.map(d => ({ ...d.data(), source: 'following' })));
    }
  }
  
  // Priority 2: Posts matching interests (30% of feed)
  if (interests.length > 0 && posts.length < limit) {
    const interestBatches = chunkArray(interests, 10);
    
    for (const batch of interestBatches) {
      const interestPosts = await db.collection('posts')
        .where('category', 'in', batch)
        .where('isActive', '==', true)
        .where('expiresAt', '>', now)
        .orderBy('expiresAt')
        .orderBy('likes', 'desc')
        .limit(Math.ceil(limit * 0.3))
        .get();
      
      posts.push(...interestPosts.docs.map(d => ({ ...d.data(), source: 'interests' })));
    }
  }
  
  // Priority 3: Trending/Popular posts (fill remaining)
  if (posts.length < limit) {
    const trendingPosts = await db.collection('posts')
      .where('isActive', '==', true)
      .where('expiresAt', '>', now)
      .orderBy('expiresAt')
      .orderBy('likes', 'desc')
      .limit(limit - posts.length)
      .get();
    
    posts.push(...trendingPosts.docs.map(d => ({ ...d.data(), source: 'trending' })));
  }
  
  // Deduplicate by post ID
  const uniquePosts = [...new Map(posts.map(p => [p.id, p])).values()];
  
  // Shuffle to mix sources
  const shuffled = shuffleArray(uniquePosts).slice(0, limit);
  
  // Check if user has liked/saved each post
  const enrichedPosts = await Promise.all(shuffled.map(async (post) => {
    const [liked, saved] = await Promise.all([
      db.collection('posts').doc(post.id).collection('likes').doc(userId).get(),
      db.collection('posts').doc(post.id).collection('saves').doc(userId).get()
    ]);
    
    return {
      ...post,
      isLiked: liked.exists,
      isSaved: saved.exists
    };
  }));
  
  return { posts: enrichedPosts };
});
```


### Get Stories Feed

```typescript
// functions/src/social/getStoriesFeed.ts
export const getStoriesFeed = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const now = Timestamp.now();
  
  // Get followed vendors
  const follows = await db.collection('followers')
    .where('oderId', '==', userId)
    .get();
  
  const followedVendorIds = follows.docs.map(d => d.data().vendorId);
  
  // Get active stories from followed vendors
  const stories: any[] = [];
  
  if (followedVendorIds.length > 0) {
    const vendorBatches = chunkArray(followedVendorIds, 10);
    
    for (const batch of vendorBatches) {
      const vendorStories = await db.collection('stories')
        .where('vendorId', 'in', batch)
        .where('expiresAt', '>', now)
        .orderBy('expiresAt')
        .orderBy('createdAt', 'desc')
        .get();
      
      stories.push(...vendorStories.docs.map(d => d.data()));
    }
  }
  
  // Group stories by vendor
  const groupedStories = stories.reduce((acc, story) => {
    if (!acc[story.vendorId]) {
      acc[story.vendorId] = {
        vendorId: story.vendorId,
        vendorName: story.vendorName,
        vendorLogo: story.vendorLogo,
        stories: []
      };
    }
    acc[story.vendorId].stories.push(story);
    return acc;
  }, {});
  
  // Check which stories user has viewed
  const enrichedGroups = await Promise.all(
    Object.values(groupedStories).map(async (group: any) => {
      const enrichedStories = await Promise.all(
        group.stories.map(async (story: any) => {
          const viewed = await db.collection('stories').doc(story.id)
            .collection('views').doc(userId).get();
          return { ...story, isViewed: viewed.exists };
        })
      );
      
      return {
        ...group,
        stories: enrichedStories,
        hasUnviewed: enrichedStories.some(s => !s.isViewed)
      };
    })
  );
  
  // Sort: unviewed first, then by most recent
  enrichedGroups.sort((a: any, b: any) => {
    if (a.hasUnviewed && !b.hasUnviewed) return -1;
    if (!a.hasUnviewed && b.hasUnviewed) return 1;
    return 0;
  });
  
  return { storyGroups: enrichedGroups };
});
```

### Like Post

```typescript
// functions/src/social/likePost.ts
export const likePost = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { postId } = data;
  
  const likeRef = db.collection('posts').doc(postId)
    .collection('likes').doc(userId);
  
  const existingLike = await likeRef.get();
  
  if (existingLike.exists) {
    // Unlike
    await likeRef.delete();
    await db.collection('posts').doc(postId).update({
      likes: FieldValue.increment(-1)
    });
    return { liked: false };
  } else {
    // Like
    await likeRef.set({
      oderId: userId,
      likedAt: FieldValue.serverTimestamp()
    });
    await db.collection('posts').doc(postId).update({
      likes: FieldValue.increment(1)
    });
    return { liked: true };
  }
});
```

### Save Post

```typescript
// functions/src/social/savePost.ts
export const savePost = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { postId } = data;
  
  const post = await db.collection('posts').doc(postId).get();
  if (!post.exists) throw new functions.https.HttpsError('not-found', 'Post not found');
  
  const postData = post.data();
  
  const saveRef = db.collection('posts').doc(postId)
    .collection('saves').doc(userId);
  
  const userSaveRef = db.collection('users').doc(userId)
    .collection('savedPosts').doc(postId);
  
  const existingSave = await saveRef.get();
  
  if (existingSave.exists) {
    // Unsave
    await saveRef.delete();
    await userSaveRef.delete();
    await db.collection('posts').doc(postId).update({
      saves: FieldValue.increment(-1)
    });
    return { saved: false };
  } else {
    // Save
    await saveRef.set({
      oderId: userId,
      savedAt: FieldValue.serverTimestamp()
    });
    await userSaveRef.set({
      postId,
      vendorId: postData.vendorId,
      savedAt: FieldValue.serverTimestamp()
    });
    await db.collection('posts').doc(postId).update({
      saves: FieldValue.increment(1)
    });
    return { saved: true };
  }
});
```

### Follow/Unfollow Vendor

```typescript
// functions/src/social/toggleFollow.ts
export const toggleFollow = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { vendorId } = data;
  
  const followId = `${userId}_${vendorId}`;
  const followRef = db.collection('followers').doc(followId);
  
  const existingFollow = await followRef.get();
  
  if (existingFollow.exists) {
    // Unfollow
    await followRef.delete();
    await db.collection('vendors').doc(vendorId).update({
      followerCount: FieldValue.increment(-1)
    });
    return { following: false };
  } else {
    // Follow
    await followRef.set({
      id: followId,
      oderId: userId,
      vendorId,
      followedAt: FieldValue.serverTimestamp(),
      notificationsEnabled: true
    });
    await db.collection('vendors').doc(vendorId).update({
      followerCount: FieldValue.increment(1)
    });
    return { following: true };
  }
});
```

### Share Post (Track)

```typescript
// functions/src/social/sharePost.ts
export const sharePost = functions.https.onCall(async (data, context) => {
  const { postId } = data;
  
  await db.collection('posts').doc(postId).update({
    shares: FieldValue.increment(1)
  });
  
  return { success: true };
});
```

---

## 6. Post Analytics (Seller Side)

### Get Post Analytics

```typescript
// functions/src/social/getPostAnalytics.ts
export const getPostAnalytics = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const { vendorId, postId } = data;
  
  await requirePermission(userId, vendorId, 'analytics:read');
  
  const post = await db.collection('posts').doc(postId).get();
  
  if (!post.exists || post.data().vendorId !== vendorId) {
    throw new functions.https.HttpsError('not-found', 'Post not found');
  }
  
  const postData = post.data();
  
  // Calculate engagement rate
  const totalEngagements = postData.likes + postData.comments + postData.shares + postData.saves;
  const engagementRate = postData.views > 0 
    ? ((totalEngagements / postData.views) * 100).toFixed(2)
    : 0;
  
  return {
    views: postData.views,
    likes: postData.likes,
    comments: postData.comments,
    shares: postData.shares,
    saves: postData.saves,
    engagementRate,
    isPremium: postData.isPremium,
    expiresAt: postData.expiresAt,
    createdAt: postData.createdAt
  };
});
```

### Get Social Insights (Dashboard)

```typescript
// functions/src/social/getSocialInsights.ts
export const getSocialInsights = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const { vendorId, period = '7d' } = data;
  
  await requirePermission(userId, vendorId, 'analytics:read');
  
  const now = new Date();
  const startDate = new Date();
  
  switch (period) {
    case '7d': startDate.setDate(startDate.getDate() - 7); break;
    case '30d': startDate.setDate(startDate.getDate() - 30); break;
  }
  
  // Get posts in period
  const posts = await db.collection('posts')
    .where('vendorId', '==', vendorId)
    .where('createdAt', '>=', Timestamp.fromDate(startDate))
    .get();
  
  const postData = posts.docs.map(d => d.data());
  
  // Get follower count
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const followerCount = vendor.data()?.followerCount || 0;
  
  // Get new followers in period
  const newFollowers = await db.collection('followers')
    .where('vendorId', '==', vendorId)
    .where('followedAt', '>=', Timestamp.fromDate(startDate))
    .get();
  
  // Calculate totals
  const totalViews = postData.reduce((sum, p) => sum + (p.views || 0), 0);
  const totalLikes = postData.reduce((sum, p) => sum + (p.likes || 0), 0);
  const totalComments = postData.reduce((sum, p) => sum + (p.comments || 0), 0);
  const totalShares = postData.reduce((sum, p) => sum + (p.shares || 0), 0);
  
  const totalEngagements = totalLikes + totalComments + totalShares;
  const engagementRate = totalViews > 0 
    ? ((totalEngagements / totalViews) * 100).toFixed(2)
    : 0;
  
  return {
    followers: followerCount,
    newFollowers: newFollowers.size,
    totalPosts: postData.length,
    totalViews,
    totalLikes,
    totalComments,
    totalShares,
    engagementRate,
    reach: totalViews, // Simplified - could be unique viewers
    period
  };
});
```

---

## 7. Notifications

### Notify Followers of New Post

```typescript
// functions/src/social/notifyFollowers.ts
async function notifyFollowersOfNewPost(
  vendorId: string, 
  postId: string, 
  vendorName: string, 
  content: string
) {
  // Get followers with notifications enabled
  const followers = await db.collection('followers')
    .where('vendorId', '==', vendorId)
    .where('notificationsEnabled', '==', true)
    .get();
  
  if (followers.empty) return;
  
  // Get FCM tokens
  const oderIds = followers.docs.map(d => d.data().oderId);
  const tokens: string[] = [];
  
  for (const oderId of oderIds) {
    const user = await db.collection('users').doc(oderId).get();
    if (user.exists && user.data()?.fcmToken) {
      tokens.push(user.data().fcmToken);
    }
  }
  
  if (tokens.length === 0) return;
  
  // Send push notification
  const message = {
    notification: {
      title: `${vendorName} posted`,
      body: content.substring(0, 100) + (content.length > 100 ? '...' : '')
    },
    data: {
      type: 'new_post',
      postId,
      vendorId
    },
    tokens
  };
  
  await admin.messaging().sendEachForMulticast(message);
}
```

---

## 8. Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Posts - anyone can read active posts, only vendors can write
    match /posts/{postId} {
      allow read: if resource.data.isActive == true;
      allow create: if isVendorMember(request.resource.data.vendorId);
      allow update, delete: if isVendorMember(resource.data.vendorId);
      
      // Likes subcollection
      match /likes/{oderId} {
        allow read: if true;
        allow write: if request.auth.uid == oderId;
      }
      
      // Saves subcollection
      match /saves/{oderId} {
        allow read: if true;
        allow write: if request.auth.uid == oderId;
      }
      
      // Comments subcollection
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update, delete: if request.auth.uid == resource.data.oderId;
      }
    }
    
    // Stories - anyone can read, only vendors can write
    match /stories/{storyId} {
      allow read: if resource.data.expiresAt > request.time;
      allow create: if isVendorMember(request.resource.data.vendorId);
      allow update, delete: if isVendorMember(resource.data.vendorId);
      
      match /views/{oderId} {
        allow read: if request.auth.uid == oderId;
        allow write: if request.auth.uid == oderId;
      }
    }
    
    // Followers
    match /followers/{followId} {
      allow read: if true;
      allow create: if request.auth.uid == request.resource.data.oderId;
      allow delete: if request.auth.uid == resource.data.oderId;
    }
    
    // User saved posts
    match /users/{userId}/savedPosts/{postId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    function isVendorMember(vendorId) {
      return exists(/databases/$(database)/documents/vendors/$(vendorId)/members/$(request.auth.uid));
    }
  }
}
```

---

## 9. Implementation Checklist

### Seller App (socials_screen.dart)
- [ ] Create post with text, image, video
- [ ] Premium post toggle (7d vs 24h)
- [ ] Schedule posts for later
- [ ] Create stories (camera, gallery, text)
- [ ] View post analytics (views, likes, comments, shares)
- [ ] View social insights dashboard
- [ ] Edit/delete posts
- [ ] Boost post (future: paid promotion)

### Buyer App (home_screen.dart, story_view_screen.dart)
- [ ] Personalized feed based on follows + interests
- [ ] Like posts
- [ ] Save posts
- [ ] Share posts
- [ ] Follow/unfollow vendors from feed
- [ ] Copy promo codes
- [ ] View stories with progress bar
- [ ] Reply to stories
- [ ] DM vendor from post

### Backend
- [ ] Posts collection with expiry
- [ ] Stories collection with 24h expiry
- [ ] Followers collection
- [ ] Personalized feed algorithm
- [ ] Scheduled post publishing
- [ ] Expired content cleanup
- [ ] Push notifications to followers
- [ ] Post analytics tracking
- [ ] Social insights aggregation
