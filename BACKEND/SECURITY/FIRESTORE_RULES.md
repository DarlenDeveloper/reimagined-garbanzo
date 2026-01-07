# Firestore Security Rules

## Principles

1. **Deny by default** — explicitly allow, never implicitly
2. **Validate ownership** — users can only access their own data
3. **Vendor isolation** — strict tenant separation
4. **Server-side for sensitive ops** — use Cloud Functions for critical operations
5. **Limit queries** — prevent data exfiltration

---

## Complete Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================
    // HELPER FUNCTIONS
    // ============================================
    
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if user owns this document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Check if user is a member of a vendor
    function isMemberOf(vendorId) {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/vendors/$(vendorId)/members/$(request.auth.uid));
    }
    
    // Check if user has a specific role in vendor
    function hasRole(vendorId, roles) {
      let member = get(/databases/$(database)/documents/vendors/$(vendorId)/members/$(request.auth.uid));
      return member != null && member.data.role in roles && member.data.status == 'active';
    }
    
    // Check if user is vendor owner
    function isVendorOwner(vendorId) {
      return hasRole(vendorId, ['owner']);
    }
    
    // Check if user is vendor admin or owner
    function isVendorAdmin(vendorId) {
      return hasRole(vendorId, ['owner', 'admin']);
    }
    
    // Check if user can manage products
    function canManageProducts(vendorId) {
      return hasRole(vendorId, ['owner', 'admin', 'manager']);
    }
    
    // Check if user can view orders
    function canViewOrders(vendorId) {
      return hasRole(vendorId, ['owner', 'admin', 'manager', 'staff']);
    }
    
    // Validate string length
    function isValidString(field, minLen, maxLen) {
      return field is string && field.size() >= minLen && field.size() <= maxLen;
    }
    
    // Validate email format (basic)
    function isValidEmail(email) {
      return email is string && email.matches('^[^@]+@[^@]+\\.[^@]+$');
    }
    
    // Validate price (positive number)
    function isValidPrice(price) {
      return price is number && price >= 0;
    }
    
    // Limit query size
    function hasQueryLimit(maxLimit) {
      return request.query.limit != null && request.query.limit <= maxLimit;
    }
    
    // ============================================
    // USERS COLLECTION
    // ============================================
    
    match /users/{userId} {
      // Anyone authenticated can read basic user info
      allow read: if isAuthenticated();
      
      // Only the user can write their own document
      allow create: if isOwner(userId) && validateUserCreate();
      allow update: if isOwner(userId) && validateUserUpdate();
      allow delete: if false; // Soft delete only via Cloud Functions
      
      function validateUserCreate() {
        let data = request.resource.data;
        return data.keys().hasAll(['email', 'displayName', 'userType', 'createdAt']) &&
               isValidEmail(data.email) &&
               isValidString(data.displayName, 1, 100) &&
               data.userType in ['buyer', 'vendor'] &&
               data.createdAt == request.time;
      }
      
      function validateUserUpdate() {
        let data = request.resource.data;
        // Cannot change email, userType, or createdAt
        return !data.diff(resource.data).affectedKeys().hasAny(['email', 'userType', 'createdAt', 'id']);
      }
    }
    
    // ============================================
    // BUYERS COLLECTION
    // ============================================
    
    match /buyers/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }
    
    // ============================================
    // VENDORS COLLECTION
    // ============================================
    
    match /vendors/{vendorId} {
      // Public read for store discovery
      allow read: if isAuthenticated();
      
      // Only owner can create (via Cloud Function recommended)
      allow create: if isOwner(vendorId) && validateVendorCreate();
      
      // Only admin+ can update
      allow update: if isVendorAdmin(vendorId) && validateVendorUpdate();
      
      // Only owner can delete (soft delete)
      allow delete: if false; // Via Cloud Functions only
      
      function validateVendorCreate() {
        let data = request.resource.data;
        return data.keys().hasAll(['storeName', 'contactEmail', 'createdAt']) &&
               isValidString(data.storeName, 2, 100) &&
               isValidEmail(data.contactEmail);
      }
      
      function validateVendorUpdate() {
        let data = request.resource.data;
        // Cannot change owner-level fields
        return !data.diff(resource.data).affectedKeys()
          .hasAny(['userId', 'createdAt', 'subscriptionTier', 'pesapalMerchantId']);
      }
      
      // ----------------------------------------
      // VENDOR MEMBERS (RBAC)
      // ----------------------------------------
      
      match /members/{memberId} {
        // Members can see other members
        allow read: if isMemberOf(vendorId);
        
        // Write only via Cloud Functions (invite, accept, remove)
        allow write: if false;
      }
      
      // ----------------------------------------
      // PRODUCTS
      // ----------------------------------------
      
      match /products/{productId} {
        // Public read for buyers
        allow read: if isAuthenticated();
        
        // List with limit
        allow list: if isAuthenticated() && hasQueryLimit(50);
        
        // Only manager+ can write
        allow create: if canManageProducts(vendorId) && validateProductCreate();
        allow update: if canManageProducts(vendorId) && validateProductUpdate();
        allow delete: if isVendorAdmin(vendorId);
        
        function validateProductCreate() {
          let data = request.resource.data;
          return data.keys().hasAll(['name', 'price', 'vendorId', 'createdAt']) &&
                 isValidString(data.name, 1, 200) &&
                 isValidPrice(data.price) &&
                 data.vendorId == vendorId &&
                 data.createdAt == request.time;
        }
        
        function validateProductUpdate() {
          let data = request.resource.data;
          return !data.diff(resource.data).affectedKeys().hasAny(['vendorId', 'createdAt']);
        }
      }
      
      // ----------------------------------------
      // ORDERS
      // ----------------------------------------
      
      match /orders/{orderId} {
        // Staff+ can read orders
        allow read: if canViewOrders(vendorId);
        
        // List with limit
        allow list: if canViewOrders(vendorId) && hasQueryLimit(100);
        
        // Orders created by buyers or Cloud Functions
        allow create: if false; // Via Cloud Functions only
        
        // Staff+ can update status
        allow update: if canViewOrders(vendorId) && validateOrderUpdate();
        
        // No delete
        allow delete: if false;
        
        function validateOrderUpdate() {
          let data = request.resource.data;
          let allowedFields = ['status', 'updatedAt', 'notes', 'trackingNumber'];
          return data.diff(resource.data).affectedKeys().hasOnly(allowedFields);
        }
        
        // Order items subcollection
        match /items/{itemId} {
          allow read: if canViewOrders(vendorId);
          allow write: if false; // Via Cloud Functions only
        }
      }
      
      // ----------------------------------------
      // INVENTORY
      // ----------------------------------------
      
      match /inventory/{productId} {
        allow read: if canManageProducts(vendorId);
        allow write: if canManageProducts(vendorId);
      }
      
      // ----------------------------------------
      // CONVERSATIONS / MESSAGES
      // ----------------------------------------
      
      match /conversations/{conversationId} {
        allow read: if isMemberOf(vendorId);
        allow create: if false; // Via Cloud Functions
        allow update: if isMemberOf(vendorId);
        
        match /messages/{messageId} {
          allow read: if isMemberOf(vendorId);
          allow create: if isMemberOf(vendorId) && validateMessage();
          allow update, delete: if false;
          
          function validateMessage() {
            let data = request.resource.data;
            return data.keys().hasAll(['senderId', 'content', 'createdAt']) &&
                   data.senderId == request.auth.uid &&
                   isValidString(data.content, 1, 5000) &&
                   data.createdAt == request.time;
          }
        }
      }
      
      // ----------------------------------------
      // ANALYTICS (Read-only for vendor)
      // ----------------------------------------
      
      match /analytics/{docId} {
        allow read: if hasRole(vendorId, ['owner', 'admin', 'manager']);
        allow write: if false; // Written by Cloud Functions only
      }
      
      // ----------------------------------------
      // NOTIFICATIONS
      // ----------------------------------------
      
      match /notifications/{notificationId} {
        allow read: if isMemberOf(vendorId);
        allow update: if isMemberOf(vendorId) && 
                        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read', 'readAt']);
        allow create, delete: if false; // Via Cloud Functions
      }
    }
    
    // ============================================
    // INVITATIONS (Cross-vendor)
    // ============================================
    
    match /invitations/{invitationId} {
      // Invitee can read their invitation
      allow read: if isAuthenticated() && 
                    (resource.data.email == request.auth.token.email ||
                     isMemberOf(resource.data.vendorId));
      
      // Write only via Cloud Functions
      allow write: if false;
    }
    
    // ============================================
    // RATE LIMITS (Internal)
    // ============================================
    
    match /_rateLimits/{docId} {
      allow read, write: if false; // Cloud Functions only
    }
    
    // ============================================
    // CATCH-ALL: DENY EVERYTHING ELSE
    // ============================================
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Cloud Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Vendor assets (logos, banners)
    match /vendors/{vendorId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     isVendorMember(vendorId) &&
                     request.resource.size < 5 * 1024 * 1024 && // 5MB max
                     request.resource.contentType.matches('image/.*');
    }
    
    // Product images
    match /products/{vendorId}/{productId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     isVendorMember(vendorId) &&
                     request.resource.size < 10 * 1024 * 1024 && // 10MB max
                     request.resource.contentType.matches('image/.*');
    }
    
    // User avatars
    match /users/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId &&
                     request.resource.size < 2 * 1024 * 1024 && // 2MB max
                     request.resource.contentType.matches('image/.*');
    }
    
    // Chat attachments
    match /chat/{conversationId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     request.resource.size < 10 * 1024 * 1024;
    }
    
    // Helper function
    function isVendorMember(vendorId) {
      return firestore.exists(/databases/(default)/documents/vendors/$(vendorId)/members/$(request.auth.uid));
    }
    
    // Deny everything else
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Testing Rules

```bash
# Install Firebase emulator
firebase emulators:start --only firestore

# Run rules tests
npm test
```

```typescript
// tests/firestore.rules.test.ts
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';

describe('Firestore Rules', () => {
  it('denies unauthenticated access', async () => {
    const db = getFirestore(null); // No auth
    await assertFails(db.collection('users').doc('test').get());
  });
  
  it('allows user to read own profile', async () => {
    const db = getFirestore({ uid: 'user1' });
    await assertSucceeds(db.collection('users').doc('user1').get());
  });
  
  it('denies cross-vendor data access', async () => {
    const db = getFirestore({ uid: 'user1' }); // Member of vendor1
    await assertFails(
      db.collection('vendors').doc('vendor2').collection('orders').get()
    );
  });
});
```
