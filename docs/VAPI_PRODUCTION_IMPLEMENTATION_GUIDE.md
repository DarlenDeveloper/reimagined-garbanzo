# VAPI AI Customer Service - Production Implementation Guide

**Date**: February 22, 2026  
**Status**: IN PROGRESS

---

## Implementation Checklist

### ✅ COMPLETED
- [x] VAPI credentials documented
- [x] Architecture designed
- [x] Subscription lifecycle designed
- [x] All Cloud Functions implemented
- [x] TypeScript types created
- [x] VAPI client wrapper created
- [x] Helper functions created
- [x] Firestore indexes updated
- [x] Setup scripts created
- [x] Code compiled successfully

### 🔄 IN PROGRESS
- [ ] Task 3: Store Secrets in Firebase
- [ ] Task 1: Run Setup Scripts (requires Firebase auth)
- [ ] Task 5: Deploy Functions
- [ ] Task 6: Flutter Integration
- [ ] Task 7: Testing

### ⏸️ BLOCKED
- Setup scripts require Firebase authentication
- Need to run: `firebase login` first

---

## TASK 1: Setup VAPI Configuration in Firestore

### 1.1 Create Setup Script
**File**: `functions/src/scripts/setupVapiConfig.ts`

### 1.2 Create DID Population Script
**File**: `functions/src/scripts/populateDids.ts`

### 1.3 Run Scripts
```bash
cd functions
npm run build
node lib/scripts/setupVapiConfig.js
node lib/scripts/populateDids.js
```

---

## TASK 2: Implement Cloud Functions

### Files to Create:

#### Core Files
1. `functions/src/vapi/types.ts` - TypeScript interfaces
2. `functions/src/vapi/vapiClient.ts` - VAPI API wrapper
3. `functions/src/vapi/helpers.ts` - Shared utilities

#### Function Files
4. `functions/src/vapi/enableAIService.ts` - Enable AI for store
5. `functions/src/vapi/renewAISubscription.ts` - Renew subscription
6. `functions/src/vapi/vapiWebhook.ts` - Handle VAPI webhooks
7. `functions/src/vapi/getCallLogs.ts` - Fetch call history
8. `functions/src/vapi/getAIConfig.ts` - Get current config
9. `functions/src/vapi/checkSubscriptionStatus.ts` - Daily scheduled check
10. `functions/src/vapi/deleteAIService.ts` - Internal cleanup function

#### Update
11. `functions/src/index.ts` - Export all functions

---

## TASK 3: Store Secrets

```bash
firebase functions:secrets:set VAPI_PRIVATE_KEY
# Enter: 0b2ef112-f947-4a36-a520-083bc5902771

firebase functions:secrets:set VAPI_PUBLIC_KEY
# Enter: fc915f5b-fdb2-41fb-a601-c6ed2ea1072d
```

---

## TASK 4: Update Firestore Indexes

**File**: `firestore.indexes.json`

Add indexes for:
- DIDs collection
- Call logs
- Subscription queries

---

## TASK 5: Deploy Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

---

## TASK 6: Flutter Integration

### Files to Create:
1. `lib/models/call_log.dart`
2. `lib/models/ai_config.dart`
3. `lib/services/vapi_service.dart`
4. `lib/providers/ai_service_provider.dart`
5. `lib/screens/ai_customer_service_screen.dart`
6. `lib/screens/call_detail_screen.dart`
7. `lib/widgets/call_log_card.dart`

---

## TASK 7: Testing

### Test Cases:
1. Enable AI service for test store
2. Make test call
3. Verify webhook receives data
4. Check call log saved
5. Verify push notification
6. Test subscription expiry
7. Test grace period
8. Test renewal
9. Test deletion after grace period

---

## Subscription Flow Summary

**States**: `active` → `grace_period` → `expired`

**Timeline**:
- Day 0: Subscribe ($20)
- Day 30: Expires → Grace period starts
- Day 30-60: Grace period (calls blocked, data preserved)
- Day 60: If not renewed → Delete everything

**What Gets Deleted**:
- VAPI assistant
- VAPI phone number
- Call logs (archived first)
- Config marked expired
- DID returned to pool

**Notifications**:
- Day 23: "Expires in 7 days"
- Day 30: "Expired, 30 days to renew"
- Day 45: "15 days until deletion"
- Day 57: "3 days until deletion"
- Day 60: "Service deleted"

---

## Key Configuration

**VAPI Settings**:
- SIP Credential ID: `25718c8b-4388-4b59-ad0c-e2c7b8ea2147`
- Voice ID: `GDzHdQOi6jjf8zaXhCYD` (Riley)
- Voice Model: `eleven_turbo_v2_5`
- LLM: `gpt-4o-mini`
- Structured Outputs:
  - Call Summary: `a356b2a9-fecc-49da-9220-85b5d315e2db`
  - CSAT: `01b9a819-68cb-41d6-b626-4426af1e89bb`

**Subscription**:
- Price: $20/month
- Minutes: 100 included
- Overage: Block calls (no charging)
- Grace Period: 30 days

**Firebase**:
- Project: `purlstores-za`
- Region: `africa-south1`
- Runtime: Node.js 20

---

## Progress Tracking

**Current Task**: Starting Task 1
**Next**: Task 2
**Blockers**: None

---

**Let's build this! 🚀**
