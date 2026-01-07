# Purl Admin App - Firebase Implementation Guide

## Current State

The app is a fully functional UI with dummy data. All screens are built and navigation is working. This guide maps each screen to its backend implementation phase.

## Tech Stack

| Current | To Add |
|---------|--------|
| Flutter 3.7+ | firebase_core |
| go_router | firebase_auth |
| provider | cloud_firestore |
| google_fonts | firebase_storage |
| iconsax | firebase_messaging |
| cached_network_image | google_sign_in |
| lottie | sign_in_with_apple |

---

## Session Persistence (Auto-Login)

Firebase Auth automatically persists user sessions locally. Users only need to log in once.

### How It Works

```
App Launch
    │
    ▼
Splash Screen checks FirebaseAuth.instance.currentUser
    │
    ├── currentUser != null (session exists)
    │   │
    │   ▼
    │   Load vendor profile from Firestore
    │   │
    │   ├── Profile exists → Dashboard
    │   └── No profile → Store Setup
    │
    └── currentUser == null (no session)
        │
        ▼
        Login Screen
```

### Implementation

```dart
// splash_screen.dart
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is logged in - check if they have a store
      final vendorDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(user.uid)
          .get();
      
      if (vendorDoc.exists) {
        context.go('/dashboard');
      } else {
        context.go('/store-setup');
      }
    } else {
      // No session - go to login
      context.go('/login');
    }
  }
}
```

### Session Lifecycle

| Event | Behavior |
|-------|----------|
| App opened | Auto-login if session exists |
| App closed | Session persists |
| App killed | Session persists |
| Device restarted | Session persists |
| User signs out | Session cleared, redirect to login |
| Token expired | Firebase auto-refreshes (transparent) |
| Account deleted | Session invalidated on next API call |

### Security Considerations

- Sessions persist indefinitely until explicit sign-out
- For sensitive actions (delete account, change password), re-authenticate:
  ```dart
  await user.reauthenticateWithCredential(credential);
  ```
- Optional: Implement session timeout for inactive users (30 min as per requirements)

---

## Implementation Order

### Phase 1: Firebase Auth + RBAC (Start Here)

**Why first:** Everything depends on knowing who the user is and what they can do.

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `splash_screen.dart` | Auto-navigates to login | Check auth state, route accordingly |
| `login_screen.dart` | Dummy login, goes to dashboard | Firebase email/password + Google/Apple OAuth |
| `signup_screen.dart` | Dummy signup + "Join as Runner" link | Firebase createUser + vendor profile creation |
| `forgot_password_screen.dart` | UI only | Firebase sendPasswordResetEmail |
| `verify_code_screen.dart` | UI only | Email verification flow |
| `access_screen.dart` | 4-digit code entry UI | Verify code via Cloud Function, join store |
| `users_screen.dart` | Team list + code generation UI | RBAC team management with 4-digit codes |
| `ads_screen.dart` | Coming soon placeholder | Future: Ad campaign management |

#### RBAC Flow (4-Digit Code System)

```
ADMIN FLOW:
1. Admin opens Team page
2. Taps "Add Runner"
3. Enters runner's email
4. System generates 4-digit code (valid 15 min)
5. Admin shares code with runner (verbally, SMS, etc.)

RUNNER FLOW:
1. Runner creates account (or logs in)
2. Taps "Join as Store Runner" on signup screen
3. Enters 4-digit code
4. If valid → Access granted, redirected to dashboard
5. If expired/invalid → Error shown

PAYMENT RESTRICTION:
- Runners can view orders, products, inventory
- Runners CANNOT process payments directly
- Payment actions require admin approval notification
```

#### New Files Needed

```
lib/
├── services/
│   ├── auth_service.dart          # Firebase Auth wrapper
│   └── rbac_service.dart          # Permission checking
├── providers/
│   ├── auth_provider.dart         # Auth state management
│   └── store_provider.dart        # Current store context
├── models/
│   ├── user_model.dart
│   ├── vendor_model.dart
│   └── store_member_model.dart
└── widgets/
    └── permission_gate.dart       # Conditional UI based on role
```

#### Data Flow

```
1. App Launch
   └── Check Firebase Auth state
       ├── Not logged in → Login Screen
       └── Logged in → Check vendor profile
           ├── No profile → Store Setup
           └── Has profile → Load RBAC role → Dashboard

2. Login
   └── Firebase signInWithEmailAndPassword / signInWithGoogle / signInWithApple
       └── On success → Load vendor profile + member role
           └── Navigate to Dashboard

3. Signup
   └── Firebase createUserWithEmailAndPassword
       └── Cloud Function creates /users + /vendors docs
           └── Navigate to Subscription → Store Setup
```

---

### Phase 2: Products & Store Management

**Depends on:** Phase 1 (need vendorId from auth)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `products_screen.dart` | Local list, CRUD in memory | Firestore CRUD, image upload |
| `store_screen.dart` | Static dummy data | Read/write vendor profile |
| `store_setup_screen.dart` | UI only | Create/update vendor doc |

#### Firestore Collections

```
/vendors/{vendorId}
/vendors/{vendorId}/products/{productId}
/vendors/{vendorId}/categories/{categoryId}
```

#### New Files

```
lib/
├── services/
│   ├── product_service.dart
│   └── storage_service.dart       # Image uploads
├── providers/
│   └── products_provider.dart
└── models/
    ├── product_model.dart
    └── category_model.dart
```

---

### Phase 3: Orders & Inventory

**Depends on:** Phase 2 (products must exist)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `orders_screen.dart` | Local list with filters | Firestore queries, real-time updates |
| `inventory_screen.dart` | UI only | Stock management, low stock alerts |
| `home_screen.dart` | Dummy stats | Real-time order counts, today's sales |

#### Firestore Collections

```
/vendors/{vendorId}/orders/{orderId}
/vendors/{vendorId}/orders/{orderId}/items/{itemId}
/vendors/{vendorId}/inventory/{productId}
```

#### New Files

```
lib/
├── services/
│   ├── order_service.dart
│   └── inventory_service.dart
├── providers/
│   ├── orders_provider.dart
│   └── inventory_provider.dart
└── models/
    ├── order_model.dart
    └── inventory_model.dart
```

---

### Phase 4: Payments (Pesapal)

**Depends on:** Phase 3 (orders must exist)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `payments_screen.dart` | UI only | Transaction history, payouts |
| `subscription_screen.dart` | UI only | Vendor subscription management |

#### Integration

- Pesapal merchant registration
- Payment webhooks via Cloud Functions
- Payout tracking

---

### Phase 5: Delivery (Uber Direct)

**Depends on:** Phase 3 (orders must exist)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `delivery_screen.dart` | UI only | Active deliveries, tracking |
| `shipping_screen.dart` | UI only | Shipping settings, zones |
| `request_delivery_screen.dart` | UI only | Create Uber Direct delivery |

---

### Phase 6: Communication

**Depends on:** Phase 1 (need user context)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `messages_screen.dart` | UI only | Customer conversations |
| `chat_screen.dart` | UI only | Real-time chat |
| `notifications_screen.dart` | UI only | FCM notifications |

#### Firestore Collections

```
/vendors/{vendorId}/conversations/{conversationId}
/vendors/{vendorId}/conversations/{conversationId}/messages/{messageId}
/vendors/{vendorId}/notifications/{notificationId}
```

---

### Phase 7: AI Customer Service (Vapi)

**Depends on:** Phase 6 (chat infrastructure)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `chat_screen.dart` | Basic chat UI | Vapi AI integration |

---

### Phase 8: Social Feed

**Depends on:** Phase 2 (store must exist)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `socials_screen.dart` | UI only | Create posts, stories |

---

### Phase 9: Analytics

**Depends on:** Phase 3 (need order data)

#### Screens to Update

| Screen | Current State | Backend Work |
|--------|---------------|--------------|
| `analytics_screen.dart` | UI only | Real analytics from Firestore/BigQuery |
| `dashboard_screen.dart` | Dummy charts | Live data |
| `home_screen.dart` | Dummy stats | Real metrics |

---

### Phase 10-12: Additional Features

| Phase | Features | Screens |
|-------|----------|---------|
| 10 | Discounts, Reviews | `discounts_screen.dart` |
| 11 | Marketing Campaigns | `marketing_screen.dart` |
| 12 | Settings, Subscriptions | `settings_screen.dart`, `subscription_screen.dart` |

---

## Immediate Next Steps (Phase 1)

### 1. Add Firebase Dependencies

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.0
```

### 2. Initialize Firebase

Update `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PurlAdminApp());
}
```

### 3. Create Auth Service

```dart
// lib/services/auth_service.dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
}
```

### 4. Create Auth Provider

```dart
// lib/providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  VendorModel? _vendor;
  StoreMember? _member;
  
  bool get isAuthenticated => _user != null;
  bool get hasStore => _vendor != null;
  String? get role => _member?.role;
  
  bool hasPermission(String permission);
  Future<void> loadVendorProfile();
  Future<void> loadMemberRole(String vendorId);
}
```

### 5. Update Router with Auth Guards

```dart
// lib/navigation/router.dart
final router = GoRouter(
  refreshListenable: authProvider,
  redirect: (context, state) {
    final isLoggedIn = authProvider.isAuthenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    
    if (!isLoggedIn && !isAuthRoute) return '/auth';
    if (isLoggedIn && isAuthRoute) return '/dashboard';
    return null;
  },
  routes: [...],
);
```

### 6. Wire Up Login Screen

Replace dummy `context.go('/dashboard')` with actual Firebase auth calls.

### 7. Build Team Management (RBAC)

Update `users_screen.dart` to:
- List team members from Firestore
- Invite new members
- Change roles (owner only)
- Remove members (owner only)

---

## File Structure After Phase 1

```
lib/
├── main.dart                      # Firebase init
├── navigation/
│   └── router.dart                # Auth-aware routing
├── screens/                       # Existing screens (updated)
├── services/
│   ├── auth_service.dart
│   └── rbac_service.dart
├── providers/
│   ├── auth_provider.dart
│   └── store_provider.dart
├── models/
│   ├── user_model.dart
│   ├── vendor_model.dart
│   └── store_member_model.dart
├── widgets/
│   └── permission_gate.dart
└── theme/                         # Existing
```

---

## Testing Checklist

### Auth Flow
- [ ] Email/password signup creates user + vendor docs
- [ ] Email/password login works
- [ ] Google sign-in works
- [ ] Apple sign-in works
- [ ] Password reset email sends
- [ ] Email verification works
- [ ] Logout clears session

### RBAC Flow
- [ ] Owner can invite team members
- [ ] Invitation email sends
- [ ] Team member can accept invitation
- [ ] Roles restrict UI correctly
- [ ] Owner can remove members
- [ ] Owner can change roles
- [ ] Staff cannot access products
- [ ] Manager cannot access billing
