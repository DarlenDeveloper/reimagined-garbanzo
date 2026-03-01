// Quick test script to verify admin authentication
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./functions/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'purlstores-za'
});

const db = admin.firestore();

async function testAdminAuth() {
  try {
    console.log('Fetching admins collection...');
    const adminsSnapshot = await db.collection('admins').limit(5).get();
    
    if (adminsSnapshot.empty) {
      console.log('No admin users found in the admins collection');
      return;
    }
    
    console.log(`Found ${adminsSnapshot.size} admin user(s):\n`);
    
    adminsSnapshot.forEach(doc => {
      console.log('Admin ID:', doc.id);
      console.log('Admin Data:', JSON.stringify(doc.data(), null, 2));
      console.log('---');
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit(0);
  }
}

testAdminAuth();
