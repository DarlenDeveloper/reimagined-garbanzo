# VAPI Efficient Implementation Flow - POP Platform

**Date**: February 22, 2026  
**Status**: Implementation Ready

---

## Optimal Flow Based on VAPI Documentation

### Key Insights from VAPI Docs:

1. **Structured Outputs are separate entities** - Created independently and linked to assistants via `structuredOutputIds`
2. **Phone numbers link to assistants** - via `assistantId` field
3. **BYO Phone Numbers** - Use `provider: "byo-phone-number"` with your SIP trunk
4. **Webhooks for dynamic context** - Set `assistantId: null` and use `serverUrl` for per-call customization
5. **Call logs include structured data** - Automatically available after call ends

### Your Actual Setup:

- **One SIP Credential ID** - Shared across all stores
- **One DID per store** - Each store gets dedicated phone number
- **Same LLM** - gpt-4o-mini for all stores
- **Same Voice** - Riley (11labs voice ID: GDzHdQOi6jjf8zaXhCYD)
- **Same VAPI Key** - One organization account
- **Two Structured Outputs** - Already created:
  - `a356b2a9-fecc-49da-9220-85b5d315e2db`
  - `01b9a819-68cb-41d6-b626-4426af1e89bb`

---

## Recommended Implementation Flow

### Phase 1: One-Time Setup (Already Done ✓)

#### 1.1 Structured Outputs (Already Created)
You already have two structured outputs:
- `a356b2a9-fecc-49da-9220-85b5d315e2db`
- `01b9a819-68cb-41d6-b626-4426af1e89bb`

**Store in Firestore:**
```javascript
/config/vapi {
  structuredOutputIds: [
    "a356b2a9-fecc-49da-9220-85b5d315e2db",
    "01b9a819-68cb-41d6-b626-4426af1e89bb"
  ],
  sipCredentialId: "YOUR_SIP_CREDENTIAL_ID",  // Get from VAPI dashboard
  voiceId: "GDzHdQOi6jjf8zaXhCYD",  // Riley voice
  voiceModel: "eleven_turbo_v2_5",
  llmModel: "gpt-4o-mini",
  createdAt: timestamp
}
```

---

### Phase 2: Per-Store Setup (When Seller Subscribes)

#### 2.1 Assign DID from Pool
```typescript
// Query Firestore for unassigned DID
const did = await db.collection('dids')
  .where('assigned', '==', false)
  .limit(1)
  .get();

// Mark as assigned
await db.collection('dids').doc(did.id).update({
  assigned: true,
  storeId: storeId,
  assignedAt: FieldValue.serverTimestamp()
});
```

#### 2.2 Create VAPI Assistant (Store-Specific)
```typescript
POST https://api.vapi.ai/assistant
Headers: {
  Authorization: Bearer VAPI_PRIVATE_KEY
}
Body: {
  name: `Riley - ${storeName}`,
  voice: {
    model: "eleven_turbo_v2_5",
    voiceId: "GDzHdQOi6jjf8zaXhCYD",  // Riley voice
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
    model: "gpt-4o-mini",
    provider: "openai",
    maxTokens: 2500,
    temperature: 0.3,
    messages: [{
      role: "system",
      content: `[Identity]
You are Riley, the customer care assistant for ${storeName}, the physical and online retail store. Your sole focus is assisting ${storeName} customers with any questions or issues related to in-store services, purchases, or orders made through the POP app. You help with questions about orders, in-store purchases, resolving missing or delayed store orders or deliveries, general inquiries about ${storeName} retail operations, collecting troubleshooting information, and providing support or next steps for ${storeName} shoppers. You do not have the ability to look up or access specific order information.

[Style]
- Sound upbeat, approachable, and professional at all times.
- Use clear, simple, and personable language.
- Employ natural conversational elements like, "Let me check that for you," or "Just a moment while I help you out."
- Sparingly add brief, natural hesitations ("um," "let's see," short pause) to enhance human-like delivery.
- Avoid jargon or technical terms unless necessary; offer quick explanations if they do arise.

[Response Guidelines]
- Confirm and repeat order numbers, item names, and addresses clearly, spelling out details if needed.
- Present instructions or questions one at a time, always waiting for the customer's response before moving forward.
- Keep responses concise and focused—ask one question or provide one instruction at a time.
- Use gentle affirmations ("Got it," "Thank you," "Perfect") to acknowledge customer input.
- Clearly enunciate numbers or support codes, speaking digits slowly and carefully.
- Never mention tool names, apps, or internal processes to customers.

[Task & Goals]
1. Greet the customer, introducing yourself as Riley from ${storeName} customer care. Example: "Hi! This is Riley, your ${storeName} customer care assistant. How can I help you today?"
2. Listen for the customer's needs—such as questions about in-store purchases, order confirmation, delivery, missing or delayed store orders, wrong items, product returns, or general store policies.
3. If a customer needs help with an order, delivery, or return:
   a. Kindly ask for their ${storeName} order number and clearly emphasize the need for the name on the order as well.
   <wait for customer response>
   b. Explain that, at this time, you are unable to look up specific order details yourself but can still guide them on what to do next or connect them with a team member who can help.
   c. For problems with delivery (e.g., delayed, missing, damaged, or wrong items):
      - Ask the customer to describe the issue and confirm all relevant details, such as delivery address and items.
      - Let the customer know you can provide general support steps and offer to connect them to a human representative for specific issues.
   d. For returns or cancellations:
      - Ask for their order details and the reason for return or cancellation.
      - Provide high-level instructions on the ${storeName} return/cancellation policy and suggest visiting the store or contacting support directly. Offer to connect them to a human representative if needed.
4. For any questions about ${storeName} store policies, hours, locations, or general information, answer clearly and directly.
5. Always wait for the customer's reply before moving to the next step.
6. If an issue cannot be resolved (invalid info, unresolved problems, or anything requiring account/order lookup), offer to escalate to human support. If escalation is needed, do not say anything to the customer; silently trigger the transfer tool.
7. When an issue is addressed, briefly summarize support provided and ask if the customer needs anything else.

[Error Handling / Fallback]
- If customer input is unclear, politely ask for clarification.
- If an order cannot be found or a situation is beyond your abilities, apologize, state the limitation, and offer to connect them with a human agent if needed.
- Ask explicit questions to fill in any missing details; never assume information.
- If you need to escalate to live support, do not say anything aloud—just trigger the transfer tool silently.
- If the customer is silent or seems lost, offer help and suggest connecting them with a live representative if needed.

[Call Closing]
- Confirm that all questions or issues are resolved before ending the call.
- End with a warm thank you: "Thank you for shopping with ${storeName}. Have a wonderful day!"`
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
  clientMessages: [
    "conversation-update",
    "function-call",
    "hang",
    "model-output",
    "speech-update",
    "status-update",
    "transfer-update",
    "transcript",
    "tool-calls",
    "user-interrupted",
    "voice-input",
    "workflow.node.started",
    "assistant.started"
  ],
  serverMessages: [
    "conversation-update",
    "end-of-call-report",
    "function-call",
    "hang",
    "speech-update",
    "status-update",
    "tool-calls",
    "transfer-destination-request",
    "handoff-destination-request",
    "user-interrupted",
    "assistant.started"
  ],
  endCallPhrases: ["goodbye", "talk to you soon"],
  hipaaEnabled: false,
  maxDurationSeconds: 300,  // 5 minutes
  analysisPlan: {
    summaryPlan: { enabled: false },
    successEvaluationPlan: { enabled: false }
  },
  artifactPlan: {
    recordingEnabled: false,
    structuredOutputIds: [
      "a356b2a9-fecc-49da-9220-85b5d315e2db",
      "01b9a819-68cb-41d6-b626-4426af1e89bb"
    ]
  },
  messagePlan: {
    idleMessages: ["Are you still there?"]
  },
  startSpeakingPlan: {
    waitSeconds: 0.4,
    smartEndpointingEnabled: "livekit"
  },
  compliancePlan: {
    hipaaEnabled: false,
    pciEnabled: false
  }
}

Response: {
  id: "assistant-abc123"
}
```

#### 2.3 Create VAPI Phone Number (Link DID to Assistant)
```typescript
POST https://api.vapi.ai/phone-number
Headers: {
  Authorization: Bearer VAPI_PRIVATE_KEY
}
Body: {
  provider: "byo-phone-number",
  number: "+256700123456",  // From DID pool
  assistantId: "assistant-abc123",
  credentialId: "YOUR_SIP_CREDENTIAL_ID",  // Get from /config/vapi in Firestore
  name: `${storeName} Main Line`,
  numberE164CheckEnabled: true,
  server: {
    url: "https://us-central1-purlstores-za.cloudfunctions.net/vapiWebhook",
    timeoutSeconds: 20,
    backoffPlan: {
      type: "fixed",
      maxRetries: 3,
      baseDelaySeconds: 1,
      excludedStatusCodes: [400, 401, 403, 404]
    }
  }
}

Response: {
  id: "phone-number-xyz789"
}
```

#### 2.4 Save to Firestore
```typescript
await db.collection('stores').doc(storeId).collection('aiAssistant').doc('config').set({
  enabled: true,
  
  // VAPI IDs
  vapiAssistantId: "assistant-abc123",
  vapiPhoneNumberId: "phone-number-xyz789",
  
  // DID Info
  didId: did.id,
  phoneNumber: "+256700123456",
  
  // Store Context
  storeName: storeName,
  storeHours: storeHours,
  storeLocation: storeLocation,
  
  // Subscription
  subscription: {
    plan: "ai_basic",
    monthlyFee: 50000,
    status: "active",
    startDate: FieldValue.serverTimestamp(),
    minutesIncluded: 1000,
    usedMinutes: 0
  },
  
  createdAt: FieldValue.serverTimestamp()
});
```

---

### Phase 3: Runtime (Per Call)

#### 3.1 Incoming Call Flow
```
1. Customer calls +256700123456
2. SIP trunk routes to VAPI
3. VAPI finds phone number → gets assistantId
4. VAPI sends webhook to your server (optional for dynamic context)
5. Assistant handles call using stored configuration
6. Call ends
7. VAPI processes structured output
8. VAPI sends end-of-call-report webhook
9. Your server saves call log
```

#### 3.2 Webhook Handler (Cloud Function)
```typescript
export const vapiWebhook = onRequest(async (req, res) => {
  const event = req.body;
  
  // Event 1: Assistant Request (optional - for dynamic context)
  if (event.type === "assistant-request") {
    // You can provide dynamic context here if needed
    // For now, assistant has all context already
    return res.status(200).send({ success: true });
  }
  
  // Event 2: End of Call Report
  if (event.type === "end-of-call-report") {
    const { call } = event;
    
    // Extract structured data
    const structuredData = call.artifact?.structuredOutputs?.[0]?.result || {};
    
    // Find store by phone number
    const phoneQuery = await db.collection('dids')
      .where('phoneNumber', '==', call.phoneNumber.number)
      .limit(1)
      .get();
    
    if (phoneQuery.empty) {
      return res.status(404).send({ error: "Store not found" });
    }
    
    const storeId = phoneQuery.docs[0].data().storeId;
    
    // Save call log
    await db.collection('stores')
      .doc(storeId)
      .collection('aiAssistant')
      .collection('callLogs')
      .doc(call.id)
      .set({
        callId: call.id,
        customerPhone: call.customer?.number || structuredData.customer_phone,
        customerName: structuredData.customer_name,
        duration: call.endedAt - call.startedAt,  // milliseconds
        transcript: call.transcript,
        summary: structuredData.summary,
        intent: structuredData.intent,
        issueStatus: structuredData.issue_status,
        orderNumber: structuredData.order_number,
        productsMentioned: structuredData.products_mentioned,
        cost: call.cost,
        createdAt: FieldValue.serverTimestamp()
      });
    
    // Send notification to seller
    await sendPushNotification(storeId, {
      title: "New Customer Call",
      body: structuredData.summary,
      data: { callId: call.id }
    });
    
    return res.status(200).send({ success: true });
  }
  
  return res.status(400).send({ error: "Unknown event type" });
});
```

#### 3.3 Fetch Call Logs (Flutter App)
```typescript
// Cloud Function: getCallLogs
export const getCallLogs = onCall(async (request) => {
  const { storeId, limit = 20 } = request.data;
  
  const logsSnapshot = await db.collection('stores')
    .doc(storeId)
    .collection('aiAssistant')
    .collection('callLogs')
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();
  
  return logsSnapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
});
```

---

## API Endpoints Summary

### One-Time Setup (Already Done):
1. ✓ Structured outputs created
2. ✓ SIP credential configured
3. Need: Store SIP credential ID in Firestore `/config/vapi`

### Per Store:
1. `POST /assistant` - Create assistant with store-specific context
2. `POST /phone-number` - Link DID to assistant (using shared SIP credential)

### Runtime:
1. Webhook: `assistant-request` - Optional dynamic context
2. Webhook: `end-of-call-report` - Save call logs
3. `GET /call` - List calls (optional)
4. `GET /call/:id` - Get specific call with structured data

### Management:
1. `PATCH /assistant/:id` - Update assistant config
2. `DELETE /assistant/:id` - Delete assistant (when store unsubscribes)
3. `DELETE /phone-number/:id` - Remove phone number

---

## Firestore Structure (Final)

```
/config/vapi
  - structuredOutputIds: ["a356b2a9-fecc-49da-9220-85b5d315e2db", "01b9a819-68cb-41d6-b626-4426af1e89bb"]
  - sipCredentialId: "YOUR_SIP_CREDENTIAL_ID"
  - voiceId: "GDzHdQOi6jjf8zaXhCYD"
  - voiceModel: "eleven_turbo_v2_5"
  - llmModel: "gpt-4o-mini"
  - createdAt: timestamp

/dids/{didId}
  - phoneNumber: "+256700123456"
  - assigned: true
  - storeId: "store123"
  - vapiPhoneNumberId: "phone-xyz789"
  - assignedAt: timestamp
  - createdAt: timestamp

/stores/{storeId}/aiAssistant/config
  - enabled: true
  - vapiAssistantId: "assistant-abc123"
  - vapiPhoneNumberId: "phone-xyz789"
  - didId: "did-uuid"
  - phoneNumber: "+256700123456"
  - storeName: "Shop X"
  - storeHours: "9 AM - 6 PM"
  - storeLocation: "Kampala, Uganda"
  - subscription: {
      plan: "ai_basic",
      monthlyFee: 50000,
      status: "active",
      startDate: timestamp,
      minutesIncluded: 1000,
      usedMinutes: 0
    }
  - createdAt: timestamp
  - updatedAt: timestamp

/stores/{storeId}/aiAssistant/callLogs/{callId}
  - callId: "vapi-call-id"
  - customerPhone: "+256700999888"
  - customerName: "John Doe"
  - duration: 180  // seconds
  - transcript: "Full conversation..."
  - structuredData: {
      // Data from both structured outputs
      output1: {...},
      output2: {...}
    }
  - cost: 0.15  // USD
  - createdAt: timestamp
```

---

## Cost Optimization Tips

1. **Reuse structured output schema** - One schema for all stores
2. **Use gpt-4o-mini** - Cheaper than gpt-4, still great quality
3. **Set maxDurationSeconds** - Prevent long calls
4. **Cache common responses** - Store FAQ answers
5. **Monitor usage** - Track minutes per store

---

## Implementation Checklist

### Backend (Cloud Functions):
- [ ] Create global structured output schema
- [ ] Implement `enableAIService(storeId)` function
- [ ] Implement `vapiWebhook` handler
- [ ] Implement `getCallLogs(storeId)` function
- [ ] Implement `updateAssistantConfig(storeId, config)` function
- [ ] Set up VAPI API keys in Secret Manager

### Flutter (Seller App):
- [ ] Create `VapiService` class
- [ ] Build AI Customer Service screen UI
- [ ] Add enable/disable toggle
- [ ] Display assigned phone number
- [ ] Show call logs list
- [ ] Build analytics dashboard
- [ ] Add subscription check

### Testing:
- [ ] Test DID assignment
- [ ] Test assistant creation
- [ ] Make test call
- [ ] Verify webhook receives events
- [ ] Check call log saved correctly
- [ ] Test structured data extraction
- [ ] Verify push notifications

---

## Next Steps

1. Get VAPI API keys (public + private)
2. Get SIP credential ID from VAPI dashboard
3. Implement Cloud Functions
4. Test with one store
5. Build Flutter UI
6. Launch to beta testers

---

**Status**: Ready to implement
