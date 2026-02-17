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
    const total = order.total || 0;
    // Get currency from first item (all items in an order have same currency)
    const currency = order.items?.[0]?.currency || "UGX";

    // Get FCM tokens from /users/{userId} - supports both old and new format
    const tokens: string[] = [];
    for (const userId of authorizedUsers) {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        // Support new array format
        const userTokens = userData?.fcmTokens || [];
        tokens.push(...userTokens);
        // Support old single token format (backward compatibility)
        if (userData?.fcmToken && !userTokens.includes(userData.fcmToken)) {
          tokens.push(userData.fcmToken);
        }
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
        `${storeName} has a new order for ${itemCount} item${itemCount > 1 ? 's' : ''} totalling ${currency} ${total.toFixed(2)}`,
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
        body: `${storeName} has a new order for ${itemCount} item${itemCount > 1 ? 's' : ''} totalling ${currency} ${total.toFixed(2)}`,
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

    // Determine if recipient is a store or user
    const isRecipientStore = conversationData?.storeId === recipientId;
    
    let fcmTokens: string[] = [];

    if (isRecipientStore) {
      // Recipient is a store - get FCM tokens from all authorized users
      const storeDoc = await admin.firestore()
        .collection("stores")
        .doc(recipientId)
        .get();
      
      if (!storeDoc.exists) {
        console.log("Store not found");
        return;
      }

      const authorizedUsers = storeDoc.data()?.authorizedUsers || [];
      
      // Get FCM tokens from all authorized users
      for (const userId of authorizedUsers) {
        const userDoc = await admin.firestore()
          .collection("users")
          .doc(userId)
          .get();
        
        if (userDoc.exists) {
          const userData = userDoc.data();
          const userTokens = userData?.fcmTokens || [];
          fcmTokens.push(...userTokens);
          // Support old format
          if (userData?.fcmToken && !userTokens.includes(userData.fcmToken)) {
            fcmTokens.push(userData.fcmToken);
          }
        }
      }
    } else {
      // Recipient is a user (buyer)
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(recipientId)
        .get();
      
      if (!userDoc.exists) {
        console.log("User not found");
        return;
      }

      const userData = userDoc.data();
      fcmTokens = userData?.fcmTokens || [];
      // Support old format
      if (userData?.fcmToken && !fcmTokens.includes(userData.fcmToken)) {
        fcmTokens.push(userData.fcmToken);
      }
    }

    if (fcmTokens.length === 0) {
      console.log("No FCM tokens for recipient");
      return;
    }

    // Send notification to all recipient devices
    for (const token of fcmTokens) {
      await sendNotification(
        token,
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

    // Save notification to recipient's notifications collection
    // Check if recipient is a store (seller) or user (buyer)
    const isStore = await admin.firestore()
      .collection("stores")
      .doc(recipientId)
      .get()
      .then((doc) => doc.exists);

    if (isStore) {
      // Save to store's notifications
      await admin.firestore()
        .collection("stores")
        .doc(recipientId)
        .collection("notifications")
        .add({
          title: `💬 ${senderName}`,
          body: messageText || "Sent you a message",
          type: "message",
          data: {senderId, messageId, conversationId},
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } else {
      // Save to user's notifications
      await admin.firestore()
        .collection("users")
        .doc(recipientId)
        .collection("notifications")
        .add({
          title: `💬 ${senderName}`,
          body: messageText || "Sent you a message",
          type: "message",
          data: {senderId, messageId, conversationId},
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    console.log(`✅ Message notification sent and saved`);
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

      // Get FCM tokens - supports both old and new format
      const tokens: string[] = [];
      for (const userId of authorizedUsers) {
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          // Support new array format
          const userTokens = userData?.fcmTokens || [];
          tokens.push(...userTokens);
          // Support old single token format (backward compatibility)
          if (userData?.fcmToken && !userTokens.includes(userData.fcmToken)) {
            tokens.push(userData.fcmToken);
          }
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

    // Get FCM tokens for all target users - supports both old and new format
    const tokens: string[] = [];
    for (const userId of userIds) {
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (userDoc.exists) {
        const userData = userDoc.data();
        // Support new array format
        const userTokens = userData?.fcmTokens || [];
        tokens.push(...userTokens);
        // Support old single token format (backward compatibility)
        if (userData?.fcmToken && !userTokens.includes(userData.fcmToken)) {
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


/**
 * Notify nearby couriers when a new delivery is created
 * Triggers when a delivery document is created with status="searching"
 */
export const notifyNearbyCouriers = onDocumentCreated(
  "deliveries/{deliveryId}",
  async (event) => {
    const delivery = event.data?.data();
    if (!delivery || delivery.status !== "searching" || delivery.deliveryType !== "purl_courier") {
      return;
    }

    const deliveryId = event.params.deliveryId;
    const storeLocation = delivery.storeLocation;
    const deliveryFee = delivery.deliveryFee;
    const storeName = delivery.storeName;

    console.log(`🔍 Finding couriers near ${storeName} for delivery ${deliveryId}`);

    // Find nearby couriers (within 2km radius)
    const couriersSnapshot = await admin.firestore()
      .collection("couriers")
      .where("verified", "==", true)
      .where("isOnline", "==", true)
      .get();

    let notificationsSent = 0;

    for (const courierDoc of couriersSnapshot.docs) {
      const courier = courierDoc.data();
      const courierLocation = courier.currentLocation;

      // Skip if courier doesn't have location
      if (!courierLocation) continue;

      // Calculate distance (simple approximation)
      const distance = calculateDistance(
        storeLocation.latitude,
        storeLocation.longitude,
        courierLocation.latitude,
        courierLocation.longitude
      );

      // Only notify couriers within 2km
      if (distance > 2) continue;

      // Get courier's FCM tokens
      const fcmTokens = courier.fcmTokens || [];

      for (const token of fcmTokens) {
        try {
          await admin.messaging().send({
            token,
            notification: {
              title: "New Delivery Request",
              body: `UGX ${deliveryFee.toLocaleString()} • ${distance.toFixed(1)}km away`,
            },
            data: {
              type: "delivery_request",
              deliveryId: deliveryId,
              deliveryFee: deliveryFee.toString(),
              distance: distance.toString(),
              storeName: storeName,
            },
            android: {
              priority: "high",
              notification: {
                sound: "notification",
                channelId: "purl_courier_delivery_requests",
                priority: "high",
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "notification.mp3",
                  badge: 1,
                  contentAvailable: true,
                },
              },
            },
          });
          
          // Create in-app notification
          await admin.firestore()
            .collection("couriers")
            .doc(courierDoc.id)
            .collection("notifications")
            .add({
              type: "delivery_request",
              title: "New Delivery Request",
              message: `Order from ${storeName} • UGX ${deliveryFee.toLocaleString()} • ${distance.toFixed(1)}km away`,
              data: {
                deliveryId: deliveryId,
                deliveryFee: deliveryFee,
                distance: distance,
                storeName: storeName,
              },
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          
          notificationsSent++;
          console.log(`✅ Notified courier ${courierDoc.id}`);
        } catch (error) {
          console.error(`❌ Error notifying courier ${courierDoc.id}:`, error);
        }
      }
    }

    console.log(`📤 Sent ${notificationsSent} notifications for delivery ${deliveryId}`);

    // Update delivery with notification count
    await event.data?.ref.update({
      notificationsSent: notificationsSent,
      notifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);

/**
 * Calculate distance between two coordinates (Haversine formula)
 */
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Trigger: Delivery status updated
 * Sync delivery status with order status in both collections
 */
export const onDeliveryStatusChanged = onDocumentUpdated(
  "deliveries/{deliveryId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    
    if (!before || !after) return;

    // Check if status changed
    if (before.status === after.status) return;

    const orderId = after.orderId;
    const storeId = after.storeId;
    const newStatus = after.status;

    if (!orderId || !storeId) {
      console.error("Missing orderId or storeId in delivery document");
      return;
    }

    console.log(`📦 Delivery status changed from ${before.status} to ${newStatus} for order ${orderId}`);

    // Map delivery status to order status
    let orderStatus = "pending";
    const updateData: any = {
      status: orderStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    switch (newStatus) {
      case "searching":
      case "assigned":
        orderStatus = "confirmed";
        break;
      case "picked_up":
      case "in_transit":
        orderStatus = "shipped";
        break;
      case "delivered":
        orderStatus = "delivered";
        updateData.deliveredAt = admin.firestore.FieldValue.serverTimestamp();
        break;
      case "cancelled":
      case "no_courier_available":
        orderStatus = "pending"; // Keep as pending if delivery failed
        break;
      default:
        orderStatus = "pending";
    }

    updateData.status = orderStatus;

    try {
      // Update order in store's orders collection
      await admin.firestore()
        .collection("stores")
        .doc(storeId)
        .collection("orders")
        .doc(orderId)
        .update(updateData);

      console.log(`✅ Store order ${orderId} updated to ${orderStatus}`);

      // Get the order to find the buyer's userId
      const orderDoc = await admin.firestore()
        .collection("stores")
        .doc(storeId)
        .collection("orders")
        .doc(orderId)
        .get();

      if (orderDoc.exists) {
        const orderData = orderDoc.data();
        const buyerId = orderData?.userId;

        if (buyerId) {
          // Update order in user's orders collection
          await admin.firestore()
            .collection("users")
            .doc(buyerId)
            .collection("orders")
            .doc(orderId)
            .update({
              status: orderStatus,
            });

          console.log(`✅ User order ${orderId} updated to ${orderStatus} for buyer ${buyerId}`);
        }
      }
    } catch (error) {
      console.error(`❌ Error updating order ${orderId}:`, error);
    }
  }
);


/**
 * Trigger: Delivery accepted by courier
 * Create notification for courier
 */
export const onDeliveryAccepted = onDocumentUpdated(
  "deliveries/{deliveryId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    
    if (!before || !after) return;

    // Check if status changed to "assigned"
    if (before.status !== "assigned" && after.status === "assigned") {
      const courierId = after.assignedCourierId;
      const orderNumber = after.orderNumber;
      const deliveryFee = after.deliveryFee;

      if (!courierId) return;

      console.log(`📦 Delivery ${event.params.deliveryId} accepted by courier ${courierId}`);

      try {
        // Create in-app notification for courier
        await admin.firestore()
          .collection("couriers")
          .doc(courierId)
          .collection("notifications")
          .add({
            type: "delivery_accepted",
            title: "Delivery Accepted",
            message: `You accepted order ${orderNumber}. Pickup the package and start delivery.`,
            data: {
              deliveryId: event.params.deliveryId,
              orderNumber: orderNumber,
              deliveryFee: deliveryFee,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log(`✅ Created acceptance notification for courier ${courierId}`);
      } catch (error) {
        console.error(`❌ Error creating acceptance notification:`, error);
      }
    }

    // Check if status changed to "delivered"
    if (before.status !== "delivered" && after.status === "delivered") {
      const courierId = after.assignedCourierId;
      const orderNumber = after.orderNumber;
      const deliveryFee = after.deliveryFee;

      if (!courierId) return;

      console.log(`📦 Delivery ${event.params.deliveryId} completed by courier ${courierId}`);

      try {
        // Create in-app notification for courier
        await admin.firestore()
          .collection("couriers")
          .doc(courierId)
          .collection("notifications")
          .add({
            type: "delivery_completed",
            title: "Delivery Completed",
            message: `You earned UGX ${deliveryFee.toLocaleString()} from order ${orderNumber}`,
            data: {
              deliveryId: event.params.deliveryId,
              orderNumber: orderNumber,
              deliveryFee: deliveryFee,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log(`✅ Created completion notification for courier ${courierId}`);
      } catch (error) {
        console.error(`❌ Error creating completion notification:`, error);
      }
    }
  }
);
