# Phase 1B: Role-Based Access Control (RBAC)

## Overview

Implement role-based access control for vendor stores, allowing store owners to invite team members with different permission levels.

## Roles Hierarchy

| Role | Description | Access Level |
|------|-------------|--------------|
| Owner | Store creator, full access | All permissions + billing |
| Admin | Full access except billing | All except billing/ownership |
| Manager | Products, orders, inventory | Operational access |
| Staff | Orders only | Limited access |

## Firestore Collections

### Store Members Collection

```
/vendors/{vendorId}/members/{memberId}
├── id: string
├── userId: string (ref to /users)
├── email: string
├── name: string
├── avatarUrl: string?
├── role: 'owner' | 'admin' | 'manager' | 'staff'
├── status: 'active' | 'pending' | 'inactive'
├── invitedBy: string (userId)
├── invitedAt: timestamp
├── acceptedAt: timestamp?
├── lastActiveAt: timestamp?
└── permissions: map (custom overrides)
```

### Invitations Collection

```
/invitations/{invitationId}
├── id: string
├── vendorId: string
├── vendorName: string
├── email: string
├── role: string
├── invitedBy: string
├── inviterName: string
├── status: 'pending' | 'accepted' | 'expired' | 'cancelled'
├── token: string (secure random)
├── createdAt: timestamp
├── expiresAt: timestamp (7 days)
└── acceptedAt: timestamp?
```


## Permission Matrix

```typescript
const PERMISSIONS = {
  // Dashboard
  'dashboard:view': ['owner', 'admin', 'manager', 'staff'],
  
  // Products
  'products:view': ['owner', 'admin', 'manager'],
  'products:create': ['owner', 'admin', 'manager'],
  'products:edit': ['owner', 'admin', 'manager'],
  'products:delete': ['owner', 'admin'],
  
  // Inventory
  'inventory:view': ['owner', 'admin', 'manager'],
  'inventory:update': ['owner', 'admin', 'manager'],
  
  // Orders
  'orders:view': ['owner', 'admin', 'manager', 'staff'],
  'orders:process': ['owner', 'admin', 'manager', 'staff'],
  'orders:cancel': ['owner', 'admin', 'manager'],
  'orders:refund': ['owner', 'admin'],
  
  // Customers
  'customers:view': ['owner', 'admin', 'manager'],
  'customers:message': ['owner', 'admin', 'manager', 'staff'],
  
  // Analytics
  'analytics:view': ['owner', 'admin', 'manager'],
  'analytics:export': ['owner', 'admin'],
  
  // Marketing
  'marketing:view': ['owner', 'admin'],
  'marketing:create': ['owner', 'admin'],
  
  // Discounts
  'discounts:view': ['owner', 'admin', 'manager'],
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
  
  // Billing
  'billing:view': ['owner'],
  'billing:manage': ['owner'],
  
  // Store
  'store:edit': ['owner', 'admin'],
  'store:delete': ['owner'],
};
```

## Cloud Functions

### Invite Team Member

```typescript
// functions/src/rbac/inviteMember.ts
export const inviteMember = functions.https.onCall(async (data, context) => {
  const { email, role, vendorId } = data;
  const inviterId = context.auth?.uid;
  
  // Verify inviter has permission
  const inviterMember = await db.collection('vendors').doc(vendorId)
    .collection('members').where('userId', '==', inviterId).limit(1).get();
  
  if (inviterMember.empty) throw new Error('Unauthorized');
  
  const inviterRole = inviterMember.docs[0].data().role;
  if (!['owner', 'admin'].includes(inviterRole)) {
    throw new Error('Insufficient permissions');
  }
  
  // Only owner can invite admins
  if (role === 'admin' && inviterRole !== 'owner') {
    throw new Error('Only owner can invite admins');
  }
  
  // Check if already a member
  const existingMember = await db.collection('vendors').doc(vendorId)
    .collection('members').where('email', '==', email).limit(1).get();
  
  if (!existingMember.empty) {
    throw new Error('User is already a team member');
  }
  
  // Get vendor and inviter info
  const vendor = await db.collection('vendors').doc(vendorId).get();
  const inviter = await db.collection('users').doc(inviterId).get();
  
  // Create invitation
  const token = generateSecureToken();
  const invitationRef = db.collection('invitations').doc();
  
  await invitationRef.set({
    id: invitationRef.id,
    vendorId,
    vendorName: vendor.data().storeName,
    email,
    role,
    invitedBy: inviterId,
    inviterName: inviter.data().displayName,
    status: 'pending',
    token,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000))
  });
  
  // Send invitation email
  await sendInvitationEmail(email, {
    vendorName: vendor.data().storeName,
    inviterName: inviter.data().displayName,
    role,
    inviteLink: `https://app.purl.com/invite/${invitationRef.id}?token=${token}`
  });
  
  return { invitationId: invitationRef.id };
});
```

### Accept Invitation

```typescript
// functions/src/rbac/acceptInvitation.ts
export const acceptInvitation = functions.https.onCall(async (data, context) => {
  const { invitationId, token } = data;
  const userId = context.auth?.uid;
  
  const invitationRef = db.collection('invitations').doc(invitationId);
  const invitation = await invitationRef.get();
  
  if (!invitation.exists) throw new Error('Invitation not found');
  
  const invData = invitation.data();
  
  // Validate
  if (invData.token !== token) throw new Error('Invalid token');
  if (invData.status !== 'pending') throw new Error('Invitation already processed');
  if (invData.expiresAt.toDate() < new Date()) throw new Error('Invitation expired');
  
  // Verify email matches
  const user = await db.collection('users').doc(userId).get();
  if (user.data().email !== invData.email) {
    throw new Error('Email does not match invitation');
  }
  
  // Add as member
  const memberRef = db.collection('vendors').doc(invData.vendorId)
    .collection('members').doc();
  
  await db.runTransaction(async (transaction) => {
    transaction.set(memberRef, {
      id: memberRef.id,
      userId,
      email: invData.email,
      name: user.data().displayName,
      avatarUrl: user.data().avatarUrl,
      role: invData.role,
      status: 'active',
      invitedBy: invData.invitedBy,
      invitedAt: invData.createdAt,
      acceptedAt: FieldValue.serverTimestamp(),
      permissions: {}
    });
    
    transaction.update(invitationRef, {
      status: 'accepted',
      acceptedAt: FieldValue.serverTimestamp()
    });
  });
  
  return { success: true, vendorId: invData.vendorId };
});
```

### Check Permission

```typescript
// functions/src/rbac/checkPermission.ts
export async function checkPermission(
  userId: string,
  vendorId: string,
  permission: string
): Promise<boolean> {
  const memberSnapshot = await db.collection('vendors').doc(vendorId)
    .collection('members')
    .where('userId', '==', userId)
    .where('status', '==', 'active')
    .limit(1)
    .get();
  
  if (memberSnapshot.empty) return false;
  
  const member = memberSnapshot.docs[0].data();
  const role = member.role;
  
  // Check custom permission override first
  if (member.permissions && member.permissions[permission] !== undefined) {
    return member.permissions[permission];
  }
  
  // Check role-based permission
  const allowedRoles = PERMISSIONS[permission] || [];
  return allowedRoles.includes(role);
}

// Middleware for Cloud Functions
export function requirePermission(permission: string) {
  return async (data: any, context: functions.https.CallableContext) => {
    const { vendorId } = data;
    const userId = context.auth?.uid;
    
    if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
    
    const hasPermission = await checkPermission(userId, vendorId, permission);
    if (!hasPermission) {
      throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions');
    }
  };
}
```

### Remove Team Member

```typescript
// functions/src/rbac/removeMember.ts
export const removeMember = functions.https.onCall(async (data, context) => {
  const { vendorId, memberId } = data;
  const requesterId = context.auth?.uid;
  
  // Verify requester is owner
  const requesterMember = await db.collection('vendors').doc(vendorId)
    .collection('members').where('userId', '==', requesterId).limit(1).get();
  
  if (requesterMember.empty || requesterMember.docs[0].data().role !== 'owner') {
    throw new Error('Only owner can remove members');
  }
  
  // Get member to remove
  const memberRef = db.collection('vendors').doc(vendorId)
    .collection('members').doc(memberId);
  const member = await memberRef.get();
  
  if (!member.exists) throw new Error('Member not found');
  if (member.data().role === 'owner') throw new Error('Cannot remove owner');
  
  // Soft delete - mark as inactive
  await memberRef.update({
    status: 'inactive',
    removedAt: FieldValue.serverTimestamp(),
    removedBy: requesterId
  });
  
  return { success: true };
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

- [ ] Create Firestore collections for members and invitations
- [ ] Implement invite member Cloud Function
- [ ] Implement accept invitation Cloud Function
- [ ] Implement remove member Cloud Function
- [ ] Implement permission checking middleware
- [ ] Build team management UI in vendor app
- [ ] Build invitation acceptance flow
- [ ] Implement permission gates in UI
- [ ] Send invitation emails
- [ ] Test all RBAC flows
