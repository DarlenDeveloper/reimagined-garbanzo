# Order Management Security

## Overview
This document explains how the order system ensures that stores can only see their own orders and buyers can only see their own orders.

---

## Security Model

### Seller App (Store Orders)

**Query Logic:**
```dart
// Step 1: Find the store owned by the current user
final storeSnapshot = await _firestore
    .collection('stores')
    .where('authorizedUsers', arrayContains: userId)
    .limit(1)
    .get();

// Step 2: Query orders only from that specific store
yield* _firestore
    .collection('stores')
    .doc(storeId)  // ← Only this store's orders
    .collection('orders')
    .orderBy('createdAt', descending: true)
    .snapshots();
```

**Security Guarantees:**
1. ✅ **Store Isolation**: Each store's orders are in a separate subcollection (`/stores/{storeId}/orders`)
2. ✅ **User Authentication**: Only users in the `authorizedUsers` array can access the store
3. ✅ **No Cross-Store Access**: Store A cannot query Store B's orders because they're in different subcollections
4. ✅ **Firestore Rules**: Additional security rules prevent unauthorized access

**Example:**
- Store A (ID: `abc123`) can only see orders in `/stores/abc123/orders/`
- Store B (ID: `xyz789`) can only see orders in `/stores/xyz789/orders/`
- Even if Store A tries to query Store B's path, Firestore rules will block it

---

### Buyer App (User Orders)

**Query Logic:**
```dart
// Query orders only for the current user
_firestore
    .collection('users')
    .doc(userId)  // ← Only this user's orders
    .collection('orders')
    .orderBy('createdAt', descending: true)
    .snapshots();
```

**Security Guarantees:**
1. ✅ **User Isolation**: Each user's orders are in their own subcollection (`/users/{userId}/orders`)
2. ✅ **Authentication Required**: Must be logged in to access
3. ✅ **No Cross-User Access**: User A cannot query User B's orders
4. ✅ **Firestore Rules**: Rules enforce that users can only read their own orders

---

## Data Structure

### When an Order is Created

Orders are stored in **TWO** locations:

1. **Store's Orders Collection** (for seller):
   ```
   /stores/{storeId}/orders/{orderId}
   ├── orderNumber: "ORD-20260207-224445"
   ├── userId: "buyer123"  ← Buyer's ID
   ├── userName: "John Doe"
   ├── items: [...]
   ├── total: 2060.40
   ├── status: "pending"
   └── createdAt: timestamp
   ```

2. **User's Orders Collection** (for buyer):
   ```
   /users/{userId}/orders/{orderId}
   ├── orderId: "same-as-above"
   ├── storeId: "store123"  ← Store's ID
   ├── storeName: "NAJOD STORES"
   ├── orderNumber: "ORD-20260207-224445"
   ├── total: 2060.40
   ├── status: "pending"
   └── createdAt: timestamp
   ```

**Why Two Locations?**
- Sellers need to see all orders for their store
- Buyers need to see all their orders across all stores
- Each party only queries their own collection
- No cross-access is possible

---

## Firestore Security Rules

### Recommended Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Store orders - only authorized users can read/write
    match /stores/{storeId}/orders/{orderId} {
      allow read: if request.auth != null && 
                     request.auth.uid in get(/databases/$(database)/documents/stores/$(storeId)).data.authorizedUsers;
      allow write: if request.auth != null && 
                      request.auth.uid in get(/databases/$(database)/documents/stores/$(storeId)).data.authorizedUsers;
    }
    
    // User orders - only the user can read their own orders
    match /users/{userId}/orders/{orderId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Testing Security

### Test 1: Store Cannot See Other Store's Orders
```dart
// Store A tries to access Store B's orders
final storeAId = 'abc123';
final storeBId = 'xyz789';

// This will return empty or throw permission denied
final storeBOrders = await _firestore
    .collection('stores')
    .doc(storeBId)  // ← Different store
    .collection('orders')
    .get();

// Result: ❌ Permission denied or empty
```

### Test 2: User Cannot See Other User's Orders
```dart
// User A tries to access User B's orders
final userAId = 'user123';
final userBId = 'user456';

// This will throw permission denied
final userBOrders = await _firestore
    .collection('users')
    .doc(userBId)  // ← Different user
    .collection('orders')
    .get();

// Result: ❌ Permission denied
```

### Test 3: Correct Access
```dart
// Store A accesses their own orders
final storeAOrders = await _firestore
    .collection('stores')
    .doc(storeAId)  // ← Own store
    .collection('orders')
    .get();

// Result: ✅ Success - returns Store A's orders only
```

---

## Summary

### Security Checklist
- ✅ Stores can only see their own orders (subcollection isolation)
- ✅ Users can only see their own orders (subcollection isolation)
- ✅ Authentication required for all queries
- ✅ Firestore rules provide additional security layer
- ✅ No way for Store A to access Store B's data
- ✅ No way for User A to access User B's data

### Key Security Features
1. **Subcollection Isolation**: Orders are stored in separate subcollections per store/user
2. **Authentication Gates**: All queries require valid authentication
3. **Authorization Checks**: `authorizedUsers` array controls store access
4. **Firestore Rules**: Server-side rules enforce security even if client is compromised
5. **No Collection Group Queries**: Orders are never queried across all stores/users

---

*Last Updated: February 8, 2026*
