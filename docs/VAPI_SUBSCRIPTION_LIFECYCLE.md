# VAPI Subscription Lifecycle Management

**Date**: February 22, 2026  
**Status**: Production Design

---

## Subscription States

### Active States
1. **`active`** - Service running, calls accepted
2. **`grace_period`** - Expired but within 30-day grace period, calls blocked
3. **`cancelled`** - User cancelled, immediate cleanup

### Terminal States
4. **`expired`** - Grace period ended, data deleted
5. **`deleted`** - Manually deleted by admin

---

## Subscription Lifecycle Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SUBSCRIPTION CREATED                      │
│                    status: "active"                          │
│                    startDate: now                            │
│                    expiryDate: now + 30 days                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    [30 days pass]
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   SUBSCRIPTION EXPIRES                       │
│                   status: "grace_period"                     │
│                   gracePeriodEndsAt: now + 30 days          │
│                   ACTION: Block incoming calls               │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    [User can renew]
                            ↓
                ┌───────────┴───────────┐
                │                       │
         [User Renews]          [30 days pass]
                │                       │
                ↓                       ↓
┌───────────────────────────┐  ┌──────────────────────────────┐
│   SUBSCRIPTION RENEWED    │  │   GRACE PERIOD EXPIRED       │
│   status: "active"        │  │   status: "expired"          │
│   expiryDate: now + 30d   │  │   ACTION: Delete everything  │
│   Keep all data           │  │   - Delete VAPI assistant    │
└───────────────────────────┘  │   - Delete VAPI phone number │
                               │   - Archive call logs        │
                               │   - Unassign DID             │
                               │   - Delete config            │
                               └──────────────────────────────┘
```

---

## Data Structure

### `/stores/{storeId}/aiAssistant/config`
```javascript
{
  enabled: true,
  status: "active" | "grace_period" | "cancelled" | "expired",
  
  // VAPI IDs
  vapiAssistantId: "assistant-abc123",
  vapiPhoneNumberId: "phone-xyz789",
  didId: "did-uuid",
  phoneNumber: "+256700123456",
  
  // Subscription
  subscription: {
    plan: "ai_basic",
    monthlyFee: 20,
    currency: "USD",
    
    // Dates
    startDate: timestamp,
    expiryDate: timestamp,  // 30 days from start/renewal
    gracePeriodEndsAt: timestamp | null,  // Set when expired
    
    // Usage
    minutesIncluded: 100,
    usedMinutes: 45,
    
    // Status
    status: "active" | "grace_period" | "cancelled" | "expired",
    autoRenew: false,  // Future: auto-charge
    
    // History
    renewalCount: 0,
    lastRenewalDate: timestamp | null,
    cancellationDate: timestamp | null,
    deletionScheduledFor: timestamp | null
  },
  
  createdAt: timestamp,
  updatedAt: timestamp
}
```

---

## Cloud Functions

### 1. Daily Subscription Check (Scheduled)
**Trigger**: Every day at 2 AM (Africa/Johannesburg)

```typescript
export const checkSubscriptionStatus = onSchedule(
  {
    schedule: "0 2 * * *",  // 2 AM daily
    timeZone: "Africa/Johannesburg"
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    
    // Find subscriptions that expired today
    const expiredSnapshot = await admin.firestore()
      .collectionGroup("aiAssistant")
      .where("subscription.expiryDate", "<=", now)
      .where("subscription.status", "==", "active")
      .get();
    
    for (const doc of expiredSnapshot.docs) {
      const storeId = doc.ref.parent.parent!.id;
      const gracePeriodEndsAt = new Date();
      gracePeriodEndsAt.setDate(gracePeriodEndsAt.getDate() + 30);
      
      await doc.ref.update({
        "subscription.status": "grace_period",
        "subscription.gracePeriodEndsAt": admin.firestore.Timestamp.fromDate(gracePeriodEndsAt),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Notify store owner
      await notifySubscriptionExpired(storeId);
      
      console.log(`⏰ Store ${storeId} entered grace period`);
    }
    
    // Find grace periods that ended today
    const gracePeriodEndedSnapshot = await admin.firestore()
      .collectionGroup("aiAssistant")
      .where("subscription.gracePeriodEndsAt", "<=", now)
      .where("subscription.status", "==", "grace_period")
      .get();
    
    for (const doc of gracePeriodEndedSnapshot.docs) {
      const storeId = doc.ref.parent.parent!.id;
      await deleteAIService(storeId);
      console.log(`🗑️ Store ${storeId} AI service deleted after grace period`);
    }
  }
);
```

### 2. Renew Subscription (Callable)
```typescript
export const renewAISubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Must be authenticated");
  }

  const {storeId, paymentId} = request.data;
  
  // Verify payment (integrate with your payment system)
  const paymentDoc = await admin.firestore()
    .collection("payments")
    .doc(paymentId)
    .get();
  
  if (!paymentDoc.exists || paymentDoc.data()?.status !== "approved") {
    throw new Error("Payment not verified");
  }
  
  // Get current config
  const configDoc = await admin.firestore()
    .collection("stores")
    .doc(storeId)
    .collection("aiAssistant")
    .doc("config")
    .get();
  
  if (!configDoc.exists) {
    throw new Error("AI service not configured");
  }
  
  const currentStatus = configDoc.data()?.subscription?.status;
  
  // Calculate new expiry date
  const newExpiryDate = new Date();
  newExpiryDate.setDate(newExpiryDate.getDate() + 30);
  
  // Update subscription
  await configDoc.ref.update({
    "subscription.status": "active",
    "subscription.expiryDate": admin.firestore.Timestamp.fromDate(newExpiryDate),
    "subscription.gracePeriodEndsAt": null,
    "subscription.usedMinutes": 0,  // Reset usage
    "subscription.renewalCount": admin.firestore.FieldValue.increment(1),
    "subscription.lastRenewalDate": admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // If was in grace period, re-enable calls
  if (currentStatus === "grace_period") {
    // No action needed - webhook will check status
  }
  
  // Record payment
  await admin.firestore()
    .collection("stores")
    .doc(storeId)
    .collection("aiAssistant")
    .collection("payments")
    .add({
      paymentId: paymentId,
      amount: 20,
      currency: "USD",
      type: "renewal",
      status: "completed",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  
  return {
    success: true,
    expiryDate: newExpiryDate.toISOString(),
    message: "Subscription renewed successfully"
  };
});
```

### 3. Cancel Subscription (Callable)
```typescript
export const cancelAISubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Must be authenticated");
  }

  const {storeId, immediate = false} = request.data;
  
  const configDoc = await admin.firestore()
    .collection("stores")
    .doc(storeId)
    .collection("aiAssistant")
    .doc("config")
    .get();
  
  if (!configDoc.exists) {
    throw new Error("AI service not configured");
  }
  
  if (immediate) {
    // Immediate deletion
    await deleteAIService(storeId);
    return {success: true, message: "AI service deleted immediately"};
  } else {
    // Mark as cancelled, delete at end of current period
    const expiryDate = configDoc.data()?.subscription?.expiryDate?.toDate();
    
    await configDoc.ref.update({
      "subscription.status": "cancelled",
      "subscription.cancellationDate": admin.firestore.FieldValue.serverTimestamp(),
      "subscription.deletionScheduledFor": expiryDate,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return {
      success: true,
      message: "Subscription cancelled. Service will end on expiry date.",
      serviceEndsAt: expiryDate?.toISOString()
    };
  }
});
```

### 4. Delete AI Service (Internal)
```typescript
async function deleteAIService(storeId: string) {
  const configDoc = await admin.firestore()
    .collection("stores")
    .doc(storeId)
    .collection("aiAssistant")
    .doc("config")
    .get();
  
  if (!configDoc.exists) return;
  
  const config = configDoc.data()!;
  const vapiClient = new VapiClient(vapiPrivateKey.value());
  
  // 1. Delete VAPI assistant
  try {
    await vapiClient.deleteAssistant(config.vapiAssistantId);
    console.log(`✅ Deleted VAPI assistant ${config.vapiAssistantId}`);
  } catch (error) {
    console.error("Error deleting assistant:", error);
  }
  
  // 2. Delete VAPI phone number
  try {
    await vapiClient.deletePhoneNumber(config.vapiPhoneNumberId);
    console.log(`✅ Deleted VAPI phone number ${config.vapiPhoneNumberId}`);
  } catch (error) {
    console.error("Error deleting phone number:", error);
  }
  
  // 3. Unassign DID (make available for other stores)
  await admin.firestore()
    .collection("dids")
    .doc(config.didId)
    .update({
      assigned: false,
      storeId: null,
      vapiPhoneNumberId: null,
      assignedAt: null,
      unassignedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  
  // 4. Archive call logs (move to archive subcollection)
  const callLogsSnapshot = await admin.firestore()
    .collection("stores")
    .doc(storeId)
    .collection("aiAssistant")
    .collection("callLogs")
    .get();
  
  const batch = admin.firestore().batch();
  
  for (const logDoc of callLogsSnapshot.docs) {
    // Copy to archive
    const archiveRef = admin.firestore()
      .collection("stores")
      .doc(storeId)
      .collection("aiAssistant")
      .collection("archivedCallLogs")
      .doc(logDoc.id);
    
    batch.set(archiveRef, {
      ...logDoc.data(),
      archivedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Delete original
    batch.delete(logDoc.ref);
  }
  
  await batch.commit();
  
  // 5. Update config to expired status
  await configDoc.ref.update({
    enabled: false,
    "subscription.status": "expired",
    vapiAssistantId: null,
    vapiPhoneNumberId: null,
    phoneNumber: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    deletedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // 6. Notify store owner
  await notifyServiceDeleted(storeId);
  
  console.log(`🗑️ AI service deleted for store ${storeId}`);
}
```

### 5. Webhook Call Blocking
```typescript
// In vapiWebhook.ts - add status check
export const vapiWebhook = onRequest(async (req, res) => {
  const event = req.body;

  // For incoming calls, check subscription status
  if (event.type === "assistant-request") {
    const phoneNumber = event.call?.phoneNumber?.number;
    
    // Find store
    const didsSnapshot = await admin.firestore()
      .collection("dids")
      .where("phoneNumber", "==", phoneNumber)
      .limit(1)
      .get();
    
    if (didsSnapshot.empty) {
      return res.status(404).send({error: "Store not found"});
    }
    
    const storeId = didsSnapshot.docs[0].data().storeId;
    
    // Check subscription status
    const configDoc = await admin.firestore()
      .collection("stores")
      .doc(storeId)
      .collection("aiAssistant")
      .doc("config")
      .get();
    
    const status = configDoc.data()?.subscription?.status;
    
    if (status !== "active") {
      // Block call - return error or play message
      return res.status(200).send({
        assistant: {
          firstMessage: "This service is currently unavailable. Please contact the store directly.",
          endCallMessage: "Goodbye.",
          endCallFunctionEnabled: true
        }
      });
    }
    
    // Allow call to proceed
    return res.status(200).send({success: true});
  }
  
  // Handle end-of-call-report as before
  if (event.type === "end-of-call-report") {
    // ... existing code
  }
  
  return res.status(200).send({success: true});
});
```

---

## Notification System

### Subscription Expiry Warning (7 days before)
```typescript
// In daily check function
const sevenDaysFromNow = new Date();
sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

const expiringSnapshot = await admin.firestore()
  .collectionGroup("aiAssistant")
  .where("subscription.expiryDate", "<=", admin.firestore.Timestamp.fromDate(sevenDaysFromNow))
  .where("subscription.status", "==", "active")
  .get();

for (const doc of expiringSnapshot.docs) {
  const storeId = doc.ref.parent.parent!.id;
  await notifySubscriptionExpiring(storeId, 7);
}
```

### Notification Messages
1. **7 days before expiry**: "Your AI Customer Service subscription expires in 7 days. Renew now to avoid service interruption."
2. **On expiry**: "Your AI Customer Service has expired. You have 30 days to renew before your data is deleted."
3. **15 days into grace period**: "Your AI service will be deleted in 15 days. Renew now to keep your call history."
4. **3 days before deletion**: "Final reminder: Your AI service and call logs will be permanently deleted in 3 days."
5. **After deletion**: "Your AI Customer Service has been removed. Subscribe again anytime to get a new phone number."

---

## Edge Cases

### 1. Renewal During Grace Period
- Restore full service immediately
- Keep all archived call logs
- Reset usage minutes
- Extend expiry by 30 days from renewal date

### 2. Multiple Renewals
- Track renewal count
- Keep payment history
- Consider loyalty discounts (future)

### 3. DID Reassignment
- When store's service is deleted, DID goes back to pool
- Another store can get the same number
- Old call logs are archived (not accessible to new store)

### 4. Partial Month Usage
- No pro-rating
- Full month charge regardless of usage
- Minutes reset on renewal

### 5. Over-Usage
- If store exceeds 100 minutes:
  - Option A: Block further calls until renewal
  - Option B: Charge overage ($0.20/min) - requires payment integration
  - Recommended: Option A for simplicity

---

## Database Indexes Required

Add to `firestore.indexes.json`:
```json
{
  "collectionGroup": "aiAssistant",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {"fieldPath": "subscription.expiryDate", "order": "ASCENDING"},
    {"fieldPath": "subscription.status", "order": "ASCENDING"}
  ]
},
{
  "collectionGroup": "aiAssistant",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {"fieldPath": "subscription.gracePeriodEndsAt", "order": "ASCENDING"},
    {"fieldPath": "subscription.status", "order": "ASCENDING"}
  ]
}
```

---

## Admin Dashboard Queries

### Active Subscriptions
```typescript
db.collectionGroup("aiAssistant")
  .where("subscription.status", "==", "active")
  .get();
```

### Grace Period Subscriptions
```typescript
db.collectionGroup("aiAssistant")
  .where("subscription.status", "==", "grace_period")
  .get();
```

### Revenue Tracking
```typescript
db.collectionGroup("payments")
  .where("type", "==", "renewal")
  .where("status", "==", "completed")
  .get();
```

---

## Implementation Priority

1. **Phase 1** (MVP):
   - Basic subscription tracking
   - Manual renewal via payment
   - Scheduled deletion after grace period

2. **Phase 2** (Enhancement):
   - Automated expiry notifications
   - Grace period warnings
   - Usage alerts (approaching 100 minutes)

3. **Phase 3** (Advanced):
   - Auto-renewal with saved payment method
   - Overage charging
   - Loyalty discounts
   - Analytics dashboard

---

**Status**: Ready for implementation
