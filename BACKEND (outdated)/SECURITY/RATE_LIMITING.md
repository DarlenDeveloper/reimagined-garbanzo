# Rate Limiting Strategy

## Overview

Rate limiting prevents abuse, brute force attacks, and protects against runaway costs. Implemented at multiple layers.

---

## Rate Limits by Endpoint

### Authentication Endpoints

| Action | Limit | Window | Scope | Lockout |
|--------|-------|--------|-------|---------|
| Login attempts | 5 | 15 min | Per email | 30 min lockout after 5 fails |
| Login attempts | 10 | 1 min | Per IP | Temporary block |
| Signup | 3 | 1 hour | Per IP | Prevent mass account creation |
| Password reset | 3 | 1 hour | Per email | Prevent email spam |
| OTP requests | 5 | 1 hour | Per phone | Prevent SMS abuse |
| Email verification | 5 | 1 hour | Per email | Prevent email spam |

### API Endpoints (Cloud Functions)

| Action | Limit | Window | Scope |
|--------|-------|--------|-------|
| Read operations | 100 | 1 min | Per user |
| Write operations | 30 | 1 min | Per user |
| File uploads | 10 | 1 min | Per user |
| Search queries | 30 | 1 min | Per user |
| Bulk operations | 5 | 1 min | Per user |
| Invitation sends | 10 | 1 hour | Per vendor |
| Order creation | 50 | 1 min | Per vendor |
| Message sends | 60 | 1 min | Per user |

### Payment Endpoints

| Action | Limit | Window | Scope |
|--------|-------|--------|-------|
| Payment initiation | 10 | 1 min | Per user |
| Refund requests | 5 | 1 hour | Per vendor |
| Payout requests | 3 | 1 day | Per vendor |

---

## Implementation

### 1. Firebase App Check (First Line of Defense)

Blocks requests from non-genuine apps.

```typescript
// functions/src/index.ts
import { setGlobalOptions } from 'firebase-functions/v2';

setGlobalOptions({
  enforceAppCheck: true, // Reject requests without valid App Check token
});
```

```dart
// Flutter app initialization
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

### 2. Cloud Functions Rate Limiting

```typescript
// functions/src/middleware/rateLimiter.ts
import * as admin from 'firebase-admin';

interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
  keyPrefix: string;
}

export async function checkRateLimit(
  userId: string,
  config: RateLimitConfig
): Promise<{ allowed: boolean; remaining: number; resetAt: number }> {
  const db = admin.firestore();
  const key = `${config.keyPrefix}:${userId}`;
  const now = Date.now();
  const windowStart = now - config.windowMs;
  
  const rateLimitRef = db.collection('_rateLimits').doc(key);
  
  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(rateLimitRef);
    const data = doc.data();
    
    // Clean old entries and count recent requests
    let requests: number[] = data?.requests || [];
    requests = requests.filter(timestamp => timestamp > windowStart);
    
    if (requests.length >= config.maxRequests) {
      const resetAt = requests[0] + config.windowMs;
      return { allowed: false, remaining: 0, resetAt };
    }
    
    // Add new request
    requests.push(now);
    transaction.set(rateLimitRef, { 
      requests, 
      updatedAt: admin.firestore.FieldValue.serverTimestamp() 
    });
    
    return { 
      allowed: true, 
      remaining: config.maxRequests - requests.length,
      resetAt: now + config.windowMs 
    };
  });
}

// Usage in Cloud Function
export const createProduct = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  
  const rateLimit = await checkRateLimit(userId, {
    maxRequests: 30,
    windowMs: 60 * 1000, // 1 minute
    keyPrefix: 'write'
  });
  
  if (!rateLimit.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      `Rate limit exceeded. Try again in ${Math.ceil((rateLimit.resetAt - Date.now()) / 1000)} seconds`
    );
  }
  
  // Proceed with operation...
});
```

### 3. Login Rate Limiting with Lockout

```typescript
// functions/src/auth/loginRateLimit.ts
interface LoginAttempt {
  timestamp: number;
  success: boolean;
  ip: string;
}

export async function checkLoginRateLimit(
  email: string,
  ip: string
): Promise<{ allowed: boolean; lockedUntil?: number; reason?: string }> {
  const db = admin.firestore();
  const emailKey = `login:email:${email.toLowerCase()}`;
  const ipKey = `login:ip:${ip}`;
  
  // Check email-based limit (5 attempts per 15 min)
  const emailDoc = await db.collection('_rateLimits').doc(emailKey).get();
  const emailData = emailDoc.data();
  
  if (emailData?.lockedUntil && emailData.lockedUntil > Date.now()) {
    return { 
      allowed: false, 
      lockedUntil: emailData.lockedUntil,
      reason: 'Account temporarily locked due to too many failed attempts'
    };
  }
  
  const recentFailures = (emailData?.attempts || [])
    .filter((a: LoginAttempt) => !a.success && a.timestamp > Date.now() - 15 * 60 * 1000);
  
  if (recentFailures.length >= 5) {
    // Lock account for 30 minutes
    const lockedUntil = Date.now() + 30 * 60 * 1000;
    await db.collection('_rateLimits').doc(emailKey).update({ lockedUntil });
    
    // TODO: Send email notification about locked account
    
    return { allowed: false, lockedUntil, reason: 'Account locked for 30 minutes' };
  }
  
  // Check IP-based limit (10 attempts per minute)
  const ipDoc = await db.collection('_rateLimits').doc(ipKey).get();
  const ipAttempts = (ipDoc.data()?.attempts || [])
    .filter((a: LoginAttempt) => a.timestamp > Date.now() - 60 * 1000);
  
  if (ipAttempts.length >= 10) {
    return { allowed: false, reason: 'Too many requests from this IP' };
  }
  
  return { allowed: true };
}

export async function recordLoginAttempt(
  email: string,
  ip: string,
  success: boolean
): Promise<void> {
  const db = admin.firestore();
  const attempt: LoginAttempt = { timestamp: Date.now(), success, ip };
  
  // Record for email
  await db.collection('_rateLimits').doc(`login:email:${email.toLowerCase()}`).set({
    attempts: admin.firestore.FieldValue.arrayUnion(attempt),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
  
  // Record for IP
  await db.collection('_rateLimits').doc(`login:ip:${ip}`).set({
    attempts: admin.firestore.FieldValue.arrayUnion(attempt),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
  
  // Clear lock on successful login
  if (success) {
    await db.collection('_rateLimits').doc(`login:email:${email.toLowerCase()}`).update({
      lockedUntil: admin.firestore.FieldValue.delete()
    });
  }
}
```

### 4. Firestore Query Limits

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Limit query results to prevent data exfiltration
    match /vendors/{vendorId}/products/{productId} {
      allow list: if request.auth != null 
                  && request.query.limit <= 50; // Max 50 products per query
    }
    
    match /vendors/{vendorId}/orders/{orderId} {
      allow list: if request.auth != null 
                  && isMemberOf(vendorId)
                  && request.query.limit <= 100; // Max 100 orders per query
    }
  }
}
```

---

## Client-Side Handling

```dart
// lib/services/api_service.dart
class ApiService {
  Future<T> callWithRetry<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await apiCall();
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'resource-exhausted') {
          // Rate limited - show user-friendly message
          final retryAfter = e.details?['retryAfter'] ?? 60;
          
          if (attempts < maxRetries - 1) {
            await Future.delayed(Duration(seconds: retryAfter));
            attempts++;
            continue;
          }
          
          throw RateLimitException(
            'Too many requests. Please wait $retryAfter seconds.',
            retryAfter: retryAfter,
          );
        }
        rethrow;
      }
    }
    
    throw Exception('Max retries exceeded');
  }
}

class RateLimitException implements Exception {
  final String message;
  final int retryAfter;
  
  RateLimitException(this.message, {required this.retryAfter});
}
```

---

## Monitoring & Alerts

### Cloud Function to Clean Up Old Rate Limit Data

```typescript
// functions/src/scheduled/cleanupRateLimits.ts
export const cleanupRateLimits = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async () => {
    const db = admin.firestore();
    const cutoff = Date.now() - 24 * 60 * 60 * 1000; // 24 hours ago
    
    const oldDocs = await db.collection('_rateLimits')
      .where('updatedAt', '<', new Date(cutoff))
      .limit(500)
      .get();
    
    const batch = db.batch();
    oldDocs.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    
    console.log(`Cleaned up ${oldDocs.size} old rate limit records`);
  });
```

### Alert on Suspicious Activity

```typescript
// functions/src/triggers/securityAlerts.ts
export const onRateLimitExceeded = functions.firestore
  .document('_rateLimits/{docId}')
  .onUpdate(async (change, context) => {
    const data = change.after.data();
    
    // Alert if account locked
    if (data.lockedUntil && !change.before.data().lockedUntil) {
      await sendSecurityAlert({
        type: 'ACCOUNT_LOCKED',
        docId: context.params.docId,
        timestamp: Date.now(),
      });
    }
    
    // Alert if excessive failures from single IP
    const ipFailures = (data.attempts || [])
      .filter((a: any) => !a.success && a.timestamp > Date.now() - 60 * 60 * 1000);
    
    if (ipFailures.length >= 50) {
      await sendSecurityAlert({
        type: 'POSSIBLE_BRUTE_FORCE',
        docId: context.params.docId,
        failureCount: ipFailures.length,
        timestamp: Date.now(),
      });
    }
  });
```

---

## Rate Limit Response Codes

| HTTP Code | Meaning | Client Action |
|-----------|---------|---------------|
| 429 | Rate limit exceeded | Wait and retry |
| 403 | Account locked | Show lockout message |
| 503 | Service overloaded | Exponential backoff |
