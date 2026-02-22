import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {VapiClient} from "./vapiClient";
import {sendNotificationToStore} from "./helpers";

const vapiPrivateKey = defineSecret("VAPI_PRIVATE_KEY");

/**
 * Delete AI service for a store
 * Removes VAPI assistant, phone number, archives call logs, unassigns DID
 * This is an internal function called by scheduled checks or manual deletion
 */
export async function deleteAIService(storeId: string, apiKey: string): Promise<void> {
  console.log(`🗑️ Deleting AI service for store: ${storeId}`);

  try {
    // 1. Get current config
    const configDoc = await admin
      .firestore()
      .collection("stores")
      .doc(storeId)
      .collection("aiAssistant")
      .doc("config")
      .get();

    if (!configDoc.exists) {
      console.log("Config not found, nothing to delete");
      return;
    }

    const config = configDoc.data()!;

    // 2. Delete VAPI assistant
    if (config.vapiAssistantId) {
      try {
        const vapiClient = new VapiClient(apiKey);
        await vapiClient.deleteAssistant(config.vapiAssistantId);
        console.log(`✅ Deleted VAPI assistant: ${config.vapiAssistantId}`);
      } catch (error) {
        console.error("Error deleting assistant:", error);
        // Continue even if deletion fails
      }
    }

    // 3. Delete VAPI phone number
    if (config.vapiPhoneNumberId) {
      try {
        const vapiClient = new VapiClient(apiKey);
        await vapiClient.deletePhoneNumber(config.vapiPhoneNumberId);
        console.log(`✅ Deleted VAPI phone number: ${config.vapiPhoneNumberId}`);
      } catch (error) {
        console.error("Error deleting phone number:", error);
        // Continue even if deletion fails
      }
    }

    // 4. Unassign DID (return to pool)
    if (config.didId) {
      await admin
        .firestore()
        .collection("dids")
        .doc(config.didId)
        .update({
          assigned: false,
          storeId: null,
          vapiPhoneNumberId: null,
          assignedAt: null,
          unassignedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      console.log(`✅ DID returned to pool: ${config.phoneNumber}`);
    }

    // 5. Archive call logs
    const callLogsQuery = await admin
      .firestore()
      .collection(`stores/${storeId}/aiAssistant/callLogs`)
      .get();

    if (!callLogsQuery.empty) {
      const batch = admin.firestore().batch();

      for (const logDoc of callLogsQuery.docs) {
        // Copy to archive
        const archiveRef = admin
          .firestore()
          .collection(`stores/${storeId}/aiAssistant/archivedCallLogs`)
          .doc(logDoc.id);

        batch.set(archiveRef, {
          ...logDoc.data(),
          archivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Delete original
        batch.delete(logDoc.ref);
      }

      await batch.commit();
      console.log(`✅ Archived ${callLogsQuery.docs.length} call logs`);
    }

    // 6. Update config to expired status
    await configDoc.ref.update({
      enabled: false,
      status: "expired",
      "subscription.status": "expired",
      vapiAssistantId: null,
      vapiPhoneNumberId: null,
      phoneNumber: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Config updated to expired");

    // 7. Send notification to store
    await sendNotificationToStore(
      storeId,
      "AI Service Removed",
      "Your AI Customer Service has been removed due to expired subscription. You can reactivate anytime.",
      {
        type: "ai_service_deleted",
      }
    );

    console.log(`✅ AI service deleted successfully for store ${storeId}`);
  } catch (error) {
    console.error(`❌ Error deleting AI service for store ${storeId}:`, error);
    throw error;
  }
}

/**
 * Export a callable version for manual deletion (admin use)
 */
export {vapiPrivateKey};
