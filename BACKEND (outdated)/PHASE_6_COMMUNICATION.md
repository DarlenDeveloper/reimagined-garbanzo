# Phase 6: Communication - Chat & Notifications

## Overview

Implement real-time chat between buyers and vendors, plus push notifications using Firebase Cloud Messaging (FCM).

## Firestore Collections

### Conversations Collection

```
/conversations/{conversationId}
├── id: string
├── participants: string[] [buyerId, vendorId]
├── buyerId: string
├── buyerName: string
├── buyerAvatar: string?
├── vendorId: string
├── vendorName: string
├── vendorLogo: string?
├── lastMessage: map
│   ├── text: string
│   ├── senderId: string
│   ├── timestamp: timestamp
│   └── type: 'text' | 'image' | 'order'
├── unreadCount: map
│   ├── [buyerId]: number
│   └── [vendorId]: number
├── orderId: string? (if related to order)
├── isActive: boolean
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Messages Subcollection

```
/conversations/{conversationId}/messages/{messageId}
├── id: string
├── senderId: string
├── senderName: string
├── text: string
├── type: 'text' | 'image' | 'order' | 'system'
├── imageUrl: string?
├── orderRef: map? (for order messages)
│   ├── orderId: string
│   ├── orderNumber: string
│   └── status: string
├── isRead: boolean
├── readAt: timestamp?
└── createdAt: timestamp
```


### Notifications Collection

```
/notifications/{notificationId}
├── id: string
├── userId: string
├── type: NotificationType
├── title: string
├── body: string
├── data: map (payload)
├── imageUrl: string?
├── isRead: boolean
├── readAt: timestamp?
└── createdAt: timestamp
```

### Notification Types

```typescript
enum NotificationType {
  NEW_ORDER = 'new_order',
  ORDER_STATUS = 'order_status',
  PAYMENT_RECEIVED = 'payment_received',
  DELIVERY_UPDATE = 'delivery_update',
  NEW_MESSAGE = 'new_message',
  LOW_STOCK = 'low_stock',
  PAYOUT_PROCESSED = 'payout_processed',
  PROMO = 'promo',
  SYSTEM = 'system'
}
```

## Chat Implementation

### Start Conversation

```typescript
// functions/src/chat/startConversation.ts
export const startConversation = functions.https.onCall(async (data, context) => {
  const { vendorId, orderId, initialMessage } = data;
  const buyerId = context.auth?.uid;
  
  // Check if conversation exists
  const existing = await db.collection('conversations')
    .where('buyerId', '==', buyerId)
    .where('vendorId', '==', vendorId)
    .limit(1)
    .get();
  
  if (!existing.empty) {
    return { conversationId: existing.docs[0].id };
  }
  
  // Get user details
  const buyer = await db.collection('users').doc(buyerId).get();
  const vendor = await db.collection('vendors').doc(vendorId).get();
  
  const buyerData = buyer.data();
  const vendorData = vendor.data();
  
  // Create conversation
  const convRef = db.collection('conversations').doc();
  await convRef.set({
    id: convRef.id,
    participants: [buyerId, vendorId],
    buyerId,
    buyerName: buyerData.displayName,
    buyerAvatar: buyerData.avatarUrl,
    vendorId,
    vendorName: vendorData.storeName,
    vendorLogo: vendorData.logoUrl,
    lastMessage: null,
    unreadCount: { [buyerId]: 0, [vendorId]: 0 },
    orderId,
    isActive: true,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp()
  });
  
  // Send initial message if provided
  if (initialMessage) {
    await sendMessage(convRef.id, buyerId, initialMessage);
  }
  
  return { conversationId: convRef.id };
});
```

### Send Message

```typescript
// functions/src/chat/sendMessage.ts
export const sendMessage = functions.https.onCall(async (data, context) => {
  const { conversationId, text, type = 'text', imageUrl } = data;
  const senderId = context.auth?.uid;
  
  const convRef = db.collection('conversations').doc(conversationId);
  const conv = await convRef.get();
  
  if (!conv.exists) throw new Error('Conversation not found');
  if (!conv.data().participants.includes(senderId)) throw new Error('Unauthorized');
  
  const sender = await db.collection('users').doc(senderId).get();
  const senderData = sender.data();
  
  // Create message
  const msgRef = convRef.collection('messages').doc();
  const message = {
    id: msgRef.id,
    senderId,
    senderName: senderData.displayName,
    text,
    type,
    imageUrl,
    isRead: false,
    createdAt: FieldValue.serverTimestamp()
  };
  
  await msgRef.set(message);
  
  // Update conversation
  const recipientId = conv.data().participants.find(p => p !== senderId);
  await convRef.update({
    lastMessage: {
      text: type === 'image' ? '📷 Image' : text,
      senderId,
      timestamp: FieldValue.serverTimestamp(),
      type
    },
    [`unreadCount.${recipientId}`]: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp()
  });
  
  // Send push notification
  await sendChatNotification(recipientId, senderData.displayName, text);
  
  return { messageId: msgRef.id };
});
```

### Mark Messages as Read

```typescript
export const markAsRead = functions.https.onCall(async (data, context) => {
  const { conversationId } = data;
  const userId = context.auth?.uid;
  
  const convRef = db.collection('conversations').doc(conversationId);
  
  // Reset unread count
  await convRef.update({
    [`unreadCount.${userId}`]: 0
  });
  
  // Mark messages as read
  const unreadMessages = await convRef.collection('messages')
    .where('senderId', '!=', userId)
    .where('isRead', '==', false)
    .get();
  
  const batch = db.batch();
  unreadMessages.docs.forEach(doc => {
    batch.update(doc.ref, {
      isRead: true,
      readAt: FieldValue.serverTimestamp()
    });
  });
  
  await batch.commit();
});
```


## Push Notifications (FCM)

### FCM Token Management

```typescript
// functions/src/notifications/updateFCMToken.ts
export const updateFCMToken = functions.https.onCall(async (data, context) => {
  const { token } = data;
  const userId = context.auth?.uid;
  
  await db.collection('users').doc(userId).update({
    fcmTokens: FieldValue.arrayUnion(token)
  });
});

export const removeFCMToken = functions.https.onCall(async (data, context) => {
  const { token } = data;
  const userId = context.auth?.uid;
  
  await db.collection('users').doc(userId).update({
    fcmTokens: FieldValue.arrayRemove(token)
  });
});
```

### Send Push Notification

```typescript
// functions/src/notifications/sendPush.ts
import * as admin from 'firebase-admin';

interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  type: NotificationType;
  data?: Record<string, string>;
  imageUrl?: string;
}

export async function sendPushNotification(payload: NotificationPayload) {
  const user = await db.collection('users').doc(payload.userId).get();
  const userData = user.data();
  
  if (!userData?.fcmTokens?.length) return;
  if (!userData?.settings?.notificationsEnabled) return;
  
  // Store notification in Firestore
  const notifRef = db.collection('notifications').doc();
  await notifRef.set({
    id: notifRef.id,
    userId: payload.userId,
    type: payload.type,
    title: payload.title,
    body: payload.body,
    data: payload.data || {},
    imageUrl: payload.imageUrl,
    isRead: false,
    createdAt: FieldValue.serverTimestamp()
  });
  
  // Send FCM notification
  const message: admin.messaging.MulticastMessage = {
    tokens: userData.fcmTokens,
    notification: {
      title: payload.title,
      body: payload.body,
      imageUrl: payload.imageUrl
    },
    data: {
      type: payload.type,
      notificationId: notifRef.id,
      ...payload.data
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
      }
    },
    apns: {
      payload: {
        aps: {
          badge: 1,
          sound: 'default'
        }
      }
    }
  };
  
  const response = await admin.messaging().sendEachForMulticast(message);
  
  // Remove invalid tokens
  response.responses.forEach((resp, idx) => {
    if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
      db.collection('users').doc(payload.userId).update({
        fcmTokens: FieldValue.arrayRemove(userData.fcmTokens[idx])
      });
    }
  });
}
```

### Notification Triggers

```typescript
// New Order Notification (to vendor)
export async function sendNewOrderNotification(vendorId: string, orderId: string) {
  const order = await db.collection('orders').doc(orderId).get();
  const orderData = order.data();
  
  await sendPushNotification({
    userId: vendorId,
    title: 'New Order!',
    body: `Order ${orderData.orderNumber} - ${orderData.total} ${orderData.currency}`,
    type: NotificationType.NEW_ORDER,
    data: { orderId }
  });
}

// Order Status Notification (to buyer)
export async function sendOrderStatusNotification(buyerId: string, orderId: string, status: string) {
  const statusMessages: Record<string, string> = {
    accepted: 'Your order has been accepted',
    processing: 'Your order is being prepared',
    ready: 'Your order is ready for pickup',
    picked_up: 'Your order is on the way',
    delivered: 'Your order has been delivered',
    cancelled: 'Your order has been cancelled'
  };
  
  await sendPushNotification({
    userId: buyerId,
    title: 'Order Update',
    body: statusMessages[status] || `Order status: ${status}`,
    type: NotificationType.ORDER_STATUS,
    data: { orderId, status }
  });
}

// Low Stock Alert (to vendor)
export async function sendLowStockAlert(vendorId: string, productId: string, stock: number) {
  const product = await db.collection('products').doc(productId).get();
  
  await sendPushNotification({
    userId: vendorId,
    title: 'Low Stock Alert',
    body: `${product.data().name} has only ${stock} items left`,
    type: NotificationType.LOW_STOCK,
    data: { productId, stock: stock.toString() }
  });
}
```

## Flutter Integration

### FCM Setup

```dart
// lib/services/notification_service.dart
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission();
    
    // Get token
    final token = await _fcm.getToken();
    if (token != null) {
      await _updateToken(token);
    }
    
    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_updateToken);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }
  
  Future<void> _updateToken(String token) async {
    await FirebaseFunctions.instance
      .httpsCallable('updateFCMToken')
      .call({'token': token});
  }
}
```

## Security Rules

```javascript
// Conversations
match /conversations/{convId} {
  allow read: if request.auth.uid in resource.data.participants;
  allow create: if request.auth != null;
  allow update: if request.auth.uid in resource.data.participants;
}

// Messages
match /conversations/{convId}/messages/{msgId} {
  allow read: if request.auth.uid in get(/databases/$(database)/documents/conversations/$(convId)).data.participants;
  allow create: if request.auth.uid in get(/databases/$(database)/documents/conversations/$(convId)).data.participants;
}

// Notifications
match /notifications/{notifId} {
  allow read: if request.auth.uid == resource.data.userId;
  allow update: if request.auth.uid == resource.data.userId;
}
```

## Implementation Checklist

- [ ] Create Firestore collections
- [ ] Implement chat Cloud Functions
- [ ] Implement FCM token management
- [ ] Implement push notification functions
- [ ] Build chat UI in both apps
- [ ] Build notifications list UI
- [ ] Configure FCM in Flutter apps
- [ ] Test real-time messaging
- [ ] Test push notifications
