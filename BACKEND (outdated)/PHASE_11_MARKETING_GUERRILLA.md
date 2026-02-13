# Phase 11: Marketing & Guerrilla Campaigns

## Overview

This document covers the comprehensive marketing system including SMS campaigns, AI-powered email marketing, AI voice calls (via Vapi), and push notifications to store followers.

---

## 1. Marketing Campaigns Overview

### Campaign Types

| Type | Mode | Description |
|------|------|-------------|
| SMS | Manual | Vendor composes and sends SMS to customer segments |
| Email | AI-Powered | Automated personalized emails via AI |
| Calls | AI-Powered | Outbound marketing calls via Vapi API |
| Push | Followers Only | Push notifications to store followers |

---

## 2. Firestore Collections

### Campaigns Collection

```
/vendors/{vendorId}/campaigns/{campaignId}
├── id: string
├── vendorId: string
├── name: string
├── type: 'sms' | 'email' | 'call' | 'push'
├── mode: 'manual' | 'ai_powered'
├── status: 'draft' | 'scheduled' | 'running' | 'completed' | 'paused'
├── content: map
│   ├── subject: string? (email)
│   ├── body: string
│   ├── template: string?
│   └── aiPrompt: string? (for AI campaigns)
├── audience: map
│   ├── type: 'all' | 'segment' | 'followers' | 'custom'
│   ├── segmentId: string?
│   ├── customIds: string[]?
│   └── estimatedReach: number
├── schedule: map
│   ├── sendAt: timestamp?
│   ├── timezone: string
│   └── recurring: boolean
├── stats: map
│   ├── sent: number
│   ├── delivered: number
│   ├── opened: number
│   ├── clicked: number
│   ├── responded: number
│   ├── converted: number
│   └── revenue: number
├── createdAt: timestamp
├── updatedAt: timestamp
└── completedAt: timestamp?
```

### SMS Messages Collection

```
/vendors/{vendorId}/smsMessages/{messageId}
├── id: string
├── campaignId: string?
├── recipientPhone: string
├── recipientName: string?
├── content: string
├── characterCount: number
├── status: 'pending' | 'sent' | 'delivered' | 'failed'
├── provider: string (e.g., 'twilio', 'africas_talking')
├── providerMessageId: string?
├── cost: number?
├── sentAt: timestamp
├── deliveredAt: timestamp?
└── errorMessage: string?
```

### Email Campaigns Collection

```
/vendors/{vendorId}/emailCampaigns/{campaignId}
├── id: string
├── type: 'welcome' | 'abandoned_cart' | 're_engagement' | 'product_recommendation' | 'order_followup' | 'promotional'
├── isAiPowered: boolean
├── aiSettings: map
│   ├── enabled: boolean
│   ├── tone: string (friendly, professional, casual)
│   └── prompt: string
├── template: map
│   ├── subject: string
│   ├── preheader: string?
│   ├── bodyHtml: string
│   └── bodyText: string
├── triggers: map? (for automated)
│   ├── event: string
│   ├── delayMinutes: number
│   └── conditions: map
├── stats: map
│   ├── sent: number
│   ├── delivered: number
│   ├── opened: number
│   ├── clicked: number
│   └── unsubscribed: number
├── isActive: boolean
├── createdAt: timestamp
└── updatedAt: timestamp
```

### AI Call Campaigns Collection

```
/vendors/{vendorId}/callCampaigns/{campaignId}
├── id: string
├── name: string
├── vapiAssistantId: string
├── assignedPhoneNumber: string
├── status: 'active' | 'paused' | 'completed'
├── callTypes: string[] ('promotional', 'followup', 'winback', 'survey')
├── script: map
│   ├── greeting: string
│   ├── mainMessage: string
│   ├── callToAction: string
│   └── closing: string
├── aiPrompt: string
├── schedule: map
│   ├── startTime: string (HH:mm)
│   ├── endTime: string (HH:mm)
│   ├── daysOfWeek: number[]
│   └── timezone: string
├── stats: map
│   ├── totalCalls: number
│   ├── answered: number
│   ├── avgDuration: number (seconds)
│   ├── converted: number
│   └── callbackRequested: number
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Call Logs Collection

```
/vendors/{vendorId}/callLogs/{callId}
├── id: string
├── campaignId: string
├── vapiCallId: string
├── recipientPhone: string
├── recipientName: string?
├── buyerId: string?
├── direction: 'outbound' | 'inbound'
├── status: 'initiated' | 'ringing' | 'answered' | 'completed' | 'failed' | 'no_answer'
├── duration: number (seconds)
├── outcome: 'interested' | 'not_interested' | 'callback' | 'converted' | 'voicemail'
├── transcript: string?
├── recordingUrl: string?
├── sentiment: 'positive' | 'neutral' | 'negative'?
├── notes: string?
├── startedAt: timestamp
├── endedAt: timestamp?
└── createdAt: timestamp
```

---

## 3. SMS Campaign Functions

### Send SMS Campaign

```typescript
// functions/src/marketing/sendSmsCampaign.ts
import * as functions from 'firebase-functions';
import { AfricasTalking } from 'africastalking'; // or Twilio

export const sendSmsCampaign = functions.https.onCall(async (data, context) => {
  const { vendorId, recipients, message, campaignName } = data;
  const userId = context.auth?.uid;
  
  // Verify permission
  await requirePermission(userId, vendorId, 'marketing:create');
  
  // Create campaign record
  const campaignRef = db.collection('vendors').doc(vendorId)
    .collection('campaigns').doc();
  
  await campaignRef.set({
    id: campaignRef.id,
    vendorId,
    name: campaignName,
    type: 'sms',
    mode: 'manual',
    status: 'running',
    content: { body: message },
    audience: {
      type: 'custom',
      customIds: recipients.map(r => r.phone),
      estimatedReach: recipients.length
    },
    stats: { sent: 0, delivered: 0, responded: 0 },
    createdAt: FieldValue.serverTimestamp()
  });
  
  // Send messages
  const smsProvider = new AfricasTalking({
    apiKey: process.env.AT_API_KEY,
    username: process.env.AT_USERNAME
  });
  
  const results = [];
  for (const recipient of recipients) {
    try {
      const result = await smsProvider.SMS.send({
        to: recipient.phone,
        message: message,
        from: process.env.SMS_SENDER_ID
      });
      
      // Log message
      await db.collection('vendors').doc(vendorId)
        .collection('smsMessages').add({
          campaignId: campaignRef.id,
          recipientPhone: recipient.phone,
          recipientName: recipient.name,
          content: message,
          characterCount: message.length,
          status: 'sent',
          provider: 'africas_talking',
          providerMessageId: result.SMSMessageData.Recipients[0].messageId,
          sentAt: FieldValue.serverTimestamp()
        });
      
      results.push({ phone: recipient.phone, success: true });
    } catch (error) {
      results.push({ phone: recipient.phone, success: false, error: error.message });
    }
  }
  
  // Update campaign stats
  const successCount = results.filter(r => r.success).length;
  await campaignRef.update({
    'stats.sent': successCount,
    status: 'completed',
    completedAt: FieldValue.serverTimestamp()
  });
  
  return { campaignId: campaignRef.id, results };
});
```

---

## 4. AI Email Campaign Functions

### Configure AI Email Settings

```typescript
// functions/src/marketing/configureAiEmail.ts
export const configureAiEmail = functions.https.onCall(async (data, context) => {
  const { vendorId, emailType, settings } = data;
  const userId = context.auth?.uid;
  
  await requirePermission(userId, vendorId, 'marketing:create');
  
  const campaignRef = db.collection('vendors').doc(vendorId)
    .collection('emailCampaigns').doc(emailType);
  
  await campaignRef.set({
    id: emailType,
    type: emailType,
    isAiPowered: true,
    aiSettings: {
      enabled: settings.enabled,
      tone: settings.tone || 'friendly',
      prompt: settings.prompt
    },
    triggers: settings.triggers,
    isActive: settings.enabled,
    updatedAt: FieldValue.serverTimestamp()
  }, { merge: true });
  
  return { success: true };
});

// Trigger: Send AI email on event
export const onAbandonedCart = functions.firestore
  .document('carts/{cartId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if cart was abandoned (no update for 1 hour)
    const lastUpdate = after.updatedAt?.toDate();
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    
    if (lastUpdate < oneHourAgo && after.items.length > 0 && !after.abandonedEmailSent) {
      const vendorId = after.vendorId;
      const buyerId = after.buyerId;
      
      // Check if AI abandoned cart email is enabled
      const emailConfig = await db.collection('vendors').doc(vendorId)
        .collection('emailCampaigns').doc('abandoned_cart').get();
      
      if (emailConfig.exists && emailConfig.data().isActive) {
        await sendAiEmail({
          vendorId,
          buyerId,
          type: 'abandoned_cart',
          context: {
            cartItems: after.items,
            cartTotal: after.total
          }
        });
        
        await change.after.ref.update({ abandonedEmailSent: true });
      }
    }
  });
```

### Generate AI Email Content

```typescript
// functions/src/marketing/generateAiEmail.ts
import { OpenAI } from 'openai';

async function generateAiEmailContent(
  vendorId: string,
  emailType: string,
  context: any
): Promise<{ subject: string; body: string }> {
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const emailConfig = await db.collection('vendors').doc(vendorId)
    .collection('emailCampaigns').doc(emailType).get();
  
  const aiSettings = emailConfig.data()?.aiSettings;
  const vendorData = vendor.data();
  
  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  
  const systemPrompt = `You are an email marketing assistant for ${vendorData.storeName}. 
    Write ${aiSettings.tone} emails that highlight product benefits.
    ${aiSettings.prompt}`;
  
  const userPrompt = buildEmailPrompt(emailType, context);
  
  const response = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ],
    temperature: 0.7
  });
  
  const content = response.choices[0].message.content;
  const [subject, ...bodyParts] = content.split('\n\n');
  
  return {
    subject: subject.replace('Subject: ', ''),
    body: bodyParts.join('\n\n')
  };
}
```

---

## 5. AI Voice Calls (Vapi Integration)

### Create Call Campaign

```typescript
// functions/src/marketing/createCallCampaign.ts
export const createCallCampaign = functions.https.onCall(async (data, context) => {
  const { vendorId, name, callTypes, script, schedule } = data;
  const userId = context.auth?.uid;
  
  await requirePermission(userId, vendorId, 'marketing:create');
  
  // Create Vapi assistant for this campaign
  const vapiAssistant = await createVapiAssistant({
    name: `${name} - Marketing`,
    voice: 'jennifer',
    firstMessage: script.greeting,
    model: {
      provider: 'openai',
      model: 'gpt-4',
      systemPrompt: buildMarketingPrompt(script)
    }
  });
  
  // Get or assign phone number
  const phoneNumber = await getVendorPhoneNumber(vendorId);
  
  const campaignRef = db.collection('vendors').doc(vendorId)
    .collection('callCampaigns').doc();
  
  await campaignRef.set({
    id: campaignRef.id,
    name,
    vapiAssistantId: vapiAssistant.id,
    assignedPhoneNumber: phoneNumber,
    status: 'active',
    callTypes,
    script,
    aiPrompt: buildMarketingPrompt(script),
    schedule,
    stats: {
      totalCalls: 0,
      answered: 0,
      avgDuration: 0,
      converted: 0,
      callbackRequested: 0
    },
    createdAt: FieldValue.serverTimestamp()
  });
  
  return { campaignId: campaignRef.id, assistantId: vapiAssistant.id };
});
```

### Initiate Marketing Call

```typescript
// functions/src/marketing/initiateMarketingCall.ts
export const initiateMarketingCall = functions.https.onCall(async (data, context) => {
  const { vendorId, campaignId, recipientPhone, recipientName, buyerId } = data;
  
  const campaign = await db.collection('vendors').doc(vendorId)
    .collection('callCampaigns').doc(campaignId).get();
  
  if (!campaign.exists || campaign.data().status !== 'active') {
    throw new Error('Campaign not active');
  }
  
  const campaignData = campaign.data();
  
  // Initiate call via Vapi
  const call = await vapiClient.calls.create({
    assistantId: campaignData.vapiAssistantId,
    phoneNumber: {
      twilioPhoneNumber: campaignData.assignedPhoneNumber
    },
    customer: {
      number: recipientPhone,
      name: recipientName
    },
    assistantOverrides: {
      variableValues: {
        customerName: recipientName,
        storeName: (await db.collection('vendors').doc(vendorId).get()).data().storeName
      }
    }
  });
  
  // Log call
  const callLogRef = db.collection('vendors').doc(vendorId)
    .collection('callLogs').doc();
  
  await callLogRef.set({
    id: callLogRef.id,
    campaignId,
    vapiCallId: call.id,
    recipientPhone,
    recipientName,
    buyerId,
    direction: 'outbound',
    status: 'initiated',
    startedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp()
  });
  
  return { callId: callLogRef.id, vapiCallId: call.id };
});
```

### Handle Vapi Call Webhook

```typescript
// functions/src/webhooks/vapiMarketingWebhook.ts
export const vapiMarketingWebhook = functions.https.onRequest(async (req, res) => {
  const { type, call } = req.body;
  
  // Find call log by Vapi call ID
  const callLogs = await db.collectionGroup('callLogs')
    .where('vapiCallId', '==', call.id)
    .limit(1)
    .get();
  
  if (callLogs.empty) {
    res.status(404).send('Call not found');
    return;
  }
  
  const callLogRef = callLogs.docs[0].ref;
  
  switch (type) {
    case 'call-started':
      await callLogRef.update({ status: 'ringing' });
      break;
      
    case 'speech-update':
      // Call was answered
      await callLogRef.update({ status: 'answered' });
      break;
      
    case 'call-ended':
      const duration = call.endedAt - call.startedAt;
      const outcome = analyzeCallOutcome(call.transcript);
      
      await callLogRef.update({
        status: 'completed',
        duration,
        outcome,
        transcript: call.transcript,
        recordingUrl: call.recordingUrl,
        sentiment: call.analysis?.sentiment,
        endedAt: FieldValue.serverTimestamp()
      });
      
      // Update campaign stats
      const callLog = (await callLogRef.get()).data();
      const campaignRef = callLogRef.parent.parent
        .collection('callCampaigns').doc(callLog.campaignId);
      
      await campaignRef.update({
        'stats.totalCalls': FieldValue.increment(1),
        'stats.answered': FieldValue.increment(call.status === 'answered' ? 1 : 0),
        'stats.converted': FieldValue.increment(outcome === 'converted' ? 1 : 0)
      });
      break;
  }
  
  res.status(200).send('OK');
});
```

---

## 6. Push Notifications to Followers

### Send Push to Followers

```typescript
// functions/src/marketing/sendPushToFollowers.ts
export const sendPushToFollowers = functions.https.onCall(async (data, context) => {
  const { vendorId, title, message, notificationType, imageUrl } = data;
  const userId = context.auth?.uid;
  
  await requirePermission(userId, vendorId, 'marketing:create');
  
  // Get all followers
  const followers = await db.collection('followers')
    .where('vendorId', '==', vendorId)
    .get();
  
  if (followers.empty) {
    return { sent: 0, message: 'No followers to notify' };
  }
  
  // Get FCM tokens for followers
  const buyerIds = followers.docs.map(d => d.data().buyerId);
  const tokens = [];
  
  for (const buyerId of buyerIds) {
    const buyer = await db.collection('users').doc(buyerId).get();
    if (buyer.exists && buyer.data().fcmToken) {
      tokens.push(buyer.data().fcmToken);
    }
  }
  
  // Create campaign record
  const campaignRef = db.collection('vendors').doc(vendorId)
    .collection('campaigns').doc();
  
  await campaignRef.set({
    id: campaignRef.id,
    vendorId,
    name: title,
    type: 'push',
    mode: 'manual',
    status: 'running',
    content: { subject: title, body: message },
    audience: {
      type: 'followers',
      estimatedReach: tokens.length
    },
    stats: { sent: 0, delivered: 0, opened: 0 },
    createdAt: FieldValue.serverTimestamp()
  });
  
  // Send push notifications in batches
  const batchSize = 500;
  let sent = 0;
  
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    
    const message = {
      notification: {
        title,
        body: message,
        imageUrl
      },
      data: {
        type: notificationType,
        vendorId,
        campaignId: campaignRef.id
      },
      tokens: batch
    };
    
    const response = await admin.messaging().sendEachForMulticast(message);
    sent += response.successCount;
  }
  
  // Update campaign stats
  await campaignRef.update({
    'stats.sent': sent,
    'stats.delivered': sent,
    status: 'completed',
    completedAt: FieldValue.serverTimestamp()
  });
  
  return { campaignId: campaignRef.id, sent, total: tokens.length };
});
```

---

## 7. Marketing Analytics

### Daily Stats Aggregation

```
/vendors/{vendorId}/marketingStats/{date}
├── date: string (YYYY-MM-DD)
├── sms: map
│   ├── sent: number
│   ├── delivered: number
│   ├── responses: number
│   └── cost: number
├── email: map
│   ├── sent: number
│   ├── delivered: number
│   ├── opened: number
│   ├── clicked: number
│   └── unsubscribed: number
├── calls: map
│   ├── made: number
│   ├── answered: number
│   ├── avgDuration: number
│   ├── converted: number
│   └── cost: number
├── push: map
│   ├── sent: number
│   ├── delivered: number
│   └── opened: number
├── totalReach: number
├── totalConversions: number
├── totalRevenue: number
└── roi: number
```

---

## 8. Security Rules

```javascript
// Marketing campaigns - vendor members only
match /vendors/{vendorId}/campaigns/{campaignId} {
  allow read: if isMemberOf(vendorId);
  allow write: if hasPermission(vendorId, 'marketing:create');
}

match /vendors/{vendorId}/callCampaigns/{campaignId} {
  allow read: if isMemberOf(vendorId);
  allow write: if hasPermission(vendorId, 'marketing:create');
}

match /vendors/{vendorId}/callLogs/{callId} {
  allow read: if isMemberOf(vendorId);
  allow write: if false; // Only via Cloud Functions
}
```

---

## Implementation Checklist

- [ ] Set up SMS provider (Africa's Talking / Twilio)
- [ ] Implement SMS campaign sending
- [ ] Configure AI email automation
- [ ] Integrate Vapi for marketing calls
- [ ] Implement push notification to followers
- [ ] Build marketing dashboard UI
- [ ] Implement campaign analytics
- [ ] Set up webhook handlers
- [ ] Test all marketing channels
