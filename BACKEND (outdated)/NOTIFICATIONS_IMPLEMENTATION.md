# Notifications Implementation Guide

## Overview
This document explains the notification system for the PURL marketplace, including triggers, delivery, and custom sounds.

---

## Notification Types

### 1. New Order Notification (Seller)
**Trigger:** When a buyer places an order  
**Recipient:** Store owner  
**Title:** "🎉 New Order!"  
**Body:** "Order ORD-20260207-224445 - Total: $2,060.40"  
**Sound:** Custom notification sound  
**Action:** Navigate to Orders screen

**Implementation Status:** ✅ Trigger implemented in `order_service.dart`

---

### 2. Low Inventory Notification (Seller)
**Trigger:** When product stock falls below threshold  
**Recipient:** Store owner  
**Title:** "⚠️ Low Stock Alert"  
**Body:** "MacBook Pro is running low (2 left)"  
**Sound:** Custom notification sound  
**Action:** Navigate to Inventory screen

**Implementation Status:** ⏳ TODO - Add to ProductService

---

### 3. New Message Notification (Both)
**Trigger:** When someone sends a message  
**Recipient:** Message recipient  
**Title:** "💬 New Message"  
**Body:** "John Doe: Hey, is this still available?"  
**Sound:** Custom notification sound  
**Action:** Navigate to Messages screen

**Implementation Status:** ⏳ TODO - Add to MessagesService

---

## Architecture

### Client-Side (Flutter)
1. **NotificationService** handles:
   - FCM token registration
   - Local notification display
   - Custom sound playback
   - Notification tap handling
   - Saving notifications to Firestore

2. **Trigger Points:**
   - `OrderService.createOrdersFromCart()` → New order notification
   - `ProductService.updateProduct()` → Low inventory check
   - `MessagesService.sendMessage()` → New message notification

### Server-Side (Cloud Functions)
**TODO: Create Cloud Function to send FCM notifications**

```javascript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Listen for new notifications and send FCM
export const sendNotification = functions.firestore
  .document('stores/{storeId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const fcmToken = notification.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token found');
      return null;
    }

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: notification.type,
        orderId: notification.orderId || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        notification: {
          sound: 'notification',
          channelId: 'purl_seller_channel_v2',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'notification.mp3',
          },
        },
      },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(message);
      console.log('Notification sent successfully');
    } catch (error) {
      console.error('Error sending notification:', error);
    }

    return null;
  });
```

---

## Custom Notification Sound

### Android Setup
1. Add sound file to `android/app/src/main/res/raw/notification.mp3`
2. Sound is referenced in NotificationService as `RawResourceAndroidNotificationSound('notification')`
3. Channel ID: `purl_seller_channel_v2`

### iOS Setup
1. Add sound file to `ios/Runner/notification.mp3`
2. Update `Info.plist` if needed
3. Sound is referenced as `notification.mp3`

### Sound Requirements
- Format: MP3 or WAV
- Duration: 2-5 seconds recommended
- Volume: Normalized to prevent distortion
- Unique: Should be distinct from default system sounds

---

## Firestore Structure

### Notifications Collection
```
/stores/{storeId}/notifications/{notificationId}
├── title: string
├── body: string
├── type: string ("new_order" | "low_stock" | "message")
├── orderId: string (optional)
├── productId: string (optional)
├── conversationId: string (optional)
├── amount: number (optional)
├── isRead: boolean
├── createdAt: timestamp
└── fcmToken: string (for Cloud Function)
```

### FCM Token Storage
```
/stores/{storeId}
├── fcmToken: string
├── fcmTokenUpdatedAt: timestamp
└── platform: string ("android" | "ios")
```

---

## Implementation Checklist

### ✅ Completed
- [x] NotificationService with custom sound support
- [x] FCM token registration and storage
- [x] Local notification display
- [x] New order notification trigger
- [x] Notification tap handling
- [x] Unread count tracking

### ⏳ TODO
- [ ] Deploy Cloud Function to send FCM notifications
- [ ] Add low inventory notification trigger
- [ ] Add new message notification trigger
- [ ] Test notifications on Android
- [ ] Test notifications on iOS
- [ ] Add notification preferences (enable/disable by type)
- [ ] Add notification history screen with real data
- [ ] Handle notification navigation properly

---

## Testing

### Test New Order Notification
1. Place an order from buyer app
2. Seller should receive notification immediately
3. Tap notification → should open Orders screen
4. Custom sound should play

### Test Low Inventory Notification
1. Update product stock to below threshold (e.g., 5 items)
2. Seller should receive notification
3. Tap notification → should open Inventory screen

### Test New Message Notification
1. Send message from buyer to seller
2. Seller should receive notification
3. Tap notification → should open Messages screen with that conversation

---

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Store notifications - only store owner can read/write
    match /stores/{storeId}/notifications/{notificationId} {
      allow read: if request.auth != null && 
                     request.auth.uid in get(/databases/$(database)/documents/stores/$(storeId)).data.authorizedUsers;
      allow create: if request.auth != null; // Allow system to create
      allow update: if request.auth != null && 
                       request.auth.uid in get(/databases/$(database)/documents/stores/$(storeId)).data.authorizedUsers;
    }
  }
}
```

---

## Troubleshooting

### Notifications Not Received
1. Check FCM token is saved in Firestore
2. Verify Cloud Function is deployed
3. Check Cloud Function logs for errors
4. Ensure notification permissions are granted
5. Test with Firebase Console → Cloud Messaging

### Custom Sound Not Playing
1. Verify sound file exists in correct location
2. Check file format (MP3/WAV)
3. Ensure channel ID matches
4. Test on physical device (not emulator)

### Notification Tap Not Working
1. Check payload data is correct
2. Verify navigation logic in `_handleMessageOpenedApp`
3. Test from both background and terminated states

---

*Last Updated: February 8, 2026*
