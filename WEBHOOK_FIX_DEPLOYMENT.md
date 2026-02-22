# Webhook Fix Deployment Guide

**Date**: February 22, 2026  
**Issue**: Call logs not appearing in Flutter app after test calls

---

## 🔍 Problem Analysis

### Symptoms
- Test calls working (Riley answers)
- Webhook receiving events
- But `event.type` showing as `undefined` in logs
- Call logs not appearing in Flutter app
- Usage minutes not updating

### Root Causes Identified
1. **VAPI Payload Structure**: VAPI sends webhook events with `message.type` instead of `type`
2. **Firestore Path Mismatch**: 
   - Webhook was saving to: `stores/{storeId}/aiAssistant/callLogs/logs/{callId}`
   - Flutter was querying: `stores/{storeId}/aiAssistant/config/callLogs/{callId}`
3. **Phone Number Lookup**: Only checking by `phoneNumber`, not by `vapiPhoneNumberId`

---

## ✅ Fixes Applied

### 1. Webhook Event Type Parsing
**Before**:
```typescript
const event: VapiWebhookEvent = req.body;
if (event.type === "assistant-request") { ... }
```

**After**:
```typescript
const messageType = req.body.message?.type || req.body.type;
if (messageType === "assistant-request") { ... }
```

### 2. Call Log Firestore Path
**Before**:
```typescript
.collection("stores")
.doc(storeId)
.collection("aiAssistant")
.doc("callLogs")
.collection("logs")
.doc(call.id)
```

**After**:
```typescript
.collection("stores")
.doc(storeId)
.collection("aiAssistant")
.doc("config")
.collection("callLogs")
.doc(call.id)
```

### 3. Phone Number Lookup
**Before**:
```typescript
const didsSnapshot = await admin
  .firestore()
  .collection("dids")
  .where("phoneNumber", "==", call.phoneNumber.number)
  .limit(1)
  .get();
```

**After**:
```typescript
// Try by vapiPhoneNumberId first
let didsSnapshot = await admin
  .firestore()
  .collection("dids")
  .where("vapiPhoneNumberId", "==", phoneNumberId)
  .limit(1)
  .get();

// Fallback to phone number if not found
if (didsSnapshot.empty && phoneNumber) {
  didsSnapshot = await admin
    .firestore()
    .collection("dids")
    .where("phoneNumber", "==", phoneNumber)
    .limit(1)
    .get();
}
```

### 4. Enhanced Logging
Added detailed logging to help debug future issues:
```typescript
console.log("📦 Raw webhook body:", JSON.stringify(req.body, null, 2));
console.log("📦 Event keys:", Object.keys(req.body));
console.log("📦 Message type:", req.body.message?.type);
console.log(`📞 VAPI Webhook - Message Type: ${messageType}`);
```

### 5. Duration Calculation Safety
Added null checks for timestamps:
```typescript
const startTime = call.startedAt ? new Date(call.startedAt).getTime() : Date.now();
const endTime = call.endedAt ? new Date(call.endedAt).getTime() : Date.now();
const duration = Math.floor((endTime - startTime) / 1000);
```

---

## 📦 Deployment Package

**File**: `vapi-deployment.zip` (24MB)  
**Status**: ✅ Ready

### Package Contents
- All Cloud Functions source code
- Updated `vapiWebhook.ts` with fixes
- Firebase configuration files
- Deployment script

---

## 🚀 Deployment Instructions

### Option 1: GCP Cloud Shell (Recommended)

1. **Open GCP Cloud Shell**
   ```
   https://console.cloud.google.com/cloudshell
   ```

2. **Upload Deployment Package**
   - Click the ⋮ menu (top right)
   - Select "Upload"
   - Choose `vapi-deployment.zip`

3. **Extract and Deploy**
   ```bash
   unzip vapi-deployment.zip
   cd vapi-deployment
   chmod +x DEPLOY_FROM_GCP_CLOUD_SHELL.sh
   ./DEPLOY_FROM_GCP_CLOUD_SHELL.sh
   ```

4. **Follow Prompts**
   - Confirm function deletion if asked (old `onDeliveryCompleted`)
   - Wait for deployment to complete (~5-10 minutes)

### Option 2: Local Deployment

If your network allows:
```bash
cd functions
npm run build
cd ..
firebase deploy --only functions:vapiWebhook
```

---

## ✅ Verification Steps

After deployment, verify the fix:

### 1. Check Function Deployment
```bash
firebase functions:list | grep vapiWebhook
```

Expected output:
```
vapiWebhook(africa-south1)
```

### 2. Make Test Call
Call the test store's phone number: **+256205479710**

### 3. Check Logs
```bash
firebase functions:log --only vapiWebhook --limit 50
```

Look for:
```
📦 Raw webhook body: {...}
📦 Message type: end-of-call-report
📞 VAPI Webhook - Message Type: end-of-call-report
✅ Call log saved to: stores/X92KHn36wXuua9syZfqS/aiAssistant/config/callLogs/...
📊 Updated usage: +1 minutes
✅ Notification sent
```

### 4. Check Firestore
Navigate to:
```
stores/X92KHn36wXuua9syZfqS/aiAssistant/config/callLogs
```

Should see call documents with:
- `callId`
- `customerPhone`
- `duration`
- `transcript`
- `summary`
- `csatScore`
- `createdAt`

### 5. Check Flutter App
1. Open AI Customer Service screen
2. Should see call log appear in list
3. Tap to view call details
4. Verify usage minutes updated

---

## 🐛 Troubleshooting

### If call logs still don't appear:

1. **Check webhook is receiving events**
   ```bash
   firebase functions:log --only vapiWebhook --limit 10
   ```

2. **Verify VAPI webhook configuration**
   - Go to VAPI dashboard
   - Check assistant settings
   - Verify webhook URL: `https://africa-south1-purlstores-za.cloudfunctions.net/vapiWebhook`
   - Verify server messages include: `end-of-call-report`

3. **Check Firestore path**
   ```bash
   gcloud firestore documents list \
     projects/purlstores-za/databases/(default)/documents/stores/X92KHn36wXuua9syZfqS/aiAssistant/config/callLogs
   ```

4. **Verify DID mapping**
   ```bash
   gcloud firestore documents list \
     projects/purlstores-za/databases/(default)/documents/dids
   ```

### If deployment fails:

1. **Clean node_modules**
   ```bash
   cd functions
   rm -rf node_modules package-lock.json
   npm install
   npm run build
   ```

2. **Check Firebase project**
   ```bash
   firebase use
   ```
   Should show: `purlstores-za`

3. **Verify secrets**
   ```bash
   firebase functions:secrets:access VAPI_PRIVATE_KEY
   firebase functions:secrets:access VAPI_PUBLIC_KEY
   ```

---

## 📊 Expected Results

After successful deployment:

1. ✅ Webhook receives `end-of-call-report` events
2. ✅ Call logs saved to correct Firestore path
3. ✅ Flutter app displays call logs in real-time
4. ✅ Usage minutes increment correctly
5. ✅ Push notifications sent to store staff
6. ✅ Call details show transcript, summary, and CSAT score

---

## 🎯 Test Store Details

**Store ID**: `X92KHn36wXuua9syZfqS`  
**Phone Number**: `+256205479710`  
**VAPI Assistant**: Configured with webhook  
**Subscription**: Active (if enabled)

---

## 📝 Files Modified

1. `functions/src/vapi/vapiWebhook.ts` - Main webhook handler
2. `docs/VAPI_IMPLEMENTATION_STATUS.md` - Status update
3. `WEBHOOK_FIX_DEPLOYMENT.md` - This file

---

## 🔄 Next Steps After Deployment

1. Make test call to verify fix
2. Monitor logs for any errors
3. Test full user flow in Flutter app
4. Consider cleanup script to reset test store if needed
5. Document any additional issues found

---

**Deployment Package**: `vapi-deployment.zip` (ready to upload)  
**Estimated Deployment Time**: 5-10 minutes  
**Risk Level**: Low (only updating webhook function)
