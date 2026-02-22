# VAPI AI Customer Service - Architecture & Implementation Plan

**Last Updated**: February 22, 2026  
**Status**: Brainstorming & Planning

---

## Research Summary

### VAPI Overview
- **VAPI** = Voice AI Platform for building AI phone assistants
- Supports **phone calls** (inbound/outbound) and **SIP** integration
- Has official **Flutter SDK** (`vapi` package on pub.dev)
- Uses **GPT-4** or other LLMs for conversation
- Supports **11Labs**, **OpenAI TTS**, and other voice providers

### Key VAPI Concepts

1. **Assistants** - AI agents with defined behavior, voice, and prompts
2. **Phone Numbers (DIDs)** - Direct Inward Dialing numbers for receiving calls
3. **SIP Integration** - Connect via SIP trunks (Twilio, Telnyx, Plivo, etc.)
4. **Server Webhooks** - Backend receives call events and can customize behavior
5. **Template Variables** - Pass context (store name, products, etc.) to AI

---

## Architecture Options

### Option 1: VAPI-Managed Phone Numbers (Simplest)
**How it works:**
- VAPI provides free US phone numbers
- Sellers get a dedicated VAPI number for their store
- Buyers call this number → AI assistant answers
- No SIP configuration needed

**Pros:**
- Easiest to implement
- No telephony infrastructure needed
- VAPI handles all call routing
- Free US numbers included

**Cons:**
- Limited to US numbers (international costs extra)
- Dependent on VAPI's number availability
- Less control over telephony

---

### Option 2: SIP Trunk Integration (Most Flexible)
**How it works:**
- Use SIP provider (Twilio, Telnyx, Plivo, Zadarma)
- Purchase DIDs (phone numbers) from SIP provider
- Configure SIP trunk to route calls to VAPI
- VAPI AI assistant handles the call

**Pros:**
- International numbers available
- More control over telephony
- Can use existing phone infrastructure
- Better for scaling

**Cons:**
- More complex setup
- Requires SIP provider account
- Additional costs for DIDs and minutes
- Need backend configuration

---

### Option 3: Hybrid Approach (Recommended)
**How it works:**
- Start with VAPI-managed numbers (free tier)
- Allow premium sellers to bring their own numbers via SIP
- Backend manages both types

**Pros:**
- Easy onboarding (free VAPI numbers)
- Flexibility for premium users
- Scalable architecture
- Best of both worlds

**Cons:**
- More complex backend logic
- Need to handle two number types

---

## Recommended Architecture: Hybrid Approach

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     POP Seller App (Flutter)                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  AI Customer Service Screen                            │ │
│  │  - Enable/Disable AI                                   │ │
│  │  - View assigned phone number                          │ │
│  │  - Configure AI personality                            │ │
│  │  - View call logs & analytics                          │ │
│  │  - Subscription check (Pro/Business only)              │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
                    (API Calls via HTTP)
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│              Firebase Cloud Functions (Backend)              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  VAPI Service Functions:                               │ │
│  │  1. createVapiAssistant() - Create AI for store       │ │
│  │  2. assignPhoneNumber() - Get/assign DID              │ │
│  │  3. updateAssistantConfig() - Update AI settings      │ │
│  │  4. handleCallWebhook() - Receive call events         │ │
│  │  5. getCallLogs() - Fetch call history                │ │
│  │  6. getCallAnalytics() - Generate analytics           │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
                    (VAPI REST API)
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                      VAPI Platform                           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  - AI Assistants (GPT-4 + Voice)                      │ │
│  │  - Phone Numbers (DIDs)                               │ │
│  │  - SIP Integration                                    │ │
│  │  - Call Routing                                       │ │
│  │  - Transcription & Analytics                          │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
                    (Phone/SIP Calls)
                            ↓ ↑
                      ┌──────────┐
                      │ Customers│
                      │ (Buyers) │
                      └──────────┘
```

---

## Data Flow

### 1. Seller Enables AI Customer Service

```
1. Seller opens AI Customer Service screen
2. App checks subscription (must be Pro or Business)
3. Seller clicks "Enable AI Customer Service"
4. App calls Cloud Function: createVapiAssistant()
5. Cloud Function:
   a. Creates VAPI assistant with store context
   b. Assigns/creates phone number (DID)
   c. Saves config to Firestore
6. App displays phone number to seller
7. Seller can share number with customers
```

### 2. Customer Calls Store

```
1. Customer dials store's AI phone number
2. Call routes to VAPI
3. VAPI triggers webhook to Cloud Function
4. Cloud Function:
   a. Fetches store data from Firestore
   b. Fetches product catalog
   c. Returns context to VAPI
5. VAPI AI assistant answers call with context
6. AI handles conversation:
   - Answers product questions
   - Provides store hours/location
   - Takes orders (optional)
   - Transfers to seller if needed
7. Call ends
8. VAPI sends call summary to webhook
9. Cloud Function saves call log to Firestore
10. Seller sees call in analytics
```

### 3. Seller Views Analytics

```
1. Seller opens AI Customer Service screen
2. App fetches call logs from Firestore
3. Displays:
   - Total calls
   - Average call duration
   - Common questions
   - Call transcripts
   - Customer satisfaction
```

---

## Firestore Data Structure

### `/stores/{storeId}/aiCustomerService`
```javascript
{
  enabled: boolean,
  vapiAssistantId: string,
  phoneNumber: string,  // DID assigned
  phoneNumberType: "vapi" | "sip",
  sipConfig: {  // Only if using SIP
    provider: "twilio" | "telnyx" | "plivo",
    sipUri: string,
    credentials: {...}
  },
  aiConfig: {
    model: "gpt-4",
    voice: "11labs-burt",
    personality: "friendly",
    firstMessage: "Hello! Thanks for calling {{storeName}}...",
    systemPrompt: "You are a helpful assistant for {{storeName}}...",
    maxCallDuration: 300,  // 5 minutes
    transferEnabled: boolean,
    transferNumber: string  // Seller's phone
  },
  subscription: {
    plan: "pro" | "business",
    monthlyMinutes: 1000,
    usedMinutes: 245,
    costPerMinute: 0.05
  },
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### `/stores/{storeId}/aiCustomerService/callLogs/{callId}`
```javascript
{
  callId: string,
  phoneNumber: string,  // Caller's number
  duration: number,  // seconds
  transcript: string,
  summary: string,
  intent: "product_inquiry" | "order" | "support" | "hours",
  sentiment: "positive" | "neutral" | "negative",
  transferred: boolean,
  cost: number,
  createdAt: timestamp
}
```

---

## Cloud Functions to Implement

### 1. `createVapiAssistant`
**Trigger**: Callable (from Flutter app)  
**Purpose**: Create VAPI assistant and assign phone number

```typescript
export const createVapiAssistant = onCall(async (request) => {
  // 1. Check subscription (Pro/Business only)
  // 2. Fetch store data
  // 3. Create VAPI assistant via API
  // 4. Assign/create phone number
  // 5. Save config to Firestore
  // 6. Return phone number to app
});
```

### 2. `updateVapiAssistant`
**Trigger**: Callable  
**Purpose**: Update AI configuration

```typescript
export const updateVapiAssistant = onCall(async (request) => {
  // 1. Validate request
  // 2. Update VAPI assistant via API
  // 3. Update Firestore config
});
```

### 3. `handleVapiWebhook`
**Trigger**: HTTPS (webhook from VAPI)  
**Purpose**: Receive call events and provide context

```typescript
export const handleVapiWebhook = onRequest(async (req, res) => {
  const event = req.body;
  
  if (event.type === "assistant-request") {
    // Provide store context to VAPI
    const storeData = await getStoreData(event.phoneNumberId);
    const products = await getProducts(storeData.storeId);
    
    return res.json({
      assistant: {
        model: { provider: "openai", model: "gpt-4" },
        voice: { provider: "11labs", voiceId: "burt" },
        firstMessage: `Hello! Thanks for calling ${storeData.name}...`,
        variableValues: {
          storeName: storeData.name,
          storeHours: storeData.hours,
          topProducts: products.slice(0, 5)
        }
      }
    });
  }
  
  if (event.type === "end-of-call-report") {
    // Save call log
    await saveCallLog(event);
  }
});
```

### 4. `getCallLogs`
**Trigger**: Callable  
**Purpose**: Fetch call history for seller

### 5. `getCallAnalytics`
**Trigger**: Callable  
**Purpose**: Generate analytics dashboard data

---

## Flutter Implementation

### 1. Add VAPI Package
```yaml
# pubspec.yaml
dependencies:
  vapi: ^latest_version
```

### 2. Create VAPI Service
```dart
// lib/services/vapi_service.dart
class VapiService {
  final CloudFunctions _functions = CloudFunctions.instance;
  
  Future<Map<String, dynamic>> enableAI(String storeId) async {
    final result = await _functions
        .httpsCallable('createVapiAssistant')
        .call({'storeId': storeId});
    return result.data;
  }
  
  Future<void> updateAIConfig(String storeId, Map<String, dynamic> config) async {
    await _functions
        .httpsCallable('updateVapiAssistant')
        .call({'storeId': storeId, 'config': config});
  }
  
  Future<List<Map<String, dynamic>>> getCallLogs(String storeId) async {
    final result = await _functions
        .httpsCallable('getCallLogs')
        .call({'storeId': storeId});
    return List<Map<String, dynamic>>.from(result.data);
  }
}
```

### 3. Create AI Customer Service Screen
```dart
// lib/screens/ai_customer_service_screen.dart
class AICustomerServiceScreen extends StatefulWidget {
  // UI with:
  // - Enable/Disable toggle
  // - Phone number display
  // - Configuration options
  // - Call logs list
  // - Analytics dashboard
}
```

---

## Subscription & Pricing

### Monthly Subscription Tiers

**Pro Plan** ($9.99/month):
- 1,000 minutes included
- $0.05 per additional minute
- VAPI-managed US number
- Basic analytics

**Business Plan** ($24.99/month):
- 5,000 minutes included
- $0.03 per additional minute
- Bring your own number (SIP)
- Advanced analytics
- Priority support

---

## Implementation Steps

### Phase 1: Backend Setup (Day 1)
1. Create VAPI account and get API keys
2. Store keys in Firebase Secret Manager
3. Implement Cloud Functions:
   - createVapiAssistant
   - handleVapiWebhook
   - getCallLogs
4. Test with Postman/cURL

### Phase 2: Flutter Integration (Day 2)
1. Add vapi package to pubspec.yaml
2. Create VapiService class
3. Build AI Customer Service screen UI
4. Implement enable/disable functionality
5. Display phone number

### Phase 3: Configuration & Analytics (Day 3)
1. Add AI configuration options
2. Implement call logs display
3. Build analytics dashboard
4. Add subscription checks

### Phase 4: Testing & Polish (Day 4)
1. Test end-to-end flow
2. Test with real phone calls
3. Verify analytics accuracy
4. Polish UI/UX

---

## Questions to Answer

1. **VAPI Account**: Do you have a VAPI account? Need to create one at vapi.ai
2. **API Keys**: Will need VAPI Public Key and Private Key
3. **Phone Numbers**: Start with free VAPI US numbers or need international?
4. **AI Personality**: What should the AI assistant say/do?
5. **Call Handling**: Should AI take orders or just answer questions?
6. **Transfer**: Should AI be able to transfer calls to seller's phone?
7. **Subscription**: Confirm pricing tiers for AI service

---

## Next Steps

1. Create VAPI account
2. Get API keys
3. Decide on architecture (recommend Hybrid)
4. Define AI assistant behavior/prompts
5. Start implementation

---

**Status**: Ready to proceed once questions are answered
