# VAPI Implementation Notes - POP Platform

**Date**: February 22, 2026  
**Status**: Research & Planning

---

## Current Understanding

### Your Setup:

1. **SIP Trunk**: Already configured with local Uganda provider
2. **DIDs**: 10 Uganda phone numbers in Firestore (can get more)
3. **VAPI Account**: Active with API keys
4. **Goal**: One AI assistant per store with dedicated phone number

---

## VAPI Key Concepts

### 1. Assistant
- The AI agent configuration
- Contains: model, voice, system prompt, analysis plan
- Has unique `assistantId`

### 2. Phone Number
- DID (Direct Inward Dialing number)
- Has unique `phoneNumberId`
- Linked to an assistant via `assistantId`
- Provider: "byo-phone-number" (bring your own via SIP)

### 3. Structured Output
- Post-call data extraction
- Defined in `analysisPlan.structuredDataPlan`
- Has unique `structuredOutputId`
- Extracts: summary, customer phone, issue status, etc.

---

## Data Flow Architecture

### Firestore Structure:

#### `/dids` Collection
```javascript
{
  didId: "uuid",
  phoneNumber: "+256700123456",
  assigned: false,
  storeId: null,
  vapiPhoneNumberId: null,  // Set after VAPI phone number created
  createdAt: timestamp
}
```

#### `/stores/{storeId}/aiAssistant` Document
```javascript
{
  enabled: true,
  
  // VAPI IDs
  vapiAssistantId: "assistant-uuid",
  vapiPhoneNumberId: "phone-uuid",
  vapiStructuredOutputId: "output-uuid",
  
  // Phone number
  didId: "firestore-did-uuid",
  phoneNumber: "+256700123456",
  
  // Configuration
  storeName: "Joe's Electronics",
  systemPrompt: "You are Riley, a customer care agent for {{storeName}}...",
  firstMessage: "Hi! This is Riley from {{storeName}}, how may I help you?",
  
  // Voice settings
  voice: {
    provider: "11labs",
    voiceId: "cVfw9PD2QL7pPiHl86gf",
    model: "eleven_turbo_v2_5"
  },
  
  // Model settings
  model: {
    provider: "openai",
    model: "gpt-4o-mini",
    temperature: 0.5
  },
  
  // Subscription
  subscription: {
    plan: "ai_basic",
    monthlyFee: 50000,  // UGX
    status: "active",
    startDate: timestamp,
    minutesIncluded: 1000,
    usedMinutes: 0
  },
  
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### `/stores/{storeId}/aiAssistant/callLogs/{callId}` Subcollection
```javascript
{
  callId: "vapi-call-uuid",
  customerPhone: "+256700999888",
  duration: 180,  // seconds
  transcript: "Full conversation...",
  structuredData: {
    summary: "Customer asked about order #123...",
    issue_status: "Resolved",
    phone_number: "+256700999888"
  },
  cost: 0.15,  // USD
  createdAt: timestamp
}
```

---

## Store Creation Flow

### When Seller Subscribes to AI Service:

```
1. Seller clicks "Enable AI Customer Service"
2. App checks subscription eligibility
3. App calls Cloud Function: enableAIService(storeId)

4. Cloud Function:
   a. Query Firestore for unassigned DID
   b. Pick random unassigned DID
   c. Create VAPI Assistant via API
   d. Create VAPI Phone Number (link DID to assistant)
   e. Create Structured Output schema
   f. Update Firestore:
      - Mark DID as assigned
      - Save assistant config to store
   g. Return phone number to app

5. App displays: "Your AI assistant is ready! Phone: +256700123456"
```

---

## VAPI API Calls (To Research)

### 1. Create Assistant
```http
POST https://api.vapi.ai/assistant
Headers:
  Authorization: Bearer {VAPI_PRIVATE_KEY}
Body:
{
  "name": "Riley - Joe's Electronics",
  "model": {
    "provider": "openai",
    "model": "gpt-4o-mini",
    "messages": [{
      "role": "system",
      "content": "You are Riley, customer care for Joe's Electronics..."
    }]
  },
  "voice": {
    "provider": "11labs",
    "voiceId": "cVfw9PD2QL7pPiHl86gf"
  },
  "firstMessage": "Hi! This is Riley from Joe's Electronics...",
  "analysisPlan": {
    "structuredDataPlan": {
      "enabled": true,
      "schema": {...}
    }
  }
}

Response:
{
  "id": "assistant-uuid",
  ...
}
```

### 2. Create/Link Phone Number
```http
POST https://api.vapi.ai/phone-number
Body:
{
  "provider": "byo-phone-number",
  "number": "+256700123456",
  "assistantId": "assistant-uuid",
  "credentialId": "sip-credential-uuid"
}

Response:
{
  "id": "phone-number-uuid",
  ...
}
```

### 3. Webhook for Call Events
```http
Webhook URL: https://us-central1-purlstores-za.cloudfunctions.net/vapiWebhook

Events:
- assistant-request: Provide dynamic context
- end-of-call-report: Save call log
```

---

## Template System Prompt

```
[Identity]
You are Riley, an AI customer care assistant for {{storeName}}.

[Role]
Your mission is to provide excellent customer service by:
- Answering questions about products and orders
- Helping customers track their orders
- Providing store information (hours, location, policies)
- Taking messages for the store owner

[Style]
- Be friendly, professional, and helpful
- Keep responses clear and concise
- Ask for customer's name and phone number
- If you can't help, offer to have the store owner call back

[Store Information]
Store Name: {{storeName}}
Store Hours: {{storeHours}}
Store Location: {{storeLocation}}
Store Phone: {{storePhone}}

[Common Tasks]
1. Order Status: Ask for order number, check status
2. Product Questions: Provide information from product catalog
3. Store Hours: Share business hours
4. Callback Request: Collect name and phone number

[Response Guidelines]
- Always greet with: "Hi! This is Riley from {{storeName}}, how may I help you?"
- Keep responses under 30 words when possible
- If customer wants to speak to owner, say: "I'll have the owner call you back. May I have your name and phone number?"
- End with: "Thank you for calling {{storeName}}! Have a great day!"
```

---

## Structured Output Schema

```json
{
  "type": "object",
  "required": ["summary", "customer_phone", "issue_status", "intent"],
  "properties": {
    "summary": {
      "type": "string",
      "description": "Brief summary of the call"
    },
    "customer_phone": {
      "type": "string",
      "description": "Customer's phone number"
    },
    "customer_name": {
      "type": "string",
      "description": "Customer's name if provided"
    },
    "issue_status": {
      "type": "string",
      "enum": ["Resolved", "Callback Requested", "Unresolved"]
    },
    "intent": {
      "type": "string",
      "enum": ["order_inquiry", "product_question", "store_hours", "complaint", "other"]
    },
    "order_number": {
      "type": "string",
      "description": "Order number if mentioned"
    }
  }
}
```

---

## Next Steps

1. **Waiting for your example** to see actual VAPI assistant structure
2. **Research VAPI API** for:
   - Creating assistants
   - Linking phone numbers
   - Structured output IDs
3. **Design Cloud Functions**
4. **Build Flutter UI**

---

**Status**: Awaiting your example assistant configuration
