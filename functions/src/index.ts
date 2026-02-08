import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onCall} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();

// Set global options for all functions
setGlobalOptions({
  region: "africa-south1",
  maxInstances: 10,
});

/**
 * Send notification to a specific FCM token
 */
async function sendNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  try {
    await admin.messaging().send({
      token,
      notification: {
        title,
        body,
      },
      data,
      android: {
        priority: "high",
        notification: {
          sound: "notification",
          channelId: "purl_seller_channel_v2",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "notification.mp3",
            badge: 1,
          },
        },
      },
    });
    console.log(`✅ Notification sent to ${token}`);
  } catch (error) {
    console.error(`❌ Error sending notification:`, error);
  }
}

/**
 * Trigger: New order created
 * Send push notification to all store staff phones
 */
export const onOrderCreated = onDocumentCreated(
  "stores/{storeId}/orders/{orderId}",
  async (event) => {
    const order = event.data?.data();
    if (!order) return;

    const storeId = event.params.storeId;
    const orderId = event.params.orderId;

    console.log(`📦 New order: ${orderId} for store: ${storeId}`);

    // Get store's authorized users
    const storeDoc = await admin.firestore().collection("stores").doc(storeId).get();
    if (!storeDoc.exists) {
      console.log("Store not found");
      return;
    }

    const authorizedUsers = storeDoc.data()?.authorizedUsers || [];
    if (authorizedUsers.length === 0) {
      console.log("No authorized users");
      return;
    }

    // Get store name
    const storeName = storeDoc.data()?.name || storeDoc.data()?.storeName || "Your store";
    const itemCount = order.items?.length || 1;

    // Get FCM tokens from /users/{userId}
    const tokens: string[] = [];
    for (const userId of authorizedUsers) {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (userDoc.exists && userDoc.data()?.fcmToken) {
        tokens.push(userDoc.data()!.fcmToken);
      }
    }

    if (tokens.length === 0) {
      console.log("No FCM tokens");
      return;
    }

    console.log(`📤 Sending to ${tokens.length} phone(s)`);

    // Send push notification to phones
    for (const token of tokens) {
      await sendNotification(
        token,
        "🎉 New Order!",
        `${storeName} has a new order for ${itemCount} item${itemCount > 1 ? 's' : ''} totalling ${order.currency} ${order.total}`,
        {type: "new_order", orderId, storeId}
      );
    }

    // Save to notifications screen
    await admin.firestore()
      .collection("stores")
      .doc(storeId)
      .collection("notifications")
      .add({
        title: "🎉 New Order!",
        body: `${storeName} has a new order for ${itemCount} item${itemCount > 1 ? 's' : ''} totalling ${order.currency} ${order.total}`,
        type: "new_order",
        data: {orderId},
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log(`✅ Sent`);
  }
);

/**
 * Trigger: New message sent
 * Notify recipient about new message
 */
export const onMessageSent = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const senderId = message.senderId;
    const messageText = message.text;
    const messageId = event.params.messageId;
    const conversationId = event.params.conversationId;

    console.log(`💬 New message in conversation: ${conversationId}`);

    console.log(`💬 New message in conversation: ${conversationId}`);

    // Get conversation to find recipient and sender info
    const conversationDoc = await admin.firestore()
      .collection("conversations")
      .doc(conversationId)
      .get();

    if (!conversationDoc.exists) {
      console.log("Conversation not found");
      return;
    }

    const conversationData = conversationDoc.data();
    const participants = conversationData?.participants || [];
    const recipientId = participants.find((id: string) => id !== senderId);

    if (!recipientId) {
      console.log("Recipient not found");
      return;
    }

    // Get sender name from conversation
    const senderName = senderId === conversationData?.storeId
      ? conversationData?.storeName
      : conversationData?.userName;

    // Get recipient's FCM token (could be seller or buyer)
    let recipientDoc = await admin.firestore()
      .collection("stores")
      .doc(recipientId)
      .get();

    if (!recipientDoc.exists) {
      // Try users collection (buyers)
      recipientDoc = await admin.firestore()
        .collection("users")
        .doc(recipientId)
        .get();
    }

    if (!recipientDoc.exists) {
      console.log("Recipient not found");
      return;
    }

    const recipientData = recipientDoc.data();
    const fcmToken = recipientData?.fcmToken;

    if (!fcmToken) {
      console.log("No FCM token for recipient");
      return;
    }

    // Send notification
    await sendNotification(
      fcmToken,
      `💬 ${senderName}`,
      messageText || "Sent you a message",
      {
        type: "message",
        senderId: senderId,
        messageId: messageId,
        conversationId: conversationId,
      }
    );
  }
);

/**
 * Trigger: Product stock updated
 * Notify all store staff if stock is low
 */
export const onProductStockUpdate = onDocumentUpdated(
  "stores/{storeId}/products/{productId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const storeId = event.params.storeId;
    const lowStockThreshold = 5;

    if (after.stock <= lowStockThreshold && before.stock > lowStockThreshold) {
      // Get authorized users
      const storeDoc = await admin.firestore().collection("stores").doc(storeId).get();
      if (!storeDoc.exists) return;

      const authorizedUsers = storeDoc.data()?.authorizedUsers || [];
      if (authorizedUsers.length === 0) return;

      // Get FCM tokens
      const tokens: string[] = [];
      for (const userId of authorizedUsers) {
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (userDoc.exists && userDoc.data()?.fcmToken) {
          tokens.push(userDoc.data()!.fcmToken);
        }
      }

      if (tokens.length === 0) return;

      // Send notifications
      for (const token of tokens) {
        await sendNotification(
          token,
          "⚠️ Low Stock Alert",
          `${after.name} is running low (${after.stock} left)`,
          {type: "low_stock", productId: event.params.productId, storeId}
        );
      }
    }
  }
);

/**
 * Callable function: Send bulk notifications
 * For marketing campaigns from seller to followers
 */
export const sendBulkNotification = onCall(
  async (request) => {
    // Verify seller is authenticated
    if (!request.auth) {
      throw new Error("Must be authenticated");
    }

    const {title, body, userIds} = request.data;
    const storeId = request.auth.uid;

    console.log(`📢 Sending bulk notification from store: ${storeId}`);

    // Get FCM tokens for all target users
    const tokens: string[] = [];
    for (const userId of userIds) {
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData?.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      }
    }

    if (tokens.length === 0) {
      return {success: false, message: "No valid tokens found"};
    }

    // Send to all tokens
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        type: "promotion",
        storeId: storeId,
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Sent ${response.successCount} notifications`);

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  }
);
