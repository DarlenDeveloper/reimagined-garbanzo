import * as admin from "firebase-admin";
import {VapiAssistantConfig} from "./types";

/**
 * Generate the system prompt for Riley assistant
 */
export function generateSystemPrompt(storeName: string): string {
  return `[Identity]
You are Riley, the customer care assistant for ${storeName}, the physical and online retail store. Your sole focus is assisting ${storeName} customers with any questions or issues related to in-store services, purchases, or orders made through the POP app. You help with questions about orders, in-store purchases, resolving missing or delayed store orders or deliveries, general inquiries about ${storeName} retail operations, collecting troubleshooting information, and providing support or next steps for ${storeName} shoppers. You do not have the ability to look up or access specific order information.

[Style]
- Sound upbeat, approachable, and professional at all times.
- Use clear, simple, and personable language.
- Employ natural conversational elements like, "Let me check that for you," or "Just a moment while I help you out."
- Sparingly add brief, natural hesitations ("um," "let's see," short pause) to enhance human-like delivery.
- Avoid jargon or technical terms unless necessary; offer quick explanations if they do arise.

[Response Guidelines]
- Confirm and repeat order numbers, item names, and addresses clearly, spelling out details if needed.
- Present instructions or questions one at a time, always waiting for the customer's response before moving forward.
- Keep responses concise and focused—ask one question or provide one instruction at a time.
- Use gentle affirmations ("Got it," "Thank you," "Perfect") to acknowledge customer input.
- Clearly enunciate numbers or support codes, speaking digits slowly and carefully.
- Never mention tool names, apps, or internal processes to customers.

[Task & Goals]
1. Greet the customer, introducing yourself as Riley from ${storeName} customer care. Example: "Hi! This is Riley, your ${storeName} customer care assistant. How can I help you today?"
2. Listen for the customer's needs—such as questions about in-store purchases, order confirmation, delivery, missing or delayed store orders, wrong items, product returns, or general store policies.
3. If a customer needs help with an order, delivery, or return:
   a. Kindly ask for their ${storeName} order number and clearly emphasize the need for the name on the order as well. For example: "To assist you, could you please provide your ${storeName} order number, and the full name the order was placed under? Having both helps ensure accurate support."
   <wait for customer response>
   b. Explain that, at this time, you are unable to look up specific order details yourself but can still guide them on what to do next or connect them with a team member who can help.
   c. For problems with delivery (e.g., delayed, missing, damaged, or wrong items):
      - Ask the customer to describe the issue and confirm all relevant details, such as delivery address and items.
      - Let the customer know you can provide general support steps and offer to connect them to a human representative for specific issues.
   d. For returns or cancellations:
      - Ask for their order details and the reason for return or cancellation.
      - Provide high-level instructions on the ${storeName} return/cancellation policy and suggest visiting the store or contacting support directly. Offer to connect them to a human representative if needed.
4. For any questions about ${storeName} store policies, hours, locations, or general information, answer clearly and directly.
5. Always wait for the customer's reply before moving to the next step.
6. If an issue cannot be resolved (invalid info, unresolved problems, or anything requiring account/order lookup), offer to escalate to human support. If escalation is needed, do not say anything to the customer; silently trigger the transfer tool.
7. When an issue is addressed, briefly summarize support provided and ask if the customer needs anything else. Example: "I've shared the steps you can take for your delivery issue. Is there anything else I can help you with today?"

[Error Handling / Fallback]
- If customer input is unclear, politely ask for clarification ("Could you please repeat that?" or "I'm sorry, I didn't catch the order number or the name. Could you say those again slowly?")
- If an order cannot be found or a situation is beyond your abilities, apologize, state the limitation, and offer to connect them with a human agent if needed.
- Ask explicit questions to fill in any missing details; never assume information.
- If you need to escalate to live support, do not say anything aloud—just trigger the transfer tool silently.
- If the customer is silent or seems lost, offer help and suggest connecting them with a live representative if needed.

[Call Closing]
- Confirm that all questions or issues are resolved before ending the call ("Is there anything else I can assist you with today?")
- End with a warm thank you: "Thank you for shopping with ${storeName}. Have a wonderful day!"`;
}

/**
 * Build complete VAPI assistant configuration
 */
export function buildAssistantConfig(
  storeName: string,
  structuredOutputIds: string[],
  voiceId: string,
  voiceModel: string,
  llmModel: string
): VapiAssistantConfig {
  return {
    name: `Riley - ${storeName}`,
    voice: {
      model: voiceModel,
      voiceId: voiceId,
      provider: "11labs",
      stability: 0.5,
      similarityBoost: 0.75,
      fallbackPlan: {
        voices: [
          {
            model: "eleven_turbo_v2_5",
            voiceId: "TcAStCk0faGcHdNIFX23",
            provider: "11labs",
            stability: 0.5,
            similarityBoost: 0.75,
          },
        ],
      },
    },
    model: {
      model: llmModel,
      provider: "openai",
      maxTokens: 2500,
      temperature: 0.3,
      messages: [
        {
          role: "system",
          content: generateSystemPrompt(storeName),
        },
      ],
    },
    firstMessage: `Thank you for calling Riley from ${storeName}. How may I help you?`,
    voicemailMessage: "Hey, can you please callback, Thanks!",
    endCallMessage: "Goodbye.",
    endCallFunctionEnabled: true,
    transcriber: {
      model: "nova-3",
      language: "en",
      provider: "deepgram",
      endpointing: 150,
      fallbackPlan: {
        transcribers: [
          {
            model: "flux-general-en",
            language: "en",
            provider: "deepgram",
          },
        ],
      },
    },
    clientMessages: [
      "conversation-update",
      "function-call",
      "hang",
      "model-output",
      "speech-update",
      "status-update",
      "transfer-update",
      "transcript",
      "tool-calls",
      "user-interrupted",
      "voice-input",
      "workflow.node.started",
      "assistant.started",
    ],
    serverMessages: [
      "conversation-update",
      "end-of-call-report",
      "function-call",
      "hang",
      "speech-update",
      "status-update",
      "tool-calls",
      "transfer-destination-request",
      "handoff-destination-request",
      "user-interrupted",
      "assistant.started",
    ],
    serverUrl: "https://africa-south1-purlstores-za.cloudfunctions.net/vapiWebhook",
    endCallPhrases: ["goodbye", "talk to you soon"],
    hipaaEnabled: false,
    maxDurationSeconds: 300, // 5 minutes
    analysisPlan: {
      summaryPlan: {enabled: false},
      successEvaluationPlan: {enabled: false},
    },
    artifactPlan: {
      recordingEnabled: false,
      structuredOutputIds: structuredOutputIds,
    },
    messagePlan: {
      idleMessages: ["Are you still there?"],
    },
    startSpeakingPlan: {
      waitSeconds: 0.4,
      smartEndpointingEnabled: "livekit",
    },
    compliancePlan: {
      hipaaEnabled: false,
      pciEnabled: false,
    },
  };
}

/**
 * Send push notification to store staff
 */
export async function sendNotificationToStore(
  storeId: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  try {
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

    // Get FCM tokens from all authorized users
    const tokens: string[] = [];
    for (const userId of authorizedUsers) {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();

      if (userDoc.exists) {
        const userData = userDoc.data();
        const userTokens = userData?.fcmTokens || [];
        tokens.push(...userTokens);

        // Support old format
        if (userData?.fcmToken && !userTokens.includes(userData.fcmToken)) {
          tokens.push(userData.fcmToken);
        }
      }
    }

    if (tokens.length === 0) {
      console.log("No FCM tokens");
      return;
    }

    // Send to all tokens
    for (const token of tokens) {
      try {
        await admin.messaging().send({
          token,
          notification: {title, body},
          data,
          android: {
            priority: "high",
            notification: {
              sound: "notification",
              channelId: "purl_seller_channel_v2",
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
      } catch (error) {
        console.error(`Error sending notification to token:`, error);
      }
    }

    // Save to notifications collection
    await admin
      .firestore()
      .collection("stores")
      .doc(storeId)
      .collection("notifications")
      .add({
        title,
        body,
        type: data.type || "ai_service",
        data,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log(`✅ Sent notifications to ${tokens.length} device(s)`);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
}

/**
 * Calculate expiry date (30 days from now)
 */
export function calculateExpiryDate(): Date {
  const expiryDate = new Date();
  expiryDate.setDate(expiryDate.getDate() + 30);
  return expiryDate;
}

/**
 * Calculate grace period end date (30 days from expiry)
 */
export function calculateGracePeriodEnd(expiryDate: Date): Date {
  const gracePeriodEnd = new Date(expiryDate);
  gracePeriodEnd.setDate(gracePeriodEnd.getDate() + 30);
  return gracePeriodEnd;
}
