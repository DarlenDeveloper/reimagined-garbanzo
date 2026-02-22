import * as admin from "firebase-admin";

admin.initializeApp();

async function setupVapiConfig() {
  console.log("🔧 Setting up VAPI configuration...");

  await admin.firestore().collection("config").doc("vapi").set({
    structuredOutputIds: [
      "a356b2a9-fecc-49da-9220-85b5d315e2db", // Call Summary
      "01b9a819-68cb-41d6-b626-4426af1e89bb", // CSAT
    ],
    sipCredentialId: "25718c8b-4388-4b59-ad0c-e2c7b8ea2147",
    voiceId: "GDzHdQOi6jjf8zaXhCYD",
    voiceModel: "eleven_turbo_v2_5",
    llmModel: "gpt-4o-mini",
    subscriptionPlan: {
      name: "ai_basic",
      monthlyFee: 20, // USD
      currency: "USD",
      minutesIncluded: 100,
      costPerMinute: 0.20, // Internal tracking only
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("✅ VAPI config created successfully");
  console.log("📋 Configuration:");
  console.log("   - SIP Credential ID: 25718c8b-4388-4b59-ad0c-e2c7b8ea2147");
  console.log("   - Voice: Riley (GDzHdQOi6jjf8zaXhCYD)");
  console.log("   - LLM: gpt-4o-mini");
  console.log("   - Subscription: $20/month, 100 minutes");
}

setupVapiConfig()
  .then(() => {
    console.log("✅ Setup complete");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });
