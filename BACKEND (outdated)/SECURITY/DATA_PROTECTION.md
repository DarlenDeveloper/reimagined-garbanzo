# Data Protection & Privacy

## Data Classification

| Classification | Examples | Storage | Access | Retention |
|----------------|----------|---------|--------|-----------|
| **Public** | Store name, product info | Firestore | Any authenticated user | Indefinite |
| **Internal** | Order details, analytics | Firestore | Vendor members only | 7 years |
| **Confidential** | Customer PII, messages | Firestore (encrypted) | Authorized roles only | As required |
| **Restricted** | Payment tokens, passwords | Never stored / Firebase Auth | System only | N/A |

---

## PII (Personally Identifiable Information)

### PII Fields in System

| Collection | PII Fields | Protection |
|------------|------------|------------|
| `/users` | email, phone, displayName | Field-level access control |
| `/buyers` | addresses, paymentMethods | Owner-only access |
| `/vendors/.../orders` | customer name, phone, address | Vendor members only |
| `/vendors/.../conversations` | message content | Participants only |

### PII Handling Rules

1. **Minimize collection** — only collect what's necessary
2. **Limit access** — strict Firestore rules
3. **Encrypt sensitive fields** — at-rest encryption (Firestore default)
4. **Mask in logs** — never log full PII
5. **Enable deletion** — support GDPR/data deletion requests

---

## Encryption

### Data at Rest

Firebase/GCP provides automatic encryption at rest using AES-256.

### Data in Transit

All Firebase connections use TLS 1.2+.

### Application-Level Encryption (Optional)

For extra-sensitive fields:

```typescript
// functions/src/utils/encryption.ts
import * as crypto from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY!; // 32 bytes
const ALGORITHM = 'aes-256-gcm';

export function encrypt(text: string): string {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, Buffer.from(ENCRYPTION_KEY, 'hex'), iv);
  
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag();
  
  // Format: iv:authTag:encrypted
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
}

export function decrypt(encryptedText: string): string {
  const [ivHex, authTagHex, encrypted] = encryptedText.split(':');
  
  const iv = Buffer.from(ivHex, 'hex');
  const authTag = Buffer.from(authTagHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, Buffer.from(ENCRYPTION_KEY, 'hex'), iv);
  
  decipher.setAuthTag(authTag);
  
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}

// Usage for sensitive fields
const encryptedSSN = encrypt(ssn);
await db.collection('sensitive').doc(userId).set({
  ssn: encryptedSSN, // Stored encrypted
});
```

---

## Data Masking

### In Logs

```typescript
// functions/src/utils/logging.ts

export function maskPII(data: Record<string, any>): Record<string, any> {
  const sensitiveFields = ['email', 'phone', 'password', 'ssn', 'cardNumber', 'address'];
  const masked = { ...data };
  
  for (const field of sensitiveFields) {
    if (masked[field]) {
      masked[field] = maskValue(field, masked[field]);
    }
  }
  
  return masked;
}

function maskValue(field: string, value: string): string {
  switch (field) {
    case 'email':
      const [local, domain] = value.split('@');
      return `${local[0]}***@${domain}`;
    case 'phone':
      return `***${value.slice(-4)}`;
    case 'cardNumber':
      return `****${value.slice(-4)}`;
    default:
      return '***REDACTED***';
  }
}

// Usage
console.log('User action:', maskPII({ email: 'john@example.com', phone: '+1234567890' }));
// Output: User action: { email: 'j***@example.com', phone: '***7890' }
```

### In API Responses

```typescript
// Don't expose internal IDs or sensitive data in responses
export function sanitizeUserResponse(user: UserDocument): PublicUser {
  return {
    id: user.id,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    // Exclude: email, phone, addresses, etc.
  };
}
```

---

## Data Retention

### Retention Policies

| Data Type | Retention Period | Action After |
|-----------|------------------|--------------|
| User accounts | Until deletion request | Anonymize |
| Order history | 7 years | Archive to cold storage |
| Chat messages | 2 years | Delete |
| Analytics | 2 years | Aggregate and delete raw |
| Audit logs | 7 years | Archive |
| Rate limit data | 24 hours | Auto-delete |
| Session data | 30 days inactive | Auto-delete |

### Automated Cleanup

```typescript
// functions/src/scheduled/dataRetention.ts
import * as functions from 'firebase-functions';

export const cleanupOldData = functions.pubsub
  .schedule('every day 02:00')
  .timeZone('UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const now = Date.now();
    
    // Delete old chat messages (2 years)
    const twoYearsAgo = new Date(now - 2 * 365 * 24 * 60 * 60 * 1000);
    const oldMessages = await db.collectionGroup('messages')
      .where('createdAt', '<', twoYearsAgo)
      .limit(500)
      .get();
    
    const batch = db.batch();
    oldMessages.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    
    console.log(`Deleted ${oldMessages.size} old messages`);
    
    // Delete inactive sessions (30 days)
    const thirtyDaysAgo = new Date(now - 30 * 24 * 60 * 60 * 1000);
    const oldSessions = await db.collectionGroup('sessions')
      .where('lastActiveAt', '<', thirtyDaysAgo)
      .limit(500)
      .get();
    
    const sessionBatch = db.batch();
    oldSessions.docs.forEach(doc => sessionBatch.delete(doc.ref));
    await sessionBatch.commit();
    
    console.log(`Deleted ${oldSessions.size} inactive sessions`);
  });
```

---

## Data Deletion (GDPR Right to Erasure)

### User Account Deletion

```typescript
// functions/src/users/deleteAccount.ts
export const deleteUserAccount = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  
  const db = admin.firestore();
  
  // 1. Get all user data locations
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();
  
  // 2. Delete or anonymize based on data type
  const batch = db.batch();
  
  // Delete user profile
  batch.delete(db.collection('users').doc(userId));
  
  // Delete buyer profile
  batch.delete(db.collection('buyers').doc(userId));
  
  // Delete sessions
  const sessions = await db.collection('users').doc(userId).collection('sessions').get();
  sessions.docs.forEach(doc => batch.delete(doc.ref));
  
  // 3. Anonymize data that must be retained (orders for accounting)
  if (userData?.userType === 'buyer') {
    const orders = await db.collectionGroup('orders')
      .where('buyerId', '==', userId)
      .get();
    
    orders.docs.forEach(doc => {
      batch.update(doc.ref, {
        'customer.name': 'Deleted User',
        'customer.email': 'deleted@example.com',
        'customer.phone': null,
        'customer.address': 'Address Removed',
        'buyerId': 'DELETED_' + userId,
      });
    });
  }
  
  // 4. Delete from Firebase Auth
  await admin.auth().deleteUser(userId);
  
  // 5. Delete from Cloud Storage
  const bucket = admin.storage().bucket();
  await bucket.deleteFiles({ prefix: `users/${userId}/` });
  
  // 6. Commit all Firestore changes
  await batch.commit();
  
  // 7. Log for compliance
  await db.collection('_deletionLogs').add({
    userId,
    email: userData?.email,
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    dataDeleted: ['users', 'buyers', 'sessions', 'storage'],
    dataAnonymized: ['orders'],
  });
  
  return { success: true };
});
```

### Data Export (GDPR Right to Portability)

```typescript
// functions/src/users/exportData.ts
export const exportUserData = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  
  const db = admin.firestore();
  
  // Collect all user data
  const exportData: Record<string, any> = {};
  
  // User profile
  const userDoc = await db.collection('users').doc(userId).get();
  exportData.profile = userDoc.data();
  
  // Buyer data
  const buyerDoc = await db.collection('buyers').doc(userId).get();
  if (buyerDoc.exists) {
    exportData.buyerProfile = buyerDoc.data();
  }
  
  // Orders
  const orders = await db.collectionGroup('orders')
    .where('buyerId', '==', userId)
    .get();
  exportData.orders = orders.docs.map(doc => doc.data());
  
  // Messages
  const conversations = await db.collectionGroup('conversations')
    .where('participants', 'array-contains', userId)
    .get();
  
  exportData.conversations = [];
  for (const conv of conversations.docs) {
    const messages = await conv.ref.collection('messages').get();
    exportData.conversations.push({
      ...conv.data(),
      messages: messages.docs.map(m => m.data()),
    });
  }
  
  // Generate downloadable file
  const bucket = admin.storage().bucket();
  const fileName = `exports/${userId}/data-export-${Date.now()}.json`;
  const file = bucket.file(fileName);
  
  await file.save(JSON.stringify(exportData, null, 2), {
    contentType: 'application/json',
  });
  
  // Generate signed URL (valid for 1 hour)
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000,
  });
  
  return { downloadUrl: url };
});
```

---

## Backup & Recovery

### Firestore Backups

```bash
# Daily automated backup via Cloud Scheduler
gcloud firestore export gs://purl-platform-backups/$(date +%Y-%m-%d)
```

### Backup Encryption

GCP automatically encrypts backups at rest.

### Recovery Procedure

```bash
# Restore from backup
gcloud firestore import gs://purl-platform-backups/2024-01-15
```

---

## Compliance Checklist

### GDPR (EU)

- [ ] Privacy policy published
- [ ] Consent collection for data processing
- [ ] Right to access (data export)
- [ ] Right to erasure (account deletion)
- [ ] Right to rectification (profile editing)
- [ ] Data breach notification process
- [ ] DPO contact information

### PCI DSS (Payments)

- [ ] No storage of full card numbers (Pesapal handles)
- [ ] Tokenization for saved payment methods
- [ ] Secure transmission (TLS)
- [ ] Access logging for payment data

### Local Regulations

- [ ] Kenya Data Protection Act compliance
- [ ] Other African market regulations as applicable
