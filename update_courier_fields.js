// Quick script to update courier document with required fields
// Run this in Firebase Console > Firestore > Query

// Replace YOUR_COURIER_UID with your actual courier user ID
const courierUid = "YOUR_COURIER_UID";

// Required fields for the delivery system
const requiredFields = {
  isOnline: false,  // Will be toggled by app
  currentLocation: new firebase.firestore.GeoPoint(0.3476, 32.5825), // Kampala - update with actual location
  lastLocationUpdate: firebase.firestore.FieldValue.serverTimestamp(),
  lastStatusUpdate: firebase.firestore.FieldValue.serverTimestamp(),
  fcmTokens: [],  // Will be populated by app
  totalDeliveries: 0,
  totalEarnings: 0,
  rating: 5
};

// Update the courier document
db.collection('couriers').doc(courierUid).update(requiredFields)
  .then(() => console.log('Courier updated successfully!'))
  .catch(error => console.error('Error:', error));
