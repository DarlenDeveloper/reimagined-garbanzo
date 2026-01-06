# Phase 1: Core Infrastructure - Firebase & Authentication

## Overview

Set up Firebase project and implement authentication for both Purl Admin (vendors) and Purl Stores (buyers) applications.

## Firebase Project Setup

### 1. Create Firebase Project

```
Project Name: purl-platform
Project ID: purl-platform-prod
Region: Choose closest to target market
```

### 2. Enable Services

- [ ] Firebase Authentication
- [ ] Cloud Firestore
- [ ] Cloud Storage
- [ ] Cloud Functions
- [ ] Firebase Cloud Messaging
- [ ] Firebase Analytics

### 3. Flutter Integration

```yaml
# pubspec.yaml dependencies
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_messaging: ^14.7.10
  firebase_analytics: ^10.8.0
```

## Authentication Methods

### Supported Auth Providers

| Provider | Buyer App | Seller App |
|----------|-----------|------------|
| Email/Password | ✅ | ✅ |
| Phone (OTP) | ✅ | ✅ |
| Google OAuth | ✅ | ✅ |
| Apple OAuth | ✅ | ✅ |

## Firestore Collections

### Users Collection

```
/users/{userId}
├── id: string
├── email: string
├── phone: string?
├── displayName: string
├── avatarUrl: string?
├── userType: 'buyer' | 'vendor'
├── createdAt: timestamp
├── updatedAt: timestamp
├── lastLoginAt: timestamp
├── isActive: boolean
├── fcmTokens: string[]
└── settings: map
    ├── language: string
    ├── currency: string
    └── notificationsEnabled: boolean
```

### Buyer Profiles Collection

```
/buyers/{userId}
├── userId: string (ref to /users)
├── addresses: array
│   ├── id: string
│   ├── label: string
│   ├── street: string
│   ├── city: string
│   ├── state: string
│   ├── postalCode: string
│   ├── country: string
│   ├── latitude: number?
│   ├── longitude: number?
│   └── isDefault: boolean
├── paymentMethods: array (tokenized refs only)
├── interests: string[]
├── followedVendors: string[]
└── wishlist: string[] (product IDs)
```

### Vendor Profiles Collection

```
/vendors/{userId}
├── userId: string (ref to /users)
├── storeName: string
├── storeDescription: string
├── logoUrl: string?
├── bannerUrl: string?
├── contactEmail: string
├── contactPhone: string
├── businessHours: map
├── location: geopoint
├── address: map
├── isVerified: boolean
├── isActive: boolean
├── rating: number
├── reviewCount: number
├── followerCount: number
├── productCount: number
├── subscriptionTier: 'free' | 'premium'
├── subscriptionExpiresAt: timestamp?
├── pesapalMerchantId: string?
└── createdAt: timestamp
```

## Authentication Flows

### 1. Email/Password Registration

```dart
// Buyer Registration Flow
1. User enters email, password, name
2. Firebase Auth creates account
3. Cloud Function triggered (onCreate)
4. Create /users document
5. Create /buyers document
6. Send verification email
7. Return to app with user session

// Vendor Registration Flow
1. Vendor enters email, password, business details
2. Firebase Auth creates account
3. Cloud Function triggered (onCreate)
4. Create /users document (userType: 'vendor')
5. Create /vendors document
6. Send verification email
7. Redirect to store setup flow
```

### 2. Phone OTP Authentication

```dart
// Phone Auth Flow
1. User enters phone number
2. Firebase sends OTP via SMS
3. User enters OTP code
4. Firebase verifies and creates/signs in user
5. Check if user document exists
6. If new user, create profile documents
```

### 3. OAuth (Google/Apple)

```dart
// OAuth Flow
1. User taps Google/Apple sign-in
2. OAuth provider authenticates
3. Firebase receives OAuth token
4. Firebase creates/signs in user
5. Check if user document exists
6. If new user, prompt for userType selection
7. Create appropriate profile documents
```

### 4. Password Reset

```dart
// Password Reset Flow
1. User enters email
2. Firebase sends reset email
3. User clicks link, enters new password
4. Firebase updates password
5. User redirected to login
```

## Cloud Functions

### Auth Triggers

```typescript
// functions/src/auth/onCreate.ts
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  // Create base user document
  await db.collection('users').doc(user.uid).set({
    id: user.uid,
    email: user.email,
    phone: user.phoneNumber,
    displayName: user.displayName || '',
    avatarUrl: user.photoURL,
    userType: 'buyer', // Default, updated during onboarding
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    lastLoginAt: FieldValue.serverTimestamp(),
    isActive: true,
    fcmTokens: [],
    settings: {
      language: 'en',
      currency: 'KES',
      notificationsEnabled: true
    }
  });
});

// functions/src/auth/onDelete.ts
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  // Soft delete - mark as inactive
  await db.collection('users').doc(user.uid).update({
    isActive: false,
    deletedAt: FieldValue.serverTimestamp()
  });
});
```

## Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Buyers collection
    match /buyers/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Vendors collection
    match /vendors/{vendorId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == vendorId;
      allow update: if request.auth.uid == vendorId;
    }
  }
}
```

## Session Management

- **Session Timeout**: 30 minutes of inactivity
- **Token Refresh**: Automatic via Firebase SDK
- **Multi-device**: Support multiple FCM tokens per user
- **Logout**: Clear FCM token, invalidate session

## Implementation Checklist

- [ ] Create Firebase project
- [ ] Configure Android app (google-services.json)
- [ ] Configure iOS app (GoogleService-Info.plist)
- [ ] Enable authentication providers
- [ ] Create Firestore collections
- [ ] Deploy security rules
- [ ] Implement Cloud Functions
- [ ] Build Flutter auth service
- [ ] Implement login screens
- [ ] Implement registration screens
- [ ] Implement password reset
- [ ] Test all auth flows
