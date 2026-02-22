# Manual Setup Guide - VAPI AI Customer Service

**Date**: February 22, 2026  
**Status**: Alternative to automated scripts due to network issues

---

## Current Status

✅ **Completed:**
- All Cloud Functions code written and compiled
- VAPI secrets stored in Firebase Secret Manager
  - `VAPI_PRIVATE_KEY`: ✅ Created
  - `VAPI_PUBLIC_KEY`: ✅ Created

❌ **Blocked:**
- Firebase CLI network connectivity issues
- Cannot deploy functions
- Cannot run setup scripts

---

## Manual Setup via Firebase Console

### Step 1: Create VAPI Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `purlstores-za`
3. Go to Firestore Database
4. Create a new collection: `config`
5. Create a document with ID: `vapi`
6. Add the following fields:

```javascript
{
  structuredOutputIds: [
    "a356b2a9-fecc-49da-9220-85b5d315e2db",
    "01b9a819-68cb-41d6-b626-4426af1e89bb"
  ],
  sipCredentialId: "25718c8b-4388-4b59-ad0c-e2c7b8ea2147",
  voiceId: "GDzHdQOi6jjf8zaXhCYD",
  voiceModel: "eleven_turbo_v2_5",
  llmModel: "gpt-4o-mini",
  subscriptionPlan: {
    name: "ai_basic",
    monthlyFee: 20,
    currency: "USD",
    minutesIncluded: 100,
    costPerMinute: 0.20
  },
  createdAt: [Current timestamp]
}
```

### Step 2: Create DID Pool

1. In Firestore, create a new collection: `dids`
2. For each phone number, create a document with auto-generated ID:

```javascript
{
  phoneNumber: "+256205479710",
  assigned: false,
  storeId: null,
  vapiPhoneNumberId: null,
  assignedAt: null,
  createdAt: [Current timestamp]
}
```

Add more DIDs as you get them from your SIP provider.

---

## Deploy When Network is Stable

Once network issues are resolved, run:

```bash
firebase deploy --only functions --project purlstores-za
```

This will deploy all 17 functions (11 existing + 6 new VAPI functions).

---

## Alternative: Deploy from Different Network

If network issues persist:

1. Commit all code to Git
2. Deploy from a machine with stable internet:
   ```bash
   git pull
   cd functions
   npm install
   npm run build
   firebase login
   firebase deploy --only functions --project purlstores-za
   ```

---

## Verify Deployment

After successful deployment, verify:

1. Go to Firebase Console → Functions
2. Check that these new functions exist:
   - `enableAIService`
   - `vapiWebhook`
   - `getCallLogs`
   - `getAIConfig`
   - `renewAISubscription`
   - `checkSubscriptionStatus`

3. Check Cloud Scheduler:
   - `checkSubscriptionStatus` should be scheduled for 2 AM daily

---

## Test the System

Once deployed:

1. **Enable AI for a test store:**
   ```javascript
   // Call from your app or Firebase Console
   functions.httpsCallable('enableAIService')({
     storeId: 'test-store-id'
   })
   ```

2. **Make a test call:**
   - Call the assigned phone number
   - Verify Riley answers
   - Check call log is saved

3. **Check webhook:**
   - Verify `vapiWebhook` receives events
   - Check Firestore for call logs

---

## Current Code Status

All code is ready in:
```
functions/src/vapi/
├── types.ts
├── vapiClient.ts
├── helpers.ts
├── enableAIService.ts
├── vapiWebhook.ts
├── getCallLogs.ts
├── getAIConfig.ts
├── renewAISubscription.ts
├── checkSubscriptionStatus.ts
└── deleteAIService.ts
```

Compiled output in: `functions/lib/`

---

## Next Steps

1. **Option A**: Wait for network to stabilize, then deploy
2. **Option B**: Manually create Firestore documents, then deploy when possible
3. **Option C**: Deploy from different network/machine

All backend code is complete and ready to go! 🚀
