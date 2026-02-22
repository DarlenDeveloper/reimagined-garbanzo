# 🚀 VAPI AI Customer Service - Deployment Instructions

**Created**: February 22, 2026  
**Package**: vapi-deployment.zip (24MB)

---

## ✅ What's Ready

- ✅ All 10 Cloud Functions written and compiled
- ✅ VAPI secrets stored in Firebase Secret Manager
- ✅ Setup scripts created
- ✅ Firestore indexes configured
- ✅ Deployment package created

---

## 📦 Deployment Package Contents

```
vapi-deployment.zip
├── functions/                    (All Cloud Functions code)
│   ├── lib/                     (Compiled JavaScript)
│   ├── src/                     (TypeScript source)
│   └── package.json
├── firebase.json                 (Firebase configuration)
├── .firebaserc                   (Project settings)
├── firestore.indexes.json        (Database indexes)
├── firestore.rules               (Security rules)
├── storage.rules                 (Storage rules)
├── DEPLOY_FROM_GCP_CLOUD_SHELL.sh (🎯 Main deployment script)
├── MANUAL_FIRESTORE_SETUP.sh     (Manual setup helper)
├── README.md                     (Quick start guide)
└── docs/                         (Full documentation)
    ├── VAPI_IMPLEMENTATION_STATUS.md
    ├── VAPI_CREDENTIALS.md
    ├── MANUAL_SETUP_GUIDE.md
    └── VAPI_SUBSCRIPTION_LIFECYCLE.md
```

---

## 🚀 Deployment Steps

### Step 1: Upload to GCP Cloud Shell

1. Go to: https://console.cloud.google.com/cloudshell
2. Click the **⋮** menu (top right)
3. Select **"Upload"**
4. Choose `vapi-deployment.zip` from your computer
5. Wait for upload to complete

### Step 2: Extract Package

```bash
unzip vapi-deployment.zip
cd vapi-deployment
```

### Step 3: Run Deployment Script

```bash
bash DEPLOY_FROM_GCP_CLOUD_SHELL.sh
```

The script will:
- ✅ Extract files
- ✅ Set Firebase project
- ✅ Create Firestore configuration
- ✅ Populate DID pool
- ✅ Deploy all 17 Cloud Functions
- ✅ Deploy Firestore indexes

### Step 4: Verify Deployment

After deployment completes, verify:

1. **Functions deployed**: https://console.firebase.google.com/project/purlstores-za/functions
   - Check for 6 new functions:
     - enableAIService
     - vapiWebhook
     - getCallLogs
     - getAIConfig
     - renewAISubscription
     - checkSubscriptionStatus

2. **Firestore config**: https://console.firebase.google.com/project/purlstores-za/firestore
   - Check `/config/vapi` document exists
   - Check `/dids` collection has phone numbers

3. **Scheduler**: https://console.cloud.google.com/cloudscheduler
   - Check `checkSubscriptionStatus` scheduled for 2 AM daily

---

## 🧪 Testing

### Test 1: Enable AI for a Store

From Firebase Console Functions:
```javascript
// Call enableAIService
{
  "storeId": "your-test-store-id"
}
```

Expected response:
```javascript
{
  "success": true,
  "phoneNumber": "+256205479710",
  "assistantId": "assistant-xxx",
  "expiryDate": "2026-03-24T..."
}
```

### Test 2: Make a Test Call

1. Call the assigned phone number
2. Riley should answer
3. Have a conversation
4. Hang up

### Test 3: Verify Call Log

Check Firestore:
```
/stores/{storeId}/aiAssistant/callLogs/{callId}
```

Should contain:
- transcript
- summary
- csatScore
- duration
- cost

### Test 4: Check Notification

Store owner should receive push notification:
"📞 New Customer Call"

---

## 🔧 Troubleshooting

### If Deployment Fails

**Error: "Not logged in"**
```bash
firebase login --no-localhost
```

**Error: "Project not found"**
```bash
firebase use purlstores-za
```

**Error: "Secrets not found"**
```bash
firebase functions:secrets:set VAPI_PRIVATE_KEY
firebase functions:secrets:set VAPI_PUBLIC_KEY
```

### Manual Firestore Setup

If setup scripts fail, create documents manually:

```bash
bash MANUAL_FIRESTORE_SETUP.sh
```

Or use Firebase Console UI (instructions in script output).

---

## 📊 What Gets Deployed

### Cloud Functions (17 total)

**Existing (11)**:
1. onOrderCreated
2. createPaymentRecord
3. onMessageSent
4. onProductStockUpdate
5. sendBulkNotification
6. notifyNearbyCouriers
7. onDeliveryStatusChanged
8. onDeliveryAccepted
9. chargeCard
10. chargeMobileMoney
11. verifyFlutterwavePayment

**New VAPI Functions (6)**:
12. enableAIService ✨
13. vapiWebhook ✨
14. getCallLogs ✨
15. getAIConfig ✨
16. renewAISubscription ✨
17. checkSubscriptionStatus ✨ (scheduled)

### Firestore Collections

**New**:
- `/config/vapi` - VAPI configuration
- `/dids` - Phone number pool
- `/stores/{id}/aiAssistant/config` - Per-store AI config
- `/stores/{id}/aiAssistant/callLogs` - Call history

**Indexes (5 new)**:
- DIDs by assigned status
- Call logs by date
- Subscriptions by expiry date
- Subscriptions by grace period end

---

## 🎯 After Deployment

### Immediate Next Steps

1. ✅ Test enableAIService function
2. ✅ Make test call
3. ✅ Verify webhook works
4. ✅ Check call log saved
5. ✅ Verify notification sent

### Flutter Integration

Once backend is verified:
1. Build AI Customer Service screen
2. Implement call logs list
3. Add subscription management
4. Test end-to-end flow

---

## 📞 Support

If you encounter issues:

1. Check `firebase-debug.log` in Cloud Shell
2. Check Cloud Functions logs in Firebase Console
3. Verify secrets are set correctly
4. Check Firestore security rules

---

## 🎉 Success Criteria

Deployment is successful when:
- ✅ All 17 functions show "Active" in Firebase Console
- ✅ `/config/vapi` document exists in Firestore
- ✅ `/dids` collection has phone numbers
- ✅ Test call works and logs are saved
- ✅ Push notification received

---

**Ready to deploy! 🚀**

Upload `vapi-deployment.zip` to GCP Cloud Shell and run the deployment script!
