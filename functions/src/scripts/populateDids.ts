import * as admin from "firebase-admin";

admin.initializeApp();

// Add your available DIDs here
// Get more from your SIP provider as needed
const availableDids = [
  "+256205479710",
  // Add more numbers as you get them from your SIP provider
];

async function populateDids() {
  console.log("📞 Populating DID pool...");

  const batch = admin.firestore().batch();

  for (const phoneNumber of availableDids) {
    const didRef = admin.firestore().collection("dids").doc();
    batch.set(didRef, {
      phoneNumber: phoneNumber,
      assigned: false,
      storeId: null,
      vapiPhoneNumberId: null,
      assignedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`   ✓ Added ${phoneNumber}`);
  }

  await batch.commit();
  console.log(`✅ Successfully added ${availableDids.length} DIDs to pool`);
}

populateDids()
  .then(() => {
    console.log("✅ DID population complete");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });
