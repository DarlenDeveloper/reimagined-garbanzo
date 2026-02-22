import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {sendNotificationToStore} from "./helpers";

/**
 * VAPI Webhook Handler
 * Receives events from VAPI (assistant-request, end-of-call-report)
 */
export const vapiWebhook = onRequest(
  {region: "africa-south1"},
  async (req, res): Promise<void> => {
    // Log the raw body for debugging
    console.log("📦 Raw webhook body:", JSON.stringify(req.body, null, 2));
    console.log("📦 Event keys:", Object.keys(req.body));
    console.log("📦 Message type:", req.body.message?.type);
    
    // VAPI sends events in message.type format
    const messageType = req.body.message?.type || req.body.type;
    const event = req.body;

    console.log(`📞 VAPI Webhook - Message Type: ${messageType}`);

    try {
      // Handle assistant-request (for call blocking based on subscription status)
      if (messageType === "assistant-request") {
        const call = event.message?.call || event.call;
        const phoneNumber = call?.phoneNumberId || call?.phoneNumber?.number;

        if (!phoneNumber) {
          res.status(400).send({error: "Phone number not provided"});
          return;
        }

        console.log(`📞 Incoming call to: ${phoneNumber}`);

        // Find store by phone number
        const didsSnapshot = await admin
          .firestore()
          .collection("dids")
          .where("phoneNumber", "==", phoneNumber)
          .limit(1)
          .get();

        if (didsSnapshot.empty) {
          console.error("Store not found for phone:", phoneNumber);
          res.status(404).send({error: "Store not found"});
          return;
        }

        const storeId = didsSnapshot.docs[0].data().storeId;

        // Check subscription status
        const configDoc = await admin
          .firestore()
          .collection("stores")
          .doc(storeId)
          .collection("aiAssistant")
          .doc("config")
          .get();

        if (!configDoc.exists) {
          res.status(404).send({error: "AI config not found"});
          return;
        }

        const config = configDoc.data()!;
        const status = config.subscription?.status;

        // Block calls if not active
        if (status !== "active") {
          console.log(`⛔ Call blocked - subscription status: ${status}`);

          // Return a custom assistant that plays a message and hangs up
          res.status(200).send({
            assistant: {
              firstMessage:
                "This service is currently unavailable. Please contact the store directly. Goodbye.",
              endCallMessage: "Goodbye.",
              endCallFunctionEnabled: true,
              maxDurationSeconds: 10,
            },
          });
          return;
        }

        // Check if over usage limit
        const usedMinutes = config.subscription?.usedMinutes || 0;
        const includedMinutes = config.subscription?.minutesIncluded || 100;

        if (usedMinutes >= includedMinutes) {
          console.log(`⛔ Call blocked - usage limit exceeded: ${usedMinutes}/${includedMinutes}`);

          res.status(200).send({
            assistant: {
              firstMessage:
                "This service has reached its monthly usage limit. Please contact the store directly. Goodbye.",
              endCallMessage: "Goodbye.",
              endCallFunctionEnabled: true,
              maxDurationSeconds: 10,
            },
          });
          return;
        }

        // Allow call to proceed
        console.log(`✅ Call allowed - status: ${status}, usage: ${usedMinutes}/${includedMinutes}`);
        res.status(200).send({success: true});
        return;
      }

      // Handle end-of-call-report
      if (messageType === "end-of-call-report") {
        const call = event.message?.call || event.call;

        if (!call) {
          res.status(400).send({error: "Call data not provided"});
          return;
        }

        console.log(`📞 Call ended: ${call.id}`);

        // Get phone number from call first
        const phoneNumberId = call.phoneNumberId || call.phoneNumber?.id;
        const phoneNumber = call.phoneNumber?.number;

        console.log(`📞 Phone Number ID: ${phoneNumberId}, Number: ${phoneNumber}`);

        // Extract data from message level (VAPI structure)
        const message = event.message;
        const duration = Math.round(message?.durationSeconds || 0);
        const transcript = message?.transcript || "";
        const cost = message?.cost || 0;

        // Extract structured outputs (object format, not array)
        const structuredOutputs = message?.artifact?.structuredOutputs || {};
        
        let callSummary = "";
        let csatScore: number | null = null;

        // Call Summary
        const summaryOutput = structuredOutputs["a356b2a9-fecc-49da-9220-85b5d315e2db"];
        if (summaryOutput) {
          callSummary = summaryOutput.result || "";
        }

        // CSAT
        const csatOutput = structuredOutputs["01b9a819-68cb-41d6-b626-4426af1e89bb"];
        if (csatOutput) {
          csatScore = csatOutput.result;
        }
        
        console.log(`⏱️ Call duration: ${duration}s (${Math.ceil(duration / 60)} minutes)`);
        console.log(`📝 Transcript length: ${transcript.length} chars`);
        console.log(`📋 Summary: ${callSummary ? 'Yes' : 'No'}`);
        console.log(`⭐ CSAT: ${csatScore}`);

        // Find store by phone number ID or number
        let didsSnapshot = await admin
          .firestore()
          .collection("dids")
          .where("vapiPhoneNumberId", "==", phoneNumberId)
          .limit(1)
          .get();

        // Fallback to phone number if not found by ID
        if (didsSnapshot.empty && phoneNumber) {
          didsSnapshot = await admin
            .firestore()
            .collection("dids")
            .where("phoneNumber", "==", phoneNumber)
            .limit(1)
            .get();
        }

        if (didsSnapshot.empty) {
          console.error("Store not found for phone:", phoneNumber || phoneNumberId);
          res.status(404).send({error: "Store not found"});
          return;
        }

        const storeId = didsSnapshot.docs[0].data().storeId;

        // Save call log to subcollection (matching Flutter query path)
        const callLogRef = admin
          .firestore()
          .collection("stores")
          .doc(storeId)
          .collection("aiAssistant")
          .doc("config")
          .collection("callLogs")
          .doc(call.id);

        // Format customer phone number with +256 prefix
        let customerPhone = call.customer?.number || "Unknown";
        if (customerPhone !== "Unknown" && !customerPhone.startsWith("+")) {
          // VAPI sends numbers without country code, add +256 for Uganda
          customerPhone = "+256" + customerPhone;
        }

        await callLogRef.set({
          callId: call.id,
          customerPhone: customerPhone,
          duration: duration,
          transcript: transcript,
          summary: callSummary,
          csatScore: csatScore,
          cost: cost,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Call log saved to: stores/${storeId}/aiAssistant/config/callLogs/${call.id}`);

        // Update usage minutes
        const minutes = Math.ceil(duration / 60);
        await admin
          .firestore()
          .collection("stores")
          .doc(storeId)
          .collection("aiAssistant")
          .doc("config")
          .update({
            "subscription.usedMinutes": admin.firestore.FieldValue.increment(minutes),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log(`📊 Updated usage: +${minutes} minutes`);

        // Send notification to store staff
        const notificationBody = callSummary ||
          `Call from ${call.customer?.number || "customer"} - ${Math.floor(duration / 60)}m ${duration % 60}s`;

        await sendNotificationToStore(
          storeId,
          "📞 New Customer Call",
          notificationBody,
          {
            type: "ai_call",
            callId: call.id,
            storeId: storeId,
          }
        );

        console.log("✅ Notification sent");

        res.status(200).send({success: true});
        return;
      }

      // Unknown event type
      console.log(`⚠️ Unknown message type: ${messageType}`);
      res.status(200).send({success: true});
    } catch (error: any) {
      console.error("❌ Error processing webhook:", error);
      res.status(500).send({error: error.message});
    }
  }
);
