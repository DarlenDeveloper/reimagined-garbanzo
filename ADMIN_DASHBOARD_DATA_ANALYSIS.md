# POP COMMERCE - Admin Dashboard Data Analysis

## Executive Summary
Complete analysis of the three Flutter apps (Buyer, Seller, Courier) to inform the internal admin dashboard design for POP COMMERCE employees.

---

## 🗄️ FIRESTORE DATABASE ARCHITECTURE

### Top-Level Collections

#### 1. **stores** - Store/Seller Profiles
```
id: string (auto-generated)
name: string
slug: string (URL-friendly)
category: string
description: string
logoUrl: string
bannerUrl: string
ownerId: string (Firebase Auth UID of creator)
authorizedUsers: array<string> (RBAC - owner + store runners)
location: string | GeoPoint
isVerified: boolean
verificationStatus: "none" | "pending" | "verified" | "expired"
verificationExpiresAt: timestamp
verificationData: {
  ownerName: string
  idDocumentFront: string (URL)
  idDocumentBack: string (URL)
  faceScan: string (URL)
  location: string
  submittedAt: timestamp
  approvedAt: timestamp
}
verificationPayments: array<{amount, transactionId, paidAt, expiresAt, isRenewal}>
lastVerificationPayment: {amount, transactionId, paidAt, expiresAt, isRenewal}
inviteCode: {code: string, expiresAt: timestamp} (4-digit, 15min validity)
fcmToken: string (for push notifications)
subscription: "free" | "premium"
rating: number
reviewCount: number
followerCount: number
productCount: number
address: {street, city, state, country}
contact: {phone, email, website}
businessHours: {monday, tuesday, ...}
paymentMethods: {card, mobileMoney, ...}
shipping: {domestic, international}
createdAt: timestamp
updatedAt: timestamp
```

**Subcollections:**
- `products/{productId}` - Store products
- `orders/{orderId}` - Orders for this store
- `posts/{postId}` - Social media posts
- `visitors/{userId}` - Store visitor tracking
- `discounts/{discountId}` - Discount codes
- `notifications/{notificationId}` - Store notifications
- `payouts/{payoutId}` - Payout requests
- `aiAssistant/{configId}` - AI customer service config
- `callLogs/{callId}` - AI phone call logs

---

#### 2. **users** - Buyer/Customer Profiles
```
uid: string (Firebase Auth UID)
email: string
name: string
phone: string
avatarUrl: string (optional)
location: GeoPoint
lastLocationUpdate: timestamp
interests: array<string> (category IDs)
fcmTokens: array<string> (for push notifications - supports multiple devices)
fcmToken: string (legacy - single token)
createdAt: timestamp
updatedAt: timestamp
```

**Subcollections:**
- `cart/{cartItemId}` - Shopping cart
- `orders/{orderId}` - User's order references
- `notifications/{notificationId}` - User notifications

---

#### 3. **couriers** - Delivery Personnel Profiles
```
uid: string (Firebase Auth UID)
email: string
fullName: string
phone: string
status: "pending_verification" | "verified" | "suspended"
verified: boolean
isOnline: boolean
currentLocation: GeoPoint (updated in real-time)
rating: number (0.0 - 5.0)
totalDeliveries: number
totalEarnings: number
profileCompleted: boolean
phoneVerified: boolean
vehicleType: "motorcycle" | "car"
fcmTokens: array<string>
verification: {
  idNumber: string
  vehicleName: string
  plateNumber: string
  nextOfKin: {name, phone, nin}
  documents: {idFront, idBack, faceScan} (URLs)
  submittedAt: timestamp
  status: "pending" | "approved" | "rejected"
}
createdAt: timestamp
updatedAt: timestamp
```

**Subcollections:**
- `notifications/{notificationId}` - Courier notifications

---

#### 4. **deliveries** - Delivery Requests & Tracking
```
id: string
orderId: string
orderNumber: string (e.g., "ORD-20260127-1234")
storeId: string
storeName: string
storeLocation: GeoPoint
storeAddress: {street, city, state, country}
storePhone: string
buyerId: string
buyerName: string
buyerPhone: string
buyerLocation: GeoPoint
buyerAddress: {street, city, state, country}
status: "searching" | "assigned" | "picked_up" | "in_transit" | "delivered" | "cancelled" | "no_courier_available"
packageSize: "standard" | "bulky"
searchExpiresAt: timestamp (3-minute window for courier to accept)
deliveryFee: number
distance: number (km)
items: array<{productId, productName, quantity, price}>
totalAmount: number
deliveryType: "purl_courier"
courierLocation: GeoPoint (updated during delivery)
assignedCourierId: string (optional)
assignedCourierName: string (optional)
assignedCourierPhone: string (optional)
notificationsSent: number
notifiedAt: timestamp
createdAt: timestamp
assignedAt: timestamp (optional)
pickedUpAt: timestamp (optional)
deliveredAt: timestamp (optional)
```

---

#### 5. **payments** - Payment Records (CRITICAL FOR ADMIN)
```
id: string (auto-generated or txRef)
orderId: string
storeId: string
userId: string (buyerId)
buyerId: string
buyerName: string
buyerEmail: string
buyerPhone: string
amount: number
currency: string (e.g., "UGX", "KES")
paymentMethod: "card" | "mobile_money" | "Dummy Payment"
paymentId: string (Flutterwave transaction ID)
paymentHash: string (optional)
status: "pending" | "approved" | "paid" | "failed" | "refunded"
paymentStatus: "pending" | "paid" | "failed" | "refunded"
transactionId: string
txRef: string (transaction reference)
orderNumber: string
items: array<{productId, productName, quantity, price, currency}>
deliveryFee: number
promoCode: string (optional)
promoDiscount: number (optional)
network: string (for mobile money - "MTN" | "Airtel")
flwRef: string (Flutterwave reference)
redirectUrl: string (for 3DS verification)
authMode: string
verifiedAt: timestamp (optional)
verificationData: object (Flutterwave response)
createdAt: timestamp
updatedAt: timestamp
```

---

#### 6. **dids** - DID Pool (Phone Numbers for AI Service)
```
id: string
phoneNumber: string (e.g., "+256205479710")
assigned: boolean
storeId: string (null if unassigned)
vapiPhoneNumberId: string (null if unassigned)
assignedAt: timestamp (null if unassigned)
unassignedAt: timestamp (optional)
createdAt: timestamp
```

---

#### 7. **conversations** - Messaging Between Stores & Buyers
```
id: string (format: "storeId_userId" sorted)
participants: array<string> [storeId, userId]
storeId: string
storeName: string
storeLogoUrl: string
userId: string
userName: string
userPhotoUrl: string
lastMessage: string
lastMessageTime: timestamp
unreadCount: {storeId: number, userId: number}
createdAt: timestamp
updatedAt: timestamp
```

**Subcollections:**
- `messages/{messageId}` - Chat messages

---

#### 8. **storeFollowers** - Store Follower Tracking
```
id: string (storeId)
count: number
updatedAt: timestamp
```

**Subcollections:**
- `followers/{userId}` - Individual followers

---

#### 9. **hashtags** - Social Media Hashtags
```
id: string (hashtag text)
postCount: number
updatedAt: timestamp
```

**Subcollections:**
- `posts/{postId}` - Posts with this hashtag

---

#### 10. **buyerInterests** - Buyer Interest Tracking
```
userId: string
interests: array<string> (category IDs)
updatedAt: timestamp
```

---

#### 11. **ads** - Advertisement System
```
id: string
storeId: string
title: string
imageUrl: string
targetUrl: string
status: "active" | "paused" | "completed"
viewsRemaining: number
totalViews: number
clickCount: number
budget: number
costPerView: number
createdAt: timestamp
updatedAt: timestamp
```

---

## 📦 ORDER DATA STRUCTURE (CRITICAL)

### Store Orders: `/stores/{storeId}/orders/{orderId}`
```
orderNumber: string (e.g., "ORD-20260127-1234")
userId: string (buyer)
userName: string
userEmail: string
userPhone: string
items: array<{
  productId: string
  productName: string
  productImage: string
  price: number
  currency: string
  quantity: number
  itemTotal: number
}>
subtotal: number
shipping: number
deliveryFee: number
total: number
commission: number (platform fee)
commissionRate: number (percentage)
commissionFlat: number (flat fee)
sellerPayout: number (total - commission)
promoCode: string (optional)
promoDiscount: number (optional)
status: "pending" | "confirmed" | "shipped" | "picked_up" | "delivered" | "refunded"
paymentStatus: "pending" | "paid" | "failed" | "refunded"
paymentMethod: string
paymentId: string (optional)
paymentHash: string (optional)
deliveryAddress: {label, street, city}
deliveryLocation: GeoPoint (optional)
packageSize: "standard" | "bulky"
contactDetails: {name, phone, email}
createdAt: timestamp
updatedAt: timestamp
deliveredAt: timestamp (optional)
shippedAt: timestamp (optional)
pickedUpAt: timestamp (optional)
```

### Commission Structure (Tiered)
- **15k-49k UGX**: 10% + 0.50 flat fee
- **50k-99k UGX**: 7.5% + 0.50 flat fee
- **100k-499k UGX**: 5.5% + 0.50 flat fee
- **500k+ UGX**: 3% (no flat fee)

---

## 🔐 AUTHENTICATION & ROLES

### User Types
1. **Buyers** - Regular customers (users collection)
2. **Sellers** - Store owners + runners (stores collection with authorizedUsers)
3. **Couriers** - Delivery personnel (couriers collection)
4. **Admin** - POP COMMERCE employees (TO BE CREATED)

### RBAC for Stores
- **Owner**: Creator of the store (ownerId field)
- **Runners**: Added via 4-digit invite code (15-minute validity)
- **authorizedUsers**: Array containing owner + all runners
- All authorized users can access store data

### Current Security Rules
```javascript
// firestore.rules - VERY PERMISSIVE (needs tightening)
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

---

## ✅ VERIFICATION SYSTEMS

### Store Verification
- **Status Flow**: none → pending → verified → expired
- **Documents Required**: ID front, ID back, face scan
- **Validity**: 30 days from approval
- **Renewal**: Can renew before expiration
- **Payment Tracking**: verificationPayments array
- **Revenue Model**: Paid feature

### Courier Verification
- **Status Flow**: pending_verification → verified → suspended
- **Documents Required**: ID front, ID back, face scan
- **Additional Info**: Vehicle type, plate number, next of kin
- **Phone Verification**: Required

---

## 💰 PAYMENT & PAYOUT SYSTEM

### Payment Flow
1. Buyer places order
2. Payment processed via Flutterwave (card or mobile money)
3. Payment record created in `/payments` collection
4. Order status updated based on payment status
5. Commission calculated and deducted
6. Seller payout = total - commission

### Payout Requests: `/stores/{storeId}/payouts/{payoutId}`
```
amount: number
method: "bank_transfer" | "mobile_money"
details: {accountNumber, bankName, etc.}
status: "pending" | "processing" | "completed" | "rejected" | "cancelled"
createdAt: timestamp
processedAt: timestamp (optional)
```

---

## 📊 ANALYTICS & TRACKING

### Store Visitors: `/stores/{storeId}/visitors/{userId}`
```
userId: string
lastVisitDate: string (date key, e.g., "2026-01-27")
lastVisitTime: timestamp
visitCount: number
```

### Product Metrics (in products collection)
```
rating: number
reviewCount: number
totalSold: number
stock: number
lowStockThreshold: number
```

### Courier Metrics (in couriers collection)
```
rating: number
totalDeliveries: number
totalEarnings: number
```

---

## 🔔 NOTIFICATION SYSTEM

### Push Notifications (FCM)
- **Stores**: fcmToken field (single device) or fcmTokens array (multiple devices)
- **Users**: fcmTokens array
- **Couriers**: fcmTokens array

### In-App Notifications
- **Stores**: `/stores/{storeId}/notifications/{notificationId}`
- **Users**: `/users/{userId}/notifications/{notificationId}`
- **Couriers**: `/couriers/{uid}/notifications/{notificationId}`

### Notification Types
- new_order
- payment_received
- delivery_update
- message
- low_stock
- delivery_request
- delivery_accepted
- delivery_completed

---

## 🤖 AI CUSTOMER SERVICE (VAPI Integration)

### AI Config: `/stores/{storeId}/aiAssistant/{configId}`
```
enabled: boolean
status: "active" | "grace_period" | "expired"
vapiAssistantId: string
vapiPhoneNumberId: string
didId: string (reference to dids collection)
phoneNumber: string (assigned DID)
storeName: string
subscription: {
  plan: string
  monthlyFee: number
  currency: string
  startDate: timestamp
  expiryDate: timestamp
  gracePeriodEndsAt: timestamp
  minutesIncluded: number
  usedMinutes: number
  status: "active" | "grace_period" | "expired"
  renewalCount: number
  lastRenewalDate: timestamp
}
createdAt: timestamp
updatedAt: timestamp
```

### Call Logs: `/stores/{storeId}/callLogs/{callId}`
```
callId: string
customerPhone: string
customerName: string
duration: number (seconds)
transcript: string
summary: string
csatScore: number (1-5 or null)
cost: number
createdAt: timestamp
```

---

## 📱 SOCIAL FEATURES

### Store Posts: `/stores/{storeId}/posts/{postId}`
```
vendorId: string
vendorName: string
vendorLogo: string
content: string
imageUrl: string
likes: number
comments: number
isLiked: boolean
createdAt: timestamp
expiresAt: timestamp
hasDiscount: boolean
discountPercent: number
promoCode: string
postType: "promo" | "announcement" | "restock" | "new_arrival"
savedBy: array<string> (user IDs)
```

### Discounts: `/stores/{storeId}/discounts/{discountId}`
```
code: string (uppercase)
type: "percentage" | "fixed"
value: number
usageLimit: number
usageCount: number
status: "active" | "inactive"
expiresAt: timestamp
applicableProducts: array<string> (null = all products)
createdAt: timestamp
```

---

## 🚚 DELIVERY LOGISTICS

### Delivery Flow
1. Order created → Delivery request created (status: "searching")
2. Nearby couriers notified (within 2km radius)
3. Courier accepts → status: "assigned"
4. Courier picks up → status: "picked_up"
5. Courier in transit → status: "in_transit"
6. Courier delivers → status: "delivered"
7. Courier earnings updated

### Package Size Filtering
- **standard**: Motorcycles and cars can deliver
- **bulky**: Only cars can deliver

### Delivery Fee Calculation
- Based on distance (km) and package size
- Stored in both order and delivery documents

---

## 🎯 ADMIN DASHBOARD REQUIREMENTS

Based on your requirements, here's what the admin dashboard needs:

### 1. **Store Verification Management**
- View all pending verification requests
- Approve/reject with reason
- View verification documents (ID, face scan)
- Track verification payments
- Monitor expiration dates
- Send renewal reminders

### 2. **Courier Verification Management**
- View all pending courier applications
- Approve/reject with reason
- View courier documents
- Monitor courier performance (rating, deliveries, earnings)
- Suspend/unsuspend couriers

### 3. **Payment Management**
- View all payments (filterable by status, date, store, user)
- Process refunds
- Track commission revenue
- View payment methods breakdown
- Monitor failed payments
- Export payment reports

### 4. **User Management (All Users)**
**Data to Display:**
- Name
- Email
- Phone number
- User ID (copiable for support)
- User type (Buyer, Seller, Courier)
- Account status
- Registration date
- Last active

**Actions:**
- Search by name, email, phone, ID
- View user details
- View user orders (if buyer)
- View store details (if seller)
- View delivery history (if courier)
- Ban/unban users
- Reset passwords
- Send notifications

### 5. **Order Management**
**Data to Display:**
- Order number
- Buyer info (name, email, phone, ID)
- Store info
- Items (product names, quantities, prices)
- Total amount
- Commission
- Seller payout
- Payment status
- Delivery status
- Timestamps (created, shipped, delivered)

**Actions:**
- Search/filter orders
- View full order details
- Update order status
- Process refunds
- Contact buyer/seller
- Track delivery

### 6. **DID Pool Management**
- View all DIDs
- Add new DIDs manually
- Assign/unassign DIDs to stores
- Monitor DID usage
- Track AI service subscriptions

### 7. **Login Logs & Activity Tracking**
**NOTE**: Currently NOT implemented in the codebase
**Needs to be added:**
- User login events
- IP addresses
- Device info
- Login timestamps
- Failed login attempts
- Session duration

### 8. **Analytics Dashboard**
- Total revenue (commissions)
- Total orders
- Total users (buyers, sellers, couriers)
- Active stores
- Verified vs unverified stores
- Payment method breakdown
- Order status breakdown
- Delivery performance metrics
- Top-performing stores
- Revenue trends (daily, weekly, monthly)

---

## 🔒 SECURITY RECOMMENDATIONS FOR ADMIN DASHBOARD

### 1. **Admin User Collection** (NEW)
Create `/admins/{uid}` collection:
```
uid: string (Firebase Auth UID)
email: string
name: string
role: "super_admin" | "accountant" | "customer_service" | "analyst"
permissions: array<string>
createdAt: timestamp
lastLogin: timestamp
```

### 2. **Role-Based Permissions**
- **Super Admin**: Full access to everything
- **Accountant**: Payments, payouts, refunds, financial reports
- **Customer Service**: User management, order management, messaging (leave blank for now)
- **Analyst**: Read-only access to analytics, reports

### 3. **Firestore Security Rules** (MUST UPDATE)
```javascript
// Admin-only access
match /admins/{adminId} {
  allow read, write: if request.auth.uid == adminId || isAdmin();
}

// Payments - admin only
match /payments/{paymentId} {
  allow read, write: if isAdmin();
}

// Stores - admin can read all
match /stores/{storeId} {
  allow read: if isAdmin() || isAuthorizedUser(storeId);
  allow write: if isAuthorizedUser(storeId);
}

function isAdmin() {
  return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}
```

### 4. **Admin Dashboard Hosting**
- Separate Firebase Hosting site
- Subdomain: `admin.purlecom.com`
- `robots.txt`: Disallow all
- `<meta name="robots" content="noindex, nofollow">`
- Firebase Auth required before rendering
- Cloud Functions middleware for admin role check

### 5. **IP Whitelisting** (Optional)
- Firebase Hosting doesn't support IP whitelisting
- Consider Cloud Run + Load Balancer for true IP restrictions
- Or use Cloud Functions with IP check middleware

---

## 📋 MISSING DATA (TO BE IMPLEMENTED)

### 1. **Login Logs**
Create `/loginLogs/{logId}` collection:
```
userId: string
userType: "buyer" | "seller" | "courier" | "admin"
email: string
timestamp: timestamp
ipAddress: string
deviceInfo: string
userAgent: string
success: boolean
```

### 2. **Activity Logs**
Create `/activityLogs/{logId}` collection:
```
userId: string
action: string (e.g., "order_created", "payment_processed", "store_verified")
resource: string (e.g., "order", "payment", "store")
resourceId: string
details: object
timestamp: timestamp
```

### 3. **Admin Actions Log**
Create `/adminActions/{logId}` collection:
```
adminId: string
adminEmail: string
action: string (e.g., "approved_verification", "processed_refund")
targetType: string (e.g., "store", "courier", "payment")
targetId: string
reason: string (optional)
timestamp: timestamp
```

---

## 🎨 RECOMMENDED TECH STACK FOR ADMIN DASHBOARD

### Frontend
- **React + Vite** (fast, modern)
- **TailwindCSS** (styling)
- **Recharts** (analytics charts)
- **React Table** (data tables)
- **React Router** (navigation)

### Backend
- **Firebase Admin SDK** (via Cloud Functions)
- **Cloud Functions** (API endpoints)
- **Firestore** (database)
- **Firebase Auth** (authentication with custom claims)

### Key Libraries
- `firebase` (client SDK)
- `firebase-admin` (server SDK)
- `react-firebase-hooks` (React hooks for Firebase)
- `date-fns` (date formatting)
- `react-hot-toast` (notifications)

---

## 📂 SUGGESTED ADMIN DASHBOARD STRUCTURE

```
pop-admin-dashboard/
├── public/
│   ├── robots.txt (Disallow: /)
│   └── index.html (noindex meta tag)
├── src/
│   ├── components/
│   │   ├── Layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   └── RoleGuard.tsx
│   │   ├── Tables/
│   │   │   ├── DataTable.tsx
│   │   │   └── Pagination.tsx
│   │   └── Charts/
│   │       ├── RevenueChart.tsx
│   │       └── OrdersChart.tsx
│   ├── pages/
│   │   ├── Dashboard.tsx (main analytics)
│   │   ├── StoreVerification.tsx
│   │   ├── CourierVerification.tsx
│   │   ├── Payments.tsx
│   │   ├── Users.tsx
│   │   ├── Orders.tsx
│   │   ├── DIDPool.tsx
│   │   ├── LoginLogs.tsx (to be implemented)
│   │   └── Settings.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useFirestore.ts
│   │   └── useAdminRole.ts
│   ├── services/
│   │   ├── firebase.ts
│   │   ├── auth.ts
│   │   └── api.ts
│   ├── utils/
│   │   ├── formatters.ts
│   │   └── validators.ts
│   ├── types/
│   │   └── index.ts
│   ├── App.tsx
│   └── main.tsx
├── functions/ (Cloud Functions for admin operations)
│   └── src/
│       ├── admin/
│       │   ├── approveStoreVerification.ts
│       │   ├── approveCourierVerification.ts
│       │   ├── processRefund.ts
│       │   └── setAdminRole.ts
│       └── index.ts
├── firebase.json (separate hosting config)
├── package.json
└── vite.config.ts
```

---

## 🚀 NEXT STEPS

1. **Confirm Requirements**: Review this analysis and confirm all features needed
2. **Design UI/UX**: Sketch out the dashboard layout and user flows
3. **Set Up Project**: Initialize React + Vite + Firebase project
4. **Implement Auth**: Set up admin authentication with custom claims
5. **Build Core Features**: Start with most critical features (verification, payments, users)
6. **Add Missing Data**: Implement login logs and activity tracking
7. **Security Hardening**: Update Firestore rules, add middleware
8. **Testing**: Test all features thoroughly
9. **Deployment**: Deploy to Firebase Hosting with proper security

---

## 📞 CONTACT & SUPPORT

For questions about this analysis or the admin dashboard project, contact the development team.

---

**Document Version**: 1.0  
**Last Updated**: March 1, 2026  
**Prepared By**: Kiro AI Assistant  
**For**: POP COMMERCE Internal Admin Dashboard Project
