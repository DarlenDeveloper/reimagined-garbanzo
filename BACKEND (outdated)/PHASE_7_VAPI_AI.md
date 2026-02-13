# Phase 7: AI Customer Service - Vapi Integration

## Overview

Integrate Vapi API for AI-powered customer service features available to premium vendors. Vapi provides voice AI and conversational AI capabilities.

## Vapi Configuration

### Environment Setup

```typescript
// Environment variables
VAPI_API_KEY=your_vapi_api_key
VAPI_ASSISTANT_ID=your_assistant_id
VAPI_PHONE_NUMBER_ID=your_phone_number_id
VAPI_WEBHOOK_URL=https://your-domain.com/api/vapi/webhook
```

### Premium Feature Access

```typescript
// Check if vendor has premium access
async function hasPremiumAccess(vendorId: string): Promise<boolean> {
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const vendorData = vendor.data();
  
  return vendorData.subscriptionTier === 'premium' && 
         vendorData.subscriptionExpiresAt?.toDate() > new Date();
}
```

## Vapi API Integration

### Create Assistant for Vendor

```typescript
// functions/src/ai/createAssistant.ts
import axios from 'axios';

const VAPI_API = 'https://api.vapi.ai';

interface AssistantConfig {
  vendorId: string;
  storeName: string;
  storeDescription: string;
  faqData: Array<{ question: string; answer: string }>;
}

async function createVapiAssistant(config: AssistantConfig): Promise<string> {
  const response = await axios.post(
    `${VAPI_API}/assistant`,
    {
      name: `${config.storeName} Assistant`,
      model: {
        provider: 'openai',
        model: 'gpt-4',
        systemPrompt: buildSystemPrompt(config)
      },
      voice: {
        provider: '11labs',
        voiceId: 'rachel'
      },
      firstMessage: `Hello! Welcome to ${config.storeName}. How can I help you today?`,
      endCallMessage: 'Thank you for contacting us. Have a great day!'
    },
    {
      headers: {
        'Authorization': `Bearer ${process.env.VAPI_API_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  return response.data.id;
}


function buildSystemPrompt(config: AssistantConfig): string {
  return `You are a helpful customer service assistant for ${config.storeName}.

Store Description: ${config.storeDescription}

Your responsibilities:
1. Answer customer questions about products and services
2. Help with order inquiries
3. Provide store information (hours, location, policies)
4. Escalate complex issues to human support

FAQ Knowledge:
${config.faqData.map(faq => `Q: ${faq.question}\nA: ${faq.answer}`).join('\n\n')}

Guidelines:
- Be friendly and professional
- Keep responses concise
- If you don't know something, offer to connect with human support
- Never make up information about products or prices`;
}
```

### Generate AI Response Suggestions

```typescript
// functions/src/ai/generateSuggestion.ts
export const generateAISuggestion = functions.https.onCall(async (data, context) => {
  const { conversationId, customerMessage } = data;
  const vendorId = context.auth?.uid;
  
  // Verify premium access
  if (!await hasPremiumAccess(vendorId)) {
    throw new Error('Premium subscription required');
  }
  
  // Get conversation context
  const conv = await db.collection('conversations').doc(conversationId).get();
  const messages = await conv.ref.collection('messages')
    .orderBy('createdAt', 'desc')
    .limit(10)
    .get();
  
  const context = messages.docs.reverse().map(doc => ({
    role: doc.data().senderId === vendorId ? 'assistant' : 'user',
    content: doc.data().text
  }));
  
  // Get vendor's FAQ and product info
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const vendorData = vendor.data();
  
  const response = await axios.post(
    `${VAPI_API}/chat/completions`,
    {
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: buildSystemPrompt({
            vendorId,
            storeName: vendorData.storeName,
            storeDescription: vendorData.storeDescription,
            faqData: vendorData.faq || []
          })
        },
        ...context,
        { role: 'user', content: customerMessage }
      ],
      max_tokens: 200
    },
    {
      headers: {
        'Authorization': `Bearer ${process.env.VAPI_API_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  return {
    suggestion: response.data.choices[0].message.content
  };
});
```

### Automated Response Handler

```typescript
// functions/src/ai/autoRespond.ts
export const handleAutoResponse = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const { conversationId } = context.params;
    
    // Only process customer messages
    const conv = await db.collection('conversations').doc(conversationId).get();
    const convData = conv.data();
    
    if (message.senderId === convData.vendorId) return;
    
    // Check if vendor has auto-response enabled
    const vendor = await db.collection('vendors').doc(convData.vendorId).get();
    const vendorData = vendor.data();
    
    if (!vendorData.aiAutoResponse || vendorData.subscriptionTier !== 'premium') {
      return;
    }
    
    // Generate and send auto-response
    const suggestion = await generateAISuggestion({
      conversationId,
      customerMessage: message.text
    });
    
    // Send as vendor
    await db.collection('conversations').doc(conversationId)
      .collection('messages').add({
        senderId: convData.vendorId,
        senderName: vendorData.storeName,
        text: suggestion,
        type: 'text',
        isAIGenerated: true,
        isRead: false,
        createdAt: FieldValue.serverTimestamp()
      });
    
    // Update conversation
    await db.collection('conversations').doc(conversationId).update({
      lastMessage: {
        text: suggestion,
        senderId: convData.vendorId,
        timestamp: FieldValue.serverTimestamp(),
        type: 'text'
      },
      [`unreadCount.${convData.buyerId}`]: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp()
    });
  });
```


## Firestore Collections

### AI Conversations Log

```
/aiConversations/{conversationId}
├── id: string
├── vendorId: string
├── customerId: string?
├── channel: 'chat' | 'voice' | 'phone'
├── vapiCallId: string?
├── messages: array
│   ├── role: 'user' | 'assistant'
│   ├── content: string
│   └── timestamp: timestamp
├── sentiment: 'positive' | 'neutral' | 'negative'
├── resolved: boolean
├── escalated: boolean
├── duration: number (seconds)
├── createdAt: timestamp
└── endedAt: timestamp?
```

### Vendor AI Settings

```
/vendors/{vendorId}/aiSettings
├── enabled: boolean
├── autoResponse: boolean
├── vapiAssistantId: string?
├── responseDelay: number (seconds)
├── workingHoursOnly: boolean
├── escalationKeywords: string[]
├── customPrompt: string?
└── faq: array
    ├── question: string
    └── answer: string
```

## Premium Subscription Management

### Subscribe to Premium

```typescript
export const subscribeToPremium = functions.https.onCall(async (data, context) => {
  const vendorId = context.auth?.uid;
  
  // Process payment via Pesapal
  const subscription = await processSubscriptionPayment(vendorId, 'premium');
  
  // Update vendor
  await db.collection('vendors').doc(vendorId).update({
    subscriptionTier: 'premium',
    subscriptionExpiresAt: Timestamp.fromDate(
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
    )
  });
  
  // Create Vapi assistant
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const vendorData = vendor.data();
  
  const assistantId = await createVapiAssistant({
    vendorId,
    storeName: vendorData.storeName,
    storeDescription: vendorData.storeDescription,
    faqData: vendorData.faq || []
  });
  
  await db.collection('vendors').doc(vendorId)
    .collection('aiSettings').doc('config').set({
      enabled: true,
      autoResponse: false,
      vapiAssistantId: assistantId,
      responseDelay: 5,
      workingHoursOnly: true,
      escalationKeywords: ['human', 'agent', 'manager', 'refund'],
      faq: []
    });
  
  return { success: true, assistantId };
});
```

### Check Subscription Status

```typescript
// Scheduled function to check expired subscriptions
export const checkSubscriptions = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const expired = await db.collection('vendors')
      .where('subscriptionTier', '==', 'premium')
      .where('subscriptionExpiresAt', '<', Timestamp.now())
      .get();
    
    const batch = db.batch();
    expired.docs.forEach(doc => {
      batch.update(doc.ref, {
        subscriptionTier: 'free'
      });
    });
    
    await batch.commit();
    
    // Notify vendors
    for (const doc of expired.docs) {
      await sendPushNotification({
        userId: doc.id,
        title: 'Subscription Expired',
        body: 'Your premium subscription has expired. Renew to continue using AI features.',
        type: NotificationType.SYSTEM
      });
    }
  });
```

## Flutter Integration

### AI Suggestion Widget

```dart
class AISuggestionWidget extends StatelessWidget {
  final String conversationId;
  final String customerMessage;
  
  Future<String?> _getSuggestion() async {
    try {
      final result = await FirebaseFunctions.instance
        .httpsCallable('generateAISuggestion')
        .call({
          'conversationId': conversationId,
          'customerMessage': customerMessage
        });
      return result.data['suggestion'];
    } catch (e) {
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getSuggestion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        return Card(
          child: ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text('AI Suggestion'),
            subtitle: Text(snapshot.data!),
            trailing: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _useSuggestion(snapshot.data!),
            ),
          ),
        );
      },
    );
  }
}
```

## Implementation Checklist

- [ ] Set up Vapi account
- [ ] Configure API credentials
- [ ] Implement assistant creation
- [ ] Implement suggestion generation
- [ ] Implement auto-response handler
- [ ] Build AI settings UI in vendor app
- [ ] Build suggestion UI in chat
- [ ] Implement subscription management
- [ ] Test AI responses
- [ ] Monitor and tune AI quality
