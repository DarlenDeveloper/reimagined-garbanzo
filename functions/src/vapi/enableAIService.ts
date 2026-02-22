import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {VapiClient} from "./vapiClient";
import {
  buildAssistantConfig,
  calculateExpiryDate,
  sendNotificationToStore,
} from "./helpers";
import {VapiPhoneNumberConfig} from "./types";

const vapiPrivateKey = defineSecret("VAPI_PRIVATE_KEY");

/**
 * Enable AI Customer Service for a store
 * Creates VAPI assistant, assigns phone number, sets up subscription
 */
export const enableAIService = onCall(
  {secrets: [vapiPrivateKey], region: "africa-south1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const {storeId} = request.data;

    if (!storeId) {
      throw new HttpsError("invalid-argument", "storeId is required");
    }

    console.log(`🚀 Enabling AI service for store: ${storeId}`);

    try {
      // 1. Check if already enabled
      const existingConfigDoc = await admin
        .firestore()
        .collection("stores")
        .doc(storeId)
        .collection("aiAssistant")
        .doc("config")
        .get();

      if (existingConfigDoc.exists && existingConfigDoc.data()?.enabled) {
        throw new HttpsError(
          "already-exists",
          "AI service is already enabled for this store"
        );
      }

      // 2. Get store data
      const storeDoc = await admin.firestore().collection("stores").doc(storeId).get();

      if (!storeDoc.exists) {
        throw new HttpsError("not-found", "Store not found");
      }

      const storeData = storeDoc.data()!;
      const storeName = storeData.name || storeData.storeName || "Your Store";

      console.log(`📦 Store: ${storeName}`);

      // 3. Get VAPI config
      const vapiConfigDoc = await admin
        .firestore()
        .collection("config")
        .doc("vapi")
        .get();

      if (!vapiConfigDoc.exists) {
        throw new HttpsError(
          "failed-precondition",
          "VAPI configuration not found. Run setup script first."
        );
      }

      const vapiConfig = vapiConfigDoc.data()!;

      // 4. Assign DID from pool
      console.log("📞 Finding available DID...");
      const didsSnapshot = await admin
        .firestore()
        .collection("dids")
        .where("assigned", "==", false)
        .limit(1)
        .get();

      if (didsSnapshot.empty) {
        throw new HttpsError(
          "resource-exhausted",
          "No available phone numbers. Please contact support."
        );
      }

      const didDoc = didsSnapshot.docs[0];
      const didData = didDoc.data();
      const phoneNumber = didData.phoneNumber;

      console.log(`✅ Assigned DID: ${phoneNumber}`);

      // 5. Create VAPI assistant
      const vapiClient = new VapiClient(vapiPrivateKey.value());

      const assistantConfig = buildAssistantConfig(
        storeName,
        vapiConfig.structuredOutputIds,
        vapiConfig.voiceId,
        vapiConfig.voiceModel,
        vapiConfig.llmModel
      );

      const assistant = await vapiClient.createAssistant(assistantConfig);

      console.log(`✅ Created assistant: ${assistant.id}`);

      // 6. Create VAPI phone number
      const phoneNumberConfig: VapiPhoneNumberConfig = {
        provider: "byo-phone-number",
        number: phoneNumber,
        assistantId: assistant.id,
        credentialId: vapiConfig.sipCredentialId,
        name: `${storeName} Main Line`,
        numberE164CheckEnabled: false,
        server: {
          url: "https://africa-south1-purlstores-za.cloudfunctions.net/vapiWebhook",
          timeoutSeconds: 20,
          backoffPlan: {
            type: "fixed",
            maxRetries: 3,
            baseDelaySeconds: 1,
            excludedStatusCodes: [400, 401, 403, 404],
          },
        },
      };

      const phoneNumberObj = await vapiClient.createPhoneNumber(phoneNumberConfig);

      console.log(`✅ Created phone number: ${phoneNumberObj.id}`);

      // 7. Update DID as assigned
      await didDoc.ref.update({
        assigned: true,
        storeId: storeId,
        vapiPhoneNumberId: phoneNumberObj.id,
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 8. Calculate subscription dates
      const expiryDate = calculateExpiryDate();

      // 9. Save AI service config
      await admin
        .firestore()
        .collection("stores")
        .doc(storeId)
        .collection("aiAssistant")
        .doc("config")
        .set({
          enabled: true,
          status: "active",
          vapiAssistantId: assistant.id,
          vapiPhoneNumberId: phoneNumberObj.id,
          didId: didDoc.id,
          phoneNumber: phoneNumber,
          storeName: storeName,
          subscription: {
            plan: vapiConfig.subscriptionPlan.name,
            monthlyFee: vapiConfig.subscriptionPlan.monthlyFee,
            currency: vapiConfig.subscriptionPlan.currency,
            startDate: admin.firestore.FieldValue.serverTimestamp(),
            expiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
            gracePeriodEndsAt: null,
            minutesIncluded: vapiConfig.subscriptionPlan.minutesIncluded,
            usedMinutes: 0,
            status: "active",
            renewalCount: 0,
            lastRenewalDate: null,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log("✅ Saved AI service config");

      // 10. Send notification to store
      await sendNotificationToStore(
        storeId,
        "🎉 AI Customer Service Activated!",
        `Your AI assistant Riley is ready. Phone: ${phoneNumber}`,
        {
          type: "ai_service_enabled",
          phoneNumber: phoneNumber,
        }
      );

      console.log(`✅ AI service enabled successfully for ${storeName}`);

      return {
        success: true,
        phoneNumber: phoneNumber,
        assistantId: assistant.id,
        expiryDate: expiryDate.toISOString(),
        message: "AI Customer Service activated successfully",
      };
    } catch (error: any) {
      console.error("❌ Error enabling AI service:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        `Failed to enable AI service: ${error.message}`
      );
    }
  }
);
