# PURL - Multivendor Ecommerce Platform

A comprehensive multivendor ecommerce ecosystem connecting sellers to buyers through a unified platform.

## Project Overview

PURL is a complete ecommerce solution with three main components:

1. **Purl Admin** (iOS/Android) - Mobile app for vendors to manage their stores
2. **Purl Stores** (iOS/Android) - Mobile app for buyers to browse and purchase
3. **Purl Courier** (iOS/Android) - Mobile app for delivery partners
4. **Backend** (Firebase) - Cloud Functions, Firestore, Authentication, and Storage

## Platform Features

### Core Features (Free)
- Product catalog management
- Order processing and tracking
- Inventory management
- Payment processing (3% commission)
- Delivery coordination
- Shipping management
- Analytics and reporting
- Multi-currency support
- Real-time notifications

### Premium Features
- AI-powered customer service
- Advanced analytics
- Priority support

## Tech Stack

### Purl Admin (Seller App) ✅
- **Framework**: Flutter
- **Platforms**: iOS & Android
- **Package**: `com.purl.admin`

### Purl Stores (Buyer App) ✅
- **Framework**: Flutter
- **Platforms**: iOS & Android
- **Package**: `com.purl.stores`

### Purl Courier (Delivery App) ✅
- **Framework**: Flutter
- **Platforms**: iOS & Android
- **Package**: `com.purl.courier`

### Backend
- **Platform**: Firebase
- **Database**: Firestore
- **Auth**: Firebase Authentication
- **Storage**: Firebase Storage
- **Functions**: Cloud Functions (Node.js 20, africa-south1)
- **Messaging**: Firebase Cloud Messaging
- **Payment**: Flutterwave integration

## Project Structure

```
purl/
├── purl-admin-app(seller)/    # Seller mobile app
├── purl-stores-app(buyer)/    # Buyer mobile app
├── purl_courier_app/          # Courier mobile app
├── functions/                 # Cloud Functions (Node.js)
│   ├── src/index.ts          # 11 deployed functions
│   └── deploy.sh             # Deployment script
├── firebase.json              # Firebase configuration
├── firestore.rules            # Security rules
├── firestore.indexes.json     # Database indexes
└── storage.rules              # Storage security rules
```

## Getting Started

### Purl Admin (Seller App)

```bash
cd "purl-admin-app(seller)"
flutter pub get
flutter run
```

### Purl Stores (Buyer App)

```bash
cd "purl-stores-app(buyer)"
flutter pub get
flutter run
```

### Purl Courier (Delivery App)

```bash
cd purl_courier_app
flutter pub get
flutter run
```

### Cloud Functions

```bash
cd functions
npm install
npm run build
./deploy.sh
```

## App Features

### Purl Admin (Seller)
- Dashboard with metrics and charts
- Product management
- Order management
- Inventory tracking
- Delivery management
- Analytics and reporting
- Payment history
- Store profile management
- Marketing tools
- Notifications

### Purl Stores (Buyer)
- Product browsing and search
- Shopping cart
- Checkout flow with Flutterwave payments
- Order tracking
- Store following
- Wishlist
- Reviews and ratings
- Real-time notifications
- In-app messaging with stores
- QR code scanning

### Purl Courier (Delivery)
- Location-based delivery requests
- Real-time delivery tracking
- Earnings management
- Proof of delivery with photo capture
- Navigation and route optimization
- Push notifications for new deliveries

## Revenue Model

- **Platform Fee**: 3% commission on all processed payments
- **Premium Subscription**: AI customer service and advanced features
- **Core Platform**: Free to use for all vendors

## License

Proprietary - POP

