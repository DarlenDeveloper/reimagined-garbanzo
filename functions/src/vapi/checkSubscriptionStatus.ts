import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {deleteAIService} from "./deleteAIService";
import {sendNotificationToStore, calculateGracePeriodEnd} from "./helpers";

const vapiPrivateKey = defineSecret("VAPI_PRIVATE_KEY");

/**
 * Scheduled function to check subscription status
 * Runs daily at 2 AM Africa/Johannesburg time
 * - Moves expired subscriptions to grace period
 * - Deletes services after grace period ends
 * - Sends notifications at key milestones
 */
export const checkSubscriptionStatus = onSchedule(
  {
    schedule: "0 2 * * *", // 2 AM daily
    timeZone: "Africa/Johannesburg",
    region: "africa-south1",
    secrets: [vapiPrivateKey],
  },
  async () => {
    console.log("🔍 Checking subscription statuses...");

    const now = admin.firestore.Timestamp.now();

    try {
      // 1. Find subscriptions that expired today (move to grace period)
      const expiredSnapshot = await admin
        .firestore()
        .collectionGroup("aiAssistant")
        .where("subscription.expiryDate", "<=", now)
        .where("subscription.status", "==", "active")
        .get();

      console.log(`Found ${expiredSnapshot.docs.length} expired subscriptions`);

      for (const doc of expiredSnapshot.docs) {
        const storeId = doc.ref.parent.parent!.id;
        const config = doc.data();

        const expiryDate = config.subscription?.expiryDate?.toDate();
        const gracePeriodEndsAt = calculateGracePeriodEnd(expiryDate);

        await doc.ref.update({
          status: "grace_period",
          "subscription.status": "grace_period",
          "subscription.gracePeriodEndsAt":
            admin.firestore.Timestamp.fromDate(gracePeriodEndsAt),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Notify store
        await sendNotificationToStore(
          storeId,
          "⚠️ AI Subscription Expired",
          `Your AI service has expired. You have 30 days to renew before your data is deleted. Renew now to continue service.`,
          {
            type: "ai_subscription_expired",
            gracePeriodEndsAt: gracePeriodEndsAt.toISOString(),
          }
        );

        console.log(`⏰ Store ${storeId} entered grace period`);
      }

      // 2. Find grace periods that ended today (delete service)
      const gracePeriodEndedSnapshot = await admin
        .firestore()
        .collectionGroup("aiAssistant")
        .where("subscription.gracePeriodEndsAt", "<=", now)
        .where("subscription.status", "==", "grace_period")
        .get();

      console.log(`Found ${gracePeriodEndedSnapshot.docs.length} grace periods ended`);

      for (const doc of gracePeriodEndedSnapshot.docs) {
        const storeId = doc.ref.parent.parent!.id;

        try {
          await deleteAIService(storeId, vapiPrivateKey.value());
          console.log(`🗑️ Store ${storeId} AI service deleted after grace period`);
        } catch (error) {
          console.error(`Error deleting service for store ${storeId}:`, error);
        }
      }

      // 3. Send 7-day expiry warnings
      const sevenDaysFromNow = new Date();
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
      const sevenDaysTimestamp = admin.firestore.Timestamp.fromDate(sevenDaysFromNow);

      const expiringSnapshot = await admin
        .firestore()
        .collectionGroup("aiAssistant")
        .where("subscription.expiryDate", "<=", sevenDaysTimestamp)
        .where("subscription.expiryDate", ">", now)
        .where("subscription.status", "==", "active")
        .get();

      console.log(`Found ${expiringSnapshot.docs.length} subscriptions expiring in 7 days`);

      for (const doc of expiringSnapshot.docs) {
        const storeId = doc.ref.parent.parent!.id;
        const config = doc.data();
        const expiryDate = config.subscription?.expiryDate?.toDate();

        await sendNotificationToStore(
          storeId,
          "⏰ AI Subscription Expiring Soon",
          `Your AI Customer Service expires on ${expiryDate?.toLocaleDateString()}. Renew now to avoid service interruption.`,
          {
            type: "ai_subscription_expiring",
            expiryDate: expiryDate?.toISOString() || "",
            daysRemaining: "7",
          }
        );

        console.log(`📧 Sent 7-day warning to store ${storeId}`);
      }

      // 4. Send 3-day deletion warnings (grace period ending)
      const threeDaysFromNow = new Date();
      threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);
      const threeDaysTimestamp = admin.firestore.Timestamp.fromDate(threeDaysFromNow);

      const deletionWarningSnapshot = await admin
        .firestore()
        .collectionGroup("aiAssistant")
        .where("subscription.gracePeriodEndsAt", "<=", threeDaysTimestamp)
        .where("subscription.gracePeriodEndsAt", ">", now)
        .where("subscription.status", "==", "grace_period")
        .get();

      console.log(`Found ${deletionWarningSnapshot.docs.length} services to be deleted in 3 days`);

      for (const doc of deletionWarningSnapshot.docs) {
        const storeId = doc.ref.parent.parent!.id;

        await sendNotificationToStore(
          storeId,
          "🚨 Final Warning: AI Service Deletion",
          "Your AI service and call logs will be permanently deleted in 3 days. Renew now to keep your data.",
          {
            type: "ai_deletion_warning",
            daysRemaining: "3",
          }
        );

        console.log(`📧 Sent 3-day deletion warning to store ${storeId}`);
      }

      console.log("✅ Subscription status check complete");
    } catch (error) {
      console.error("❌ Error checking subscription status:", error);
      throw error;
    }
  }
);
