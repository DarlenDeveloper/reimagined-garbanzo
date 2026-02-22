import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * Get AI service configuration for a store
 */
export const getAIConfig = onCall(
  {region: "africa-south1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const {storeId} = request.data;

    if (!storeId) {
      throw new HttpsError("invalid-argument", "storeId is required");
    }

    try {
      const configDoc = await admin
        .firestore()
        .collection("stores")
        .doc(storeId)
        .collection("aiAssistant")
        .doc("config")
        .get();

      if (!configDoc.exists) {
        return {
          success: true,
          enabled: false,
          config: null,
        };
      }

      const config = configDoc.data()!;

      // Convert timestamps to ISO strings
      const formattedConfig = {
        ...config,
        subscription: {
          ...config.subscription,
          startDate: config.subscription?.startDate?.toDate().toISOString(),
          expiryDate: config.subscription?.expiryDate?.toDate().toISOString(),
          gracePeriodEndsAt: config.subscription?.gracePeriodEndsAt?.toDate().toISOString(),
          lastRenewalDate: config.subscription?.lastRenewalDate?.toDate().toISOString(),
        },
        createdAt: config.createdAt?.toDate().toISOString(),
        updatedAt: config.updatedAt?.toDate().toISOString(),
      };

      return {
        success: true,
        enabled: config.enabled,
        config: formattedConfig,
      };
    } catch (error: any) {
      console.error("❌ Error fetching AI config:", error);
      throw new HttpsError("internal", `Failed to fetch AI config: ${error.message}`);
    }
  }
);
