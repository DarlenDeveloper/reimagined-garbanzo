# POP - Multivendor Ecommerce Platform

## Product Information

### Brand Evolution
- **Original Name**: PURL
- **Current Name**: Wibble (in codebase)
- **New Brand**: POP
  - POP Seller (Vendor app)
  - POP Rider (Courier app)
  - POP (Buyer app)

### Firebase Project
- **Project ID**: `purlstores-za`
- **Region**: `africa-south1` (Johannesburg, South Africa)
- **Runtime**: Node.js 20

### Application Packages
**Current (Development)**:
- Seller: `com.purl.admin`
- Buyer: `com.purl.stores`
- Courier: `com.example.purl_courier_app`

**To Be Updated (Before Deployment)**:
- Seller: `com.pop.seller`
- Buyer: `com.pop.app`
- Courier: `com.pop.rider`

---

## Platform Overview

POP is a comprehensive multivendor ecommerce ecosystem connecting sellers to buyers through three interconnected mobile apps, with AI-powered features for enhanced user experience.

### Core Components

1. **POP Seller** (iOS/Android) - Vendor store management
2. **POP** (iOS/Android) - Buyer shopping experience with AI product discovery
3. **POP Rider** (iOS/Android) - Delivery partner app
4. **Backend** (Firebase) - Cloud Functions, Firestore, Authentication, Storage, Messaging

---

## Revenue Model

- **Platform Fee**: 3% commission on all processed payments
- **Premium Subscription**: AI customer service and advanced analytics
- **Core Platform**: Free to use for all vendors

---

## Tech Stack

### Frontend
- **Framework**: Flutter 3.7.2+
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI**: Google Fonts (Inter), Iconsax icons

### Backend
- **Platform**: Firebase
- **Database**: Firestore with 19 optimized indexes
- **Authentication**: Firebase Auth (Email/Password, Google Sign-In, Phone)
- **Storage**: Firebase Cloud Storage
- **Functions**: Cloud Functions (Node.js 20, TypeScript)
- **Messaging**: Firebase Cloud Messaging (FCM)
- **Analytics**: Firebase Analytics

### Integrations
- **Payment**: Flutterwave V3 (Card, Mobile Money - MTN/Airtel)
- **Maps**: Google Maps API
- **Location**: Geolocator
- **AI**: To be integrated (Product scanning, Customer service)

---

## Platform Features

### POP Seller (36 Screens)
- Dashboard with metrics and analytics
- Product management (CRUD, inventory, categories)
- Order management and fulfillment
- Delivery coordination (self-delivery or POP Rider)
- Payment history and commission tracking
- Real-time messaging with buyers
- Push notifications for orders and messages
- Low-stock alerts
- Store profile and verification
- Marketing tools (bulk notifications)
- QR code generation
- Analytics and reporting
- Staff management

### POP (45 Screens)
- AI-powered product discovery (scanning and search)
- Product browsing with categories
- Shopping cart and checkout
- Flutterwave payment integration
- Order tracking and history
- Store discovery and following
- Wishlist management
- Product Q&A system
- Reviews and ratings
- Real-time messaging with stores
- Push notifications
- Store profiles with maps
- Social feed (posts and stories)
- QR code scanning
- Address management
- Profile and settings

### POP Rider (23 Screens)
- Courier onboarding and verification
- Online/offline toggle
- Location-based delivery requests (2km radius)
- Active delivery tracking
- Navigation and directions
- Delivery completion with photo proof
- Earnings tracking
- Push notifications for delivery requests
- Real-time location updates (30s intervals)
- Phone call integration
- Profile management

---

## Cloud Functions (11 Deployed)

1. **onOrderCreated** - Notifies store staff of new orders
2. **createPaymentRecord** - Creates payment audit records
3. **onMessageSent** - Notifies recipients of new messages
4. **onProductStockUpdate** - Sends low-stock alerts
5. **sendBulkNotification** - Marketing campaigns to followers
6. **notifyNearbyCouriers** - Finds and notifies nearby riders (2km radius)
7. **onDeliveryStatusChanged** - Syncs delivery status with orders
8. **onDeliveryAccepted** - Notifies courier of acceptance/completion
9. **chargeCard** - Processes card payments with 3DES encryption
10. **chargeMobileMoney** - Processes MTN/Airtel mobile money
11. **verifyFlutterwavePayment** - Verifies payment transactions

---

## Database Structure (Firestore)

### Collections
- `/users` - Buyer profiles, FCM tokens, preferences
- `/stores` - Seller store information, authorized users
- `/stores/{storeId}/products` - Product catalog
- `/stores/{storeId}/orders` - Store-specific orders
- `/stores/{storeId}/deliveries` - Delivery records
- `/stores/{storeId}/notifications` - Store notifications
- `/users/{userId}/orders` - Buyer order history
- `/users/{userId}/notifications` - Buyer notifications
- `/users/{userId}/wishlist` - Buyer wishlist items
- `/conversations` - Chat conversations
- `/conversations/{conversationId}/messages` - Chat messages
- `/couriers` - Courier profiles and location data
- `/couriers/{courierId}/notifications` - Courier notifications
- `/deliveries` - Global delivery records
- `/payments` - Payment audit trail
- `/ads` - Promotional advertisements

### Optimized Indexes (19)
- Products: Active status, categories, featured, search, inventory
- Conversations: Participants, timestamps
- Messages: Read status, sender
- Orders: User ID, creation date
- Deliveries: Courier assignment, status, type
- Ads: Store ID, status, views
- Payments: User ID, status, date
- Stores: Active status, name

---

## Security

### Firestore Rules
- All operations require authentication
- Collection-level access controlled by app logic

### Storage Rules
- All file operations require authentication

### Payment Security
- Flutterwave keys stored in Firebase Secret Manager
- 3DES encryption for card data
- No card data stored locally
- Server-side payment verification

---

## Deployment Configuration

### Firebase Configuration
```json
{
  "functions": {
    "runtime": "nodejs20",
    "region": "africa-south1"
  }
}
```

### Deployment Scripts
- `functions/deploy.sh` - Deploy all cloud functions

---

## Current Status

**Development Phase**: Pre-launch (Production deployment this week)

**Completion Status**:
- Core Platform: ~85%
- Payment Integration: 100%
- Delivery System: 100%
- Messaging: 100%
- AI Features: 0% (To be implemented)

---

## License

Proprietary - POP

---

**Last Updated**: February 22, 2026
