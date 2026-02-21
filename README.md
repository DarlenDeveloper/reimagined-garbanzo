# PURL - Multivendor Ecommerce Platform

A comprehensive multivendor ecommerce ecosystem connecting sellers to buyers through a unified platform.

## Project Overview

PURL is a complete ecommerce solution with three main components:

1. **Purl Admin** (iOS/Android) - Mobile app for vendors to manage their stores
2. **Purl Stores** (iOS/Android) - Mobile app for buyers to browse and purchase
3. **Backend** (Supabase) - Backend services handling all business logic

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

### Backend
- **Platform**: Supabase
- **Database**: PostgreSQL
- **Auth**: Supabase Auth
- **Storage**: Supabase Storage
- **Realtime**: Supabase Realtime

## Project Structure

```
purl/
├── purl-admin-app(seller)/    # Seller mobile app
├── purl-stores-app(buyer)/    # Buyer mobile app
├── BACKEND/                   # Backend schemas and config
│   ├── scheme/               # Database schemas
│   └── supabase/             # Supabase configuration
└── README.md
```

## Getting Started

### Purl Admin (Seller App)

```bash
cd purl-admin-app\(seller\)
flutter pub get
flutter run
```

### Purl Stores (Buyer App)

```bash
cd purl-stores-app\(buyer\)
flutter pub get
flutter run
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
- Checkout flow
- Order tracking
- Store following
- Wishlist
- Reviews and ratings
- Real-time notifications

## Revenue Model

- **Platform Fee**: 3% commission on all processed payments
- **Premium Subscription**: AI customer service and advanced features
- **Core Platform**: Free to use for all vendors

## License

Proprietary - POP

