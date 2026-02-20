// Run this script to add randomSeed to existing ads
// Usage: cd functions && node update_ads_random_seed.js

const admin = require('firebase-admin');

// Initialize Firebase Admin (uses existing functions config)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function updateAdsWithRandomSeed() {
  try {
    console.log('Fetching all ads...');
    const adsSnapshot = await db.collection('ads').get();
    
    console.log(`Found ${adsSnapshot.size} ads`);
    
    const batch = db.batch();
    let updateCount = 0;
    
    adsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      
      // Only update if randomSeed doesn't exist
      if (data.randomSeed === undefined) {
        const randomSeed = Math.random();
        batch.update(doc.ref, { randomSeed });
        updateCount++;
        console.log(`Updating ad ${doc.id} with randomSeed: ${randomSeed.toFixed(4)}`);
      }
    });
    
    if (updateCount > 0) {
      console.log(`\nCommitting ${updateCount} updates...`);
      await batch.commit();
      console.log('✅ Successfully updated all ads with randomSeed!');
    } else {
      console.log('✅ All ads already have randomSeed field!');
    }
    
  } catch (error) {
    console.error('❌ Error updating ads:', error);
  } finally {
    process.exit();
  }
}

updateAdsWithRandomSeed();
