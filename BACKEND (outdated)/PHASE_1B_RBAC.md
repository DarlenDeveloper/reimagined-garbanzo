# Phase 1B: Role-Based Access Control (RBAC)

## Status: ✅ DONE (Basic Implementation)

**Completed:** January 2026

### What's Done:
- 4-digit invite code generation (admin action)
- Code verification and store joining (runner action)
- 15-minute code expiration
- Single-use codes (deleted after successful join)
- Team members list on Team page
- Remove team member functionality
- Permissions UI (view/toggle)
- Runner code entry screen with validation

### Current Flow:
1. Admin opens Team page → taps "Add Runner"
2. Admin generates 4-digit code (valid 15 min)
3. Admin shares code with runner (verbally, text, etc.)
4. Runner opens app → "Join a Store" → enters code
5. Code verified → runner added to authorizedUsers
6. Runner accesses store with runner permissions

### Firestore Structure:
```
/stores/{storeId}
├── authorizedUsers: [uid1, uid2, ...] // All users with access
├── ownerId: string                     // Store owner
├── inviteCode: {                       // Temporary, deleted after use
│   code: "1234",
│   expiresAt: timestamp
│ }
```

### Pending (Future Enhancements):
- Cloud Functions for code generation (currently client-side)
- Email-tied invite codes
- Payment approval workflow for runners
- Detailed permission storage per member
- Push notifications for approval requests

---

## Overview

Implement role-based access control for vendor stores, allowing store owners to invite team members (store runners) with a simple 4-digit code system.

## Roles Hierarchy

| Role | Description | Access Level |
|------|-------------|--------------|
| Owner | Store creator, full access | All permissions + billing |
| Admin | Full access except billing | All except billing/ownership |
| Runner | Store employee | Orders, products, inventory (no payments) |

## Access Code Flow

### How It Works

```
1. ADMIN GENERATES CODE
   └── Admin goes to Team page
       └── Enters runner's email
           └── System generates 4-digit code
               └── Code valid for 15 minutes

2. RUNNER JOINS STORE
   └── Runner creates account (or logs in)
       └── Goes to "Join as Store Runner"
           └── Enters 4-digit code
               └── If valid → Access granted
               └── If expired/invalid → Error shown

3. PAYMENT ACCESS
   └── Runner requests payment action
       └── Admin receives notification
           └── Admin approves or denies
               └── Action proceeds or blocked
```

### Code Generation Rules

- 4 random digits (0-9)
- Expires after 15 minutes
- One-time use only
- Tied to specific email address
- Admin can cancel before use
- Admin can regenerate new code

## Firestore Collections

### Store Members Collection

```
/vendors/{vendorId}/members/{memberId}
├── id: string
├── userId: string (ref to /users)
├── email: string
├── name: string
├── avatarUrl: string?
├── role: 'owner' | 'admin' | 'runner'
├── status: 'active' | 'pending' | 'inactive'
├── invitedBy: string (userId)
├── invitedAt: timestamp
├── joinedAt: timestamp?
├── lastActiveAt: timestamp?
└── permissions: map (custom overrides)
    ├── orders: boolean
    ├── products: boolean
    ├── inventory: boolean
    ├── analytics: boolean
    ├── payments: boolean (always requires approval)
    └── settings: boolean
```

### Access Codes Collection

```
/vendors/{vendorId}/accessCodes/{codeId}
├── id: string
├── code: string (4 digits)
├── email: string (target runner email)
├── role: 'runner'
├── createdBy: string (admin userId)
├── createdAt: timestamp
├── expiresAt: timestamp (15 min from creation)
├── status: 'pending' | 'used' | 'expired' | 'cancelled'
└── usedAt: timestamp?
```

### Payment Approvals Collection

```
/vendors/{vendorId}/paymentApprovals/{approvalId}
├── id: string
├── requestedBy: string (runner userId)
├── requestedAt: timestamp
├── action: 'refund' | 'payout' | 'void'
├── amount: number
├── orderId: string?
├── reason: string
├── status: 'pending' | 'approved' | 'denied'
├── reviewedBy: string? (admin userId)
├── reviewedAt: timestamp?
└── reviewNote: string?
```


## Permission Matrix

```typescript
const PERMISSIONS = {
  // Dashboard
  'dashboard:view': ['owner', 'admin', 'runner'],
  
  // Products
  'products:view': ['owner', 'admin', 'runner'],
  'products:create': ['owner', 'admin', 'runner'],
  'products:edit': ['owner', 'admin', 'runner'],
  'products:delete': ['owner', 'admin'],
  
  // Inventory
  'inventory:view': ['owner', 'admin', 'runner'],
  'inventory:update': ['owner', 'admin', 'runner'],
  
  // Orders
  'orders:view': ['owner', 'admin', 'runner'],
  'orders:process': ['owner', 'admin', 'runner'],
  'orders:cancel': ['owner', 'admin'],
  'orders:refund': ['owner', 'admin'], // Runners need approval
  
  // Customers
  'customers:view': ['owner', 'admin', 'runner'],
  'customers:message': ['owner', 'admin', 'runner'],
  
  // Analytics
  'analytics:view': ['owner', 'admin'],
  'analytics:export': ['owner', 'admin'],
  
  // Marketing
  'marketing:view': ['owner', 'admin'],
  'marketing:create': ['owner', 'admin'],
  
  // Discounts
  'discounts:view': ['owner', 'admin', 'runner'],
  'discounts:create': ['owner', 'admin'],
  'discounts:delete': ['owner', 'admin'],
  
  // Settings
  'settings:view': ['owner', 'admin'],
  'settings:edit': ['owner', 'admin'],
  
  // Team
  'team:view': ['owner', 'admin'],
  'team:invite': ['owner', 'admin'],
  'team:remove': ['owner'],
  'team:edit_roles': ['owner'],
  
  // Payments (ALWAYS requires admin approval for runners)
  'payments:view': ['owner', 'admin'],
  'payments:process': ['owner', 'admin'],
  'payments:request': ['runner'], // Can request, admin must approve
  
  // Store
  'store:edit': ['owner', 'admin'],
  'store:delete': ['owner'],
};
```

## Cloud Functions

### Generate Access Code

```typescript
// functions/src/rbac/generateAccessCode.ts
export const generateAccessCode = functions.https.onCall(async (data, context) => {
  const { email, vendorId } = data;
  const adminId = context.auth?.uid;
  
  if (!adminId) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  
  // Verify admin has permission
  const adminMember = await db.collection('vendors').doc(vendorId)
    .collection('members').where('userId', '==', adminId).limit(1).get();
  
  if (adminMember.empty) throw new functions.https.HttpsError('permission-denied', 'Not a member');
  
  const adminRole = adminMember.docs[0].data().role;
  if (!['owner', 'admin'].includes(adminRole)) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can invite runners');
  }
  
  // Check if already a member
  const existingMember = await db.collection('vendors').doc(vendorId)
    .collection('members').where('email', '==', email.toLowerCase()).limit(1).get();
  
  if (!existingMember.empty) {
    throw new functions.https.HttpsError('already-exists', 'User is already a team member');
  }
  
  // Cancel any existing pending codes for this email
  const existingCodes = await db.collection('vendors').doc(vendorId)
    .collection('accessCodes')
    .where('email', '==', email.toLowerCase())
    .where('status', '==', 'pending')
    .get();
  
  const batch = db.batch();
  existingCodes.docs.forEach(doc => {
    batch.update(doc.ref, { status: 'cancelled' });
  });
  
  // Generate 4-digit code
  const code = Math.floor(1000 + Math.random() * 9000).toString();
  const codeRef = db.collection('vendors').doc(vendorId).collection('accessCodes').doc();
  
  batch.set(codeRef, {
    id: codeRef.id,
    code,
    email: email.toLowerCase(),
    role: 'runner',
    createdBy: adminId,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 15 * 60 * 1000)), // 15 minutes
    status: 'pending',
  });
  
  await batch.commit();
  
  return { code, expiresIn: 15 * 60 }; // Return code and expiry in seconds
});
```

### Verify Access Code

```typescript
// functions/src/rbac/verifyAccessCode.ts
export const verifyAccessCode = functions.https.onCall(async (data, context) => {
  const { code } = data;
  const userId = context.auth?.uid;
  
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  
  // Get user email
  const user = await db.collection('users').doc(userId).get();
  if (!user.exists) throw new functions.https.HttpsError('not-found', 'User not found');
  
  const userEmail = user.data()!.email.toLowerCase();
  
  // Find matching code across all vendors
  const codesSnapshot = await db.collectionGroup('accessCodes')
    .where('code', '==', code)
    .where('email', '==', userEmail)
    .where('status', '==', 'pending')
    .limit(1)
    .get();
  
  if (codesSnapshot.empty) {
    throw new functions.https.HttpsError('not-found', 'Invalid or expired code');
  }
  
  const codeDoc = codesSnapshot.docs[0];
  const codeData = codeDoc.data();
  
  // Check expiry
  if (codeData.expiresAt.toDate() < new Date()) {
    await codeDoc.ref.update({ status: 'expired' });
    throw new functions.https.HttpsError('deadline-exceeded', 'Code has expired');
  }
  
  // Extract vendorId from path
  const vendorId = codeDoc.ref.parent.parent!.id;
  
  // Add user as member
  const memberRef = db.collection('vendors').doc(vendorId).collection('members').doc();
  
  await db.runTransaction(async (transaction) => {
    // Mark code as used
    transaction.update(codeDoc.ref, {
      status: 'used',
      usedAt: FieldValue.serverTimestamp(),
    });
    
    // Create member document
    transaction.set(memberRef, {
      id: memberRef.id,
      userId,
      email: userEmail,
      name: user.data()!.displayName,
      avatarUrl: user.data()!.avatarUrl || null,
      role: codeData.role,
      status: 'active',
      invitedBy: codeData.createdBy,
      invitedAt: codeData.createdAt,
      joinedAt: FieldValue.serverTimestamp(),
      permissions: {
        orders: true,
        products: true,
        inventory: true,
        analytics: false,
        payments: false, // Always false for runners
        settings: false,
      },
    });
  });
  
  // Get vendor info for response
  const vendor = await db.collection('vendors').doc(vendorId).get();
  
  return {
    success: true,
    vendorId,
    storeName: vendor.data()!.storeName,
    role: codeData.role,
  };
});
```

### Request Payment Approval

```typescript
// functions/src/rbac/requestPaymentApproval.ts
export const requestPaymentApproval = functions.https.onCall(async (data, context) => {
  const { vendorId, action, amount, orderId, reason } = data;
  const runnerId = context.auth?.uid;
  
  if (!runnerId) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  
  // Verify user is a runner
  const member = await db.collection('vendors').doc(vendorId)
    .collection('members').where('userId', '==', runnerId).limit(1).get();
  
  if (member.empty || member.docs[0].data().role !== 'runner') {
    throw new functions.https.HttpsError('permission-denied', 'Only runners need approval');
  }
  
  // Create approval request
  const approvalRef = db.collection('vendors').doc(vendorId).collection('paymentApprovals').doc();
  
  await approvalRef.set({
    id: approvalRef.id,
    requestedBy: runnerId,
    requestedAt: FieldValue.serverTimestamp(),
    action,
    amount,
    orderId: orderId || null,
    reason,
    status: 'pending',
  });
  
  // Notify admins (via FCM)
  const admins = await db.collection('vendors').doc(vendorId)
    .collection('members')
    .where('role', 'in', ['owner', 'admin'])
    .where('status', '==', 'active')
    .get();
  
  // Send push notifications to admins
  for (const admin of admins.docs) {
    const adminUser = await db.collection('users').doc(admin.data().userId).get();
    const fcmTokens = adminUser.data()?.fcmTokens || [];
    
    if (fcmTokens.length > 0) {
      await admin.messaging().sendMulticast({
        tokens: fcmTokens,
        notification: {
          title: 'Payment Approval Required',
          body: `${member.docs[0].data().name} requested ${action} for $${amount}`,
        },
        data: {
          type: 'payment_approval',
          approvalId: approvalRef.id,
          vendorId,
        },
      });
    }
  }
  
  return { approvalId: approvalRef.id };
});
```

## Security Rules

```javascript
// Vendor Members
match /vendors/{vendorId}/members/{memberId} {
  allow read: if isMemberOf(vendorId);
  allow write: if false; // Only via Cloud Functions
}

// Invitations
match /invitations/{invitationId} {
  allow read: if request.auth.token.email == resource.data.email ||
              isMemberOf(resource.data.vendorId);
  allow write: if false; // Only via Cloud Functions
}

// Helper function
function isMemberOf(vendorId) {
  return exists(/databases/$(database)/documents/vendors/$(vendorId)/members/$(request.auth.uid));
}
```

## Flutter Integration

### Permission Check Widget

```dart
class PermissionGate extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;
  
  const PermissionGate({
    required this.permission,
    required this.child,
    this.fallback,
  });
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    if (authProvider.hasPermission(permission)) {
      return child;
    }
    
    return fallback ?? const SizedBox.shrink();
  }
}

// Usage
PermissionGate(
  permission: 'products:create',
  child: FloatingActionButton(
    onPressed: () => _addProduct(),
    child: Icon(Icons.add),
  ),
)
```

### Auth Provider with RBAC

```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  StoreMember? _currentMember;
  
  bool hasPermission(String permission) {
    if (_currentMember == null) return false;
    
    // Check custom override
    if (_currentMember!.permissions.containsKey(permission)) {
      return _currentMember!.permissions[permission]!;
    }
    
    // Check role-based
    return PERMISSIONS[permission]?.contains(_currentMember!.role) ?? false;
  }
  
  Future<void> loadMemberRole(String vendorId) async {
    final snapshot = await FirebaseFirestore.instance
      .collection('vendors')
      .doc(vendorId)
      .collection('members')
      .where('userId', isEqualTo: _user!.uid)
      .where('status', isEqualTo: 'active')
      .limit(1)
      .get();
    
    if (snapshot.docs.isNotEmpty) {
      _currentMember = StoreMember.fromFirestore(snapshot.docs.first);
      notifyListeners();
    }
  }
}
```

## Implementation Checklist

- [x] Create Firestore structure for authorized users
- [x] Implement invite code generation (client-side)
- [x] Implement code verification and store joining
- [x] Implement remove member functionality
- [x] Build team management UI in vendor app
- [x] Build runner code entry screen
- [x] Implement permission UI (view/toggle)
- [ ] Create Firestore collections for detailed members/permissions
- [ ] Implement Cloud Functions for code generation
- [ ] Implement email-tied invite codes
- [ ] Implement payment approval workflow
- [ ] Send invitation emails/notifications
- [ ] Test all RBAC flows
