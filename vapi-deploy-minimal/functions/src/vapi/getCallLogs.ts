import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * Get call logs for a store
 * Returns paginated list of call logs
 */
export const getCallLogs = onCall(
  {region: "africa-south1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const {storeId, limit = 20, startAfter = null} = request.data;

    if (!storeId) {
      throw new HttpsError("invalid-argument", "storeId is required");
    }

    try {
      console.log(`📋 Fetching call logs for store: ${storeId}`);

      const callLogsRef = admin
        .firestore()
        .collection(`stores/${storeId}/aiAssistant/callLogs`);

      let query = callLogsRef.orderBy("createdAt", "desc").limit(limit);

      // Pagination support
      if (startAfter) {
        const startAfterDoc = await admin
          .firestore()
          .collection(`stores/${storeId}/aiAssistant/callLogs`)
          .doc(startAfter)
          .get();

        if (startAfterDoc.exists) {
          query = query.startAfter(startAfterDoc);
        }
      }

      const logsSnapshot = await query.get();

      const logs = logsSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate().toISOString(),
      }));

      console.log(`✅ Found ${logs.length} call logs`);

      return {
        success: true,
        logs: logs,
        hasMore: logsSnapshot.docs.length === limit,
        lastDocId: logsSnapshot.docs.length > 0 ?
          logsSnapshot.docs[logsSnapshot.docs.length - 1].id :
          null,
      };
    } catch (error: any) {
      console.error("❌ Error fetching call logs:", error);
      throw new HttpsError("internal", `Failed to fetch call logs: ${error.message}`);
    }
  }
);
