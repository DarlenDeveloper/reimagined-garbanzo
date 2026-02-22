import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {calculateExpiryDate, sendNotificationToStore} from "./helpers";

/**
 * Renew AI subscription for a store
 * Requires payment verification
 */
export const renewAISubscription = onCall(
  {region: "africa-south1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const {storeId, paymentId} = request.data;

    if (!storeId || !paymentId) {
      throw new HttpsError("invalid-argument", "storeId and paymentId are required");
    }

    console.log(`🔄 Renewing AI subscription for store: ${storeId}`);

    try {
      // 1. Verify payment
      const paymentDoc = await admin
        .firestore()
        .collection("payments")
        .doc(paymentId)
        .get();

      if (!paymentDoc.exists) {
        throw new HttpsError("not-found", "Payment not found");
      }

      const paymentData = paymentDoc.data()!;

      if (paymentData.status !== "approved" && paymentData.status !== "successful") {
        throw new HttpsError(
          "failed-precondition",
          "Payment not approved. Please complete payment first."
        );
      }

      // Check if payment already used
      if (paymentData.usedFor === "ai_subscription_renewal") {
        throw new HttpsError("already-exists", "Payment already used for renewal");
      }

      // 2. Get current config
      const configDoc = await admin
        .firestore()
        .collection("stores")
        .doc(storeId)
        .collection("aiAssistant")
        .doc("config")
        .get();

      if (!configDoc.exists) {
        throw new HttpsError("not-found", "AI service not configured");
      }

      const currentConfig = configDoc.data()!;
      const currentStatus = currentConfig.subscription?.status;

      console.log(`Current status: ${currentStatus}`);

      // 3. Calculate new expiry date
      const newExpiryDate = calculateExpiryDate();

      // 4. Update subscription
      await configDoc.ref.update({
        enabled: true,
        status: "active",
        "subscription.status": "active",
        "subscription.expiryDate": admin.firestore.Timestamp.fromDate(newExpiryDate),
        "subscription.gracePeriodEndsAt": null,
        "subscription.usedMinutes": 0, // Reset usage
        "subscription.renewalCount": admin.firestore.FieldValue.increment(1),
        "subscription.lastRenewalDate": admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Subscription renewed");

      // 5. Mark payment as used
      await paymentDoc.ref.update({
        usedFor: "ai_subscription_renewal",
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 6. Record payment in AI service payments
      await admin
        .firestore()
        .collection(`stores/${storeId}/aiAssistant/payments`)
        .add({
          paymentId: paymentId,
          amount: paymentData.amount,
          currency: paymentData.currency,
          type: "renewal",
          status: "completed",
          previousStatus: currentStatus,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // 7. Send notification
      await sendNotificationToStore(
        storeId,
        "✅ AI Subscription Renewed",
        `Your AI Customer Service has been renewed until ${newExpiryDate.toLocaleDateString()}`,
        {
          type: "ai_subscription_renewed",
          expiryDate: newExpiryDate.toISOString(),
        }
      );

      console.log(`✅ AI subscription renewed for store ${storeId}`);

      return {
        success: true,
        expiryDate: newExpiryDate.toISOString(),
        status: "active",
        message: "Subscription renewed successfully",
      };
    } catch (error: any) {
      console.error("❌ Error renewing subscription:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", `Failed to renew subscription: ${error.message}`);
    }
  }
);
