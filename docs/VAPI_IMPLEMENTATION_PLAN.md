# VAPI AI Customer Service - Implementation Plan

**Date**: February 22, 2026  
**Status**: Ready to Execute

---

## Implementation Tasks

### Task 1: Setup VAPI Configuration in Firestore
**Goal**: Store global VAPI settings and create DID pool

**Steps**:
1. Create `/config/vapi` document with:
   - Structured output IDs
   - SIP credential ID
   - Voice settings
2. Create script to populate `/dids` collection with available phone numbers

**Files to Create**:
- `functions/src/scripts/setupVapiConfig.ts`
- `functions/src/scripts/populateDids.ts`

---

### Task 2: Implement Cloud Functions
**Goal**: Create backend functions for AI service management

**Functions to Create**:

1. **`enableAIService`** (Callable)
   - Check store subscription eligibility
   - Assign unassigned DID
   - Create VAPI assistant
   - Create VAPI phone number
   - Save config to Firestore
   - Return phone number to app

2. **`vapiWebhook`** (HTTPS)
   - Handle `assistant-request` event (optional)
   - Handle `end-of-call-report` event
   - Extract structured data (CSAT + Summary)
   - Save call log to Firestore
   - Send push notification to store staff
   - Update usage minutes

3. **`getCallLogs`** (Callable)
   - Fetch call history for store
   - Return paginated results

4. **`updateAIConfig`** (Callable)
   - Update assistant configuration
   - Sync changes to VAPI

5. **`disableAIService`** (Callable)
   - Delete VAPI assistant
   - Delete VAPI phone number
   - Mark DID as unassigned
   - Archive config

**Files to Create**:
- `functions/src/vapi/enableAIService.ts`
- `functions/src/vapi/vapiWebhook.ts`
- `functions/src/vapi/getCallLogs.ts`
- `functions/src/vapi/updateAIConfig.ts`
- `functions/src/vapi/disableAIService.ts`
- `functions/src/vapi/vapiClient.ts` (API wrapper)
- `functions/src/vapi/types.ts` (TypeScript types)

---

### Task 3: Store VAPI Keys in Secret Manager
**Goal**: Securely store API credentials

**Steps**:
1. Add VAPI private key to Firebase Secret Manager
2. Add VAPI public key to Secret Manager
3. Update function definitions to use secrets

**Command**:
```bash
firebase functions:secrets:set VAPI_PRIVATE_KEY
firebase functions:secrets:set VAPI_PUBLIC_KEY
```

---

### Task 4: Update Firestore Indexes
**Goal**: Add indexes for AI service queries

**Indexes to Add**:
- `/dids`: `assigned` + `createdAt`
- `/stores/{storeId}/aiAssistant/callLogs`: `createdAt` (descending)

**File to Update**:
- `firestore.indexes.json`

---

### Task 5: Flutter Integration (Seller App)
**Goal**: Build UI for AI customer service

**Screens to Create**:
1. **AI Customer Service Screen** (`ai_customer_service_screen.dart`)
   - Enable/disable toggle
   - Display phone number
   - Show subscription status
   - Call logs list
   - Analytics dashboard

2. **Call Detail Screen** (`call_detail_screen.dart`)
   - Full transcript
   - Call summary
   - CSAT score
   - Customer info
   - Duration and cost

**Services to Create**:
- `lib/services/vapi_service.dart` - API calls to Cloud Functions
- `lib/models/call_log.dart` - Call log data model
- `lib/models/ai_config.dart` - AI configuration model

**Providers to Create**:
- `lib/providers/ai_service_provider.dart` - State management

---

### Task 6: Testing
**Goal**: Verify end-to-end functionality

**Test Cases**:
1. Enable AI service for test store
2. Make test call to assigned number
3. Verify webhook receives call data
4. Check call log saved correctly
5. Verify push notification sent
6. View call logs in Flutter app
7. Test disable AI service

---

## Detailed Task Breakdown

### TASK 1: Setup VAPI Configuration

**1.1 Create Setup Script**
```typescript
// functions/src/scripts/setupVapiConfig.ts
import * as admin from "firebase-admin";

admin.initializeApp();

async function setupVapiConfig() {
  await admin.firestore().collection("config").doc("vapi").set({
    structuredOutputIds: [
      "a356b2a9-fecc-49da-9220-85b5d315e2db",  // Call Summary
      "01b9a819-68cb-41d6-b626-4426af1e89bb"   // CSAT
    ],
    sipCredentialId: "25718c8b-4388-4b59-ad0c-e2c7b8ea2147",
    voiceId: "GDzHdQOi6jjf8zaXhCYD",
    voiceModel: "eleven_turbo_v2_5",
    llmModel: "gpt-4o-mini",
    subscriptionPlan: {
      name: "ai_basic",
      monthlyFee: 20,  // USD
      currency: "USD",
      minutesIncluded: 100,
      costPerMinute: 0.20  // Internal tracking
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  console.log("✅ VAPI config created");
}

setupVapiConfig().then(() => process.exit(0));
```

**1.2 Create DID Population Script**
```typescript
// functions/src/scripts/populateDids.ts
import * as admin from "firebase-admin";

admin.initializeApp();

// Add your available DIDs here
const availableDids = [
  "+256205479710",
  // Add more numbers as you get them
];

async function populateDids() {
  const batch = admin.firestore().batch();
  
  for (const phoneNumber of availableDids) {
    const didRef = admin.firestore().collection("dids").doc();
    batch.set(didRef, {
      phoneNumber: phoneNumber,
      assigned: false,
      storeId: null,
      vapiPhoneNumberId: null,
      assignedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  await batch.commit();
  console.log(`✅ Added ${availableDids.length} DIDs`);
}

populateDids().then(() => process.exit(0));
```

**Run Commands**:
```bash
cd functions
npm run build
node lib/scripts/setupVapiConfig.js
node lib/scripts/populateDids.js
```

---

### TASK 2: Implement Cloud Functions

**2.1 VAPI Client Wrapper**
```typescript
// functions/src/vapi/vapiClient.ts
import axios from "axios";

const VAPI_BASE_URL = "https://api.vapi.ai";

export class VapiClient {
  private apiKey: string;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async createAssistant(config: any) {
    const response = await axios.post(
      `${VAPI_BASE_URL}/assistant`,
      config,
      { headers: { Authorization: `Bearer ${this.apiKey}` } }
    );
    return response.data;
  }

  async createPhoneNumber(config: any) {
    const response = await axios.post(
      `${VAPI_BASE_URL}/phone-number`,
      config,
      { headers: { Authorization: `Bearer ${this.apiKey}` } }
    );
    return response.data;
  }

  async deleteAssistant(assistantId: string) {
    await axios.delete(
      `${VAPI_BASE_URL}/assistant/${assistantId}`,
      { headers: { Authorization: `Bearer ${this.apiKey}` } }
    );
  }

  async deletePhoneNumber(phoneNumberId: string) {
    await axios.delete(
      `${VAPI_BASE_URL}/phone-number/${phoneNumberId}`,
      { headers: { Authorization: `Bearer ${this.apiKey}` } }
    );
  }
}
```

**2.2 Enable AI Service Function**
```typescript
// functions/src/vapi/enableAIService.ts
import {onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {VapiClient} from "./vapiClient";

const vapiPrivateKey = defineSecret("VAPI_PRIVATE_KEY");

export const enableAIService = onCall(
  {secrets: [vapiPrivateKey]},
  async (request) => {
    if (!request.auth) {
      throw new Error("Must be authenticated");
    }

    const {storeId} = request.data;

    // 1. Get store data
    const storeDoc = await admin.firestore()
      .collection("stores")
      .doc(storeId)
      .get();

    if (!storeDoc.exists) {
      throw new Error("Store not found");
    }

    const storeData = storeDoc.data()!;
    const storeName = storeData.name || storeData.storeName;

    // 2. Get VAPI config
    const vapiConfigDoc = await admin.firestore()
      .collection("config")
      .doc("vapi")
      .get();

    const vapiConfig = vapiConfigDoc.data()!;

    // 3. Assign DID
    const didsSnapshot = await admin.firestore()
      .collection("dids")
      .where("assigned", "==", false)
      .limit(1)
      .get();

    if (didsSnapshot.empty) {
      throw new Error("No available phone numbers");
    }

    const didDoc = didsSnapshot.docs[0];
    const didData = didDoc.data();
    const phoneNumber = didData.phoneNumber;

    // 4. Create VAPI assistant
    const vapiClient = new VapiClient(vapiPrivateKey.value());

    const assistant = await vapiClient.createAssistant({
      name: `Riley - ${storeName}`,
      voice: {
        model: vapiConfig.voiceModel,
        voiceId: vapiConfig.voiceId,
        provider: "11labs",
        stability: 0.5,
        similarityBoost: 0.75,
        fallbackPlan: {
          voices: [{
            model: "eleven_turbo_v2_5",
            voiceId: "TcAStCk0faGcHdNIFX23",
            provider: "11labs",
            stability: 0.5,
            similarityBoost: 0.75
          }]
        }
      },
      model: {
        model: vapiConfig.llmModel,
        provider: "openai",
        maxTokens: 2500,
        temperature: 0.3,
        messages: [{
          role: "system",
          content: `[Identity]
You are Riley, the customer care assistant for ${storeName}, the physical and online retail store...
[Full prompt from sample]`
        }]
      },
      firstMessage: `Thank you for calling Riley from ${storeName}. How may I help you?`,
      voicemailMessage: "Hey, can you please callback, Thanks!",
      endCallMessage: "Goodbye.",
      endCallFunctionEnabled: true,
      transcriber: {
        model: "nova-3",
        language: "en",
        provider: "deepgram",
        endpointing: 150,
        fallbackPlan: {
          transcribers: [{
            model: "flux-general-en",
            language: "en",
            provider: "deepgram"
          }]
        }
      },
      maxDurationSeconds: 300,
      artifactPlan: {
        recordingEnabled: false,
        structuredOutputIds: vapiConfig.structuredOutputIds
      },
      // ... rest of config
    });

    // 5. Create phone number
    const phoneNumberObj = await vapiClient.createPhoneNumber({
      provider: "byo-phone-number",
      number: phoneNumber,
      assistantId: assistant.id,
      credentialId: vapiConfig.sipCredentialId,
      name: `${storeName} Main Line`,
      numberE164CheckEnabled: false,
      server: {
        url: "https://africa-south1-purlstores-za.cloudfunctions.net/vapiWebhook",
        timeoutSeconds: 20
      }
    });

    // 6. Update DID
    await didDoc.ref.update({
      assigned: true,
      storeId: storeId,
      vapiPhoneNumberId: phoneNumberObj.id,
      assignedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 7. Save config
    await admin.firestore()
      .collection("stores")
      .doc(storeId)
      .collection("aiAssistant")
      .doc("config")
      .set({
        enabled: true,
        vapiAssistantId: assistant.id,
        vapiPhoneNumberId: phoneNumberObj.id,
        didId: didDoc.id,
        phoneNumber: phoneNumber,
        storeName: storeName,
        subscription: {
          plan: "ai_basic",
          monthlyFee: 20,
          currency: "USD",
          status: "active",
          startDate: admin.firestore.FieldValue.serverTimestamp(),
          minutesIncluded: 100,
          usedMinutes: 0
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

    return {
      success: true,
      phoneNumber: phoneNumber,
      assistantId: assistant.id
    };
  }
);
```

**2.3 Webhook Handler**
```typescript
// functions/src/vapi/vapiWebhook.ts
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const vapiWebhook = onRequest(async (req, res) => {
  const event = req.body;

  console.log(`📞 VAPI Webhook: ${event.type}`);

  if (event.type === "end-of-call-report") {
    const call = event.call;

    // Find store by phone number
    const didsSnapshot = await admin.firestore()
      .collection("dids")
      .where("phoneNumber", "==", call.phoneNumber.number)
      .limit(1)
      .get();

    if (didsSnapshot.empty) {
      console.error("Store not found for phone:", call.phoneNumber.number);
      return res.status(404).send({error: "Store not found"});
    }

    const storeId = didsSnapshot.docs[0].data().storeId;

    // Extract structured data
    const artifact = call.artifact || {};
    const structuredOutputs = artifact.structuredOutputs || [];
    
    let callSummary = "";
    let csatScore = null;
    
    for (const output of structuredOutputs) {
      if (output.id === "a356b2a9-fecc-49da-9220-85b5d315e2db") {
        callSummary = output.result || "";
      }
      if (output.id === "01b9a819-68cb-41d6-b626-4426af1e89bb") {
        csatScore = output.result;
      }
    }

    // Calculate duration in seconds
    const duration = Math.floor(
      (new Date(call.endedAt).getTime() - new Date(call.startedAt).getTime()) / 1000
    );

    // Save call log
    await admin.firestore()
      .collection("stores")
      .doc(storeId)
      .collection("aiAssistant")
      .collection("callLogs")
      .doc(call.id)
      .set({
        callId: call.id,
        customerPhone: call.customer?.number || "Unknown",
        duration: duration,
        transcript: call.transcript || "",
        summary: callSummary,
        csatScore: csatScore,
        cost: call.cost || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

    // Update usage minutes
    const minutes = Math.ceil(duration / 60);
    await admin.firestore()
      .collection("stores")
      .doc(storeId)
      .collection("aiAssistant")
      .doc("config")
      .update({
        "subscription.usedMinutes": admin.firestore.FieldValue.increment(minutes)
      });

    // Send notification to store staff
    const storeDoc = await admin.firestore()
      .collection("stores")
      .doc(storeId)
      .get();

    const authorizedUsers = storeDoc.data()?.authorizedUsers || [];
    const storeName = storeDoc.data()?.name || "Your store";

    for (const userId of authorizedUsers) {
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (userDoc.exists) {
        const fcmTokens = userDoc.data()?.fcmTokens || [];
        
        for (const token of fcmTokens) {
          try {
            await admin.messaging().send({
              token,
              notification: {
                title: "📞 New Customer Call",
                body: callSummary || `Call from ${call.customer?.number || "customer"}`
              },
              data: {
                type: "ai_call",
                callId: call.id,
                storeId: storeId
              }
            });
          } catch (error) {
            console.error("Error sending notification:", error);
          }
        }
      }
    }

    return res.status(200).send({success: true});
  }

  return res.status(200).send({success: true});
});
```

**2.4 Get Call Logs Function**
```typescript
// functions/src/vapi/getCallLogs.ts
import {onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const getCallLogs = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Must be authenticated");
  }

  const {storeId, limit = 20} = request.data;

  const logsSnapshot = await admin.firestore()
    .collection("stores")
    .doc(storeId)
    .collection("aiAssistant")
    .collection("callLogs")
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return logsSnapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
});
```

---

### TASK 3: Store Secrets

**Commands**:
```bash
firebase functions:secrets:set VAPI_PRIVATE_KEY
# Enter: 0b2ef112-f947-4a36-a520-083bc5902771

firebase functions:secrets:set VAPI_PUBLIC_KEY
# Enter: fc915f5b-fdb2-41fb-a601-c6ed2ea1072d
```

---

### TASK 4: Update Indexes

**Add to `firestore.indexes.json`**:
```json
{
  "collectionGroup": "dids",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "assigned", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
},
{
  "collectionGroup": "callLogs",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

---

### TASK 5: Flutter Integration

**5.1 VAPI Service**
```dart
// lib/services/vapi_service.dart
class VapiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> enableAIService(String storeId) async {
    final result = await _functions
        .httpsCallable('enableAIService')
        .call({'storeId': storeId});
    return Map<String, dynamic>.from(result.data);
  }

  Future<List<CallLog>> getCallLogs(String storeId) async {
    final result = await _functions
        .httpsCallable('getCallLogs')
        .call({'storeId': storeId});
    
    return (result.data as List)
        .map((e) => CallLog.fromMap(e))
        .toList();
  }
}
```

**5.2 AI Customer Service Screen**
```dart
// lib/screens/ai_customer_service_screen.dart
class AICustomerServiceScreen extends StatefulWidget {
  final String storeId;
  
  @override
  _AICustomerServiceScreenState createState() => _AICustomerServiceScreenState();
}

class _AICustomerServiceScreenState extends State<AICustomerServiceScreen> {
  // UI implementation
  // - Enable/disable toggle
  // - Phone number display
  // - Call logs list
  // - Analytics
}
```

---

### TASK 6: Testing Checklist

- [ ] Run setup scripts
- [ ] Deploy Cloud Functions
- [ ] Test enableAIService with test store
- [ ] Make test call
- [ ] Verify webhook receives data
- [ ] Check call log in Firestore
- [ ] Verify push notification
- [ ] Test Flutter UI

---

## Execution Order

1. **Task 1** - Setup config (15 min)
2. **Task 3** - Store secrets (5 min)
3. **Task 2** - Implement functions (2 hours)
4. **Task 4** - Update indexes (5 min)
5. Deploy functions (10 min)
6. **Task 5** - Flutter UI (1 hour)
7. **Task 6** - Testing (30 min)

**Total Estimated Time**: 4-5 hours

---

**Ready to start?** Let me know and we'll go task by task!
