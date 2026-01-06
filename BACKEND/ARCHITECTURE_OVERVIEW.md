# Purl Platform - Backend Architecture Overview

## Introduction

This document outlines the backend architecture for the Purl multivendor e-commerce platform, consisting of two Flutter mobile applications (Purl Admin for sellers, Purl Stores for buyers) powered by Firebase/GCP with third-party integrations.

## Technology Stack

| Layer | Technology |
|-------|------------|
| **Authentication** | Firebase Auth |
| **Database** | Cloud Firestore |
| **File Storage** | Cloud Storage for Firebase |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Analytics** | Firebase Analytics + BigQuery |
| **Search** | Algolia (or Firestore queries) |
| **Serverless Functions** | Cloud Functions for Firebase |
| **AI Customer Service** | Vapi API |
| **Payments** | Pesapal |
| **Deliveries** | Uber Direct (Carrier API) |

## Implementation Phases

| Phase | Focus Area | Document | Status |
|-------|------------|----------|--------|
| 1 | Core Infrastructure (Firebase + Auth) | [PHASE_1_FIREBASE_AUTH.md](./PHASE_1_FIREBASE_AUTH.md) | Not Started |
| 1B | Role-Based Access Control (RBAC) | [PHASE_1B_RBAC.md](./PHASE_1B_RBAC.md) | Not Started |
| 2 | Product & Vendor Management | [PHASE_2_PRODUCTS_VENDORS.md](./PHASE_2_PRODUCTS_VENDORS.md) | Not Started |
| 3 | Shopping Flow (Cart, Orders, Inventory) | [PHASE_3_SHOPPING_ORDERS.md](./PHASE_3_SHOPPING_ORDERS.md) | Not Started |
| 4 | Payments (Pesapal) | [PHASE_4_PESAPAL.md](./PHASE_4_PESAPAL.md) | Not Started |
| 5 | Delivery (Uber Direct) | [PHASE_5_UBER_DIRECT.md](./PHASE_5_UBER_DIRECT.md) | Not Started |
| 6 | Communication (Chat, Notifications) | [PHASE_6_COMMUNICATION.md](./PHASE_6_COMMUNICATION.md) | Not Started |
| 7 | AI Features (Vapi) | [PHASE_7_VAPI_AI.md](./PHASE_7_VAPI_AI.md) | Not Started |
| 8 | **Store Social Feed & Stories** | [PHASE_8_SOCIAL_FEED.md](./PHASE_8_SOCIAL_FEED.md) | Not Started |
| 9 | Analytics & Reporting | [PHASE_9_ANALYTICS.md](./PHASE_9_ANALYTICS.md) | Not Started |
| 10 | Additional Features (BNPL, Coupons, Reviews) | [PHASE_10_ADDITIONAL_FEATURES.md](./PHASE_10_ADDITIONAL_FEATURES.md) | Not Started |
| 11 | Marketing & Guerrilla Campaigns | [PHASE_11_MARKETING_GUERRILLA.md](./PHASE_11_MARKETING_GUERRILLA.md) | Not Started |
| 12 | Additional Systems | [PHASE_12_ADDITIONAL_SYSTEMS.md](./PHASE_12_ADDITIONAL_SYSTEMS.md) | Not Started |

## Project Structure

```
BACKEND/
├── ARCHITECTURE_OVERVIEW.md           # This file
├── PHASE_1_FIREBASE_AUTH.md           # Firebase setup & authentication
├── PHASE_1B_RBAC.md                   # Role-based access control
├── PHASE_2_PRODUCTS_VENDORS.md        # Product & vendor management
├── PHASE_3_SHOPPING_ORDERS.md         # Cart, orders, inventory
├── PHASE_4_PESAPAL.md                 # Payment integration
├── PHASE_5_UBER_DIRECT.md             # Delivery integration
├── PHASE_6_COMMUNICATION.md           # Chat & notifications
├── PHASE_7_VAPI_AI.md                 # AI customer service
├── PHASE_8_SOCIAL_FEED.md             # Store social feed & stories (CORE FEATURE)
├── PHASE_9_ANALYTICS.md               # Analytics & reporting
├── PHASE_10_ADDITIONAL_FEATURES.md    # BNPL, Coupons, Reviews, Wishlist
├── PHASE_11_MARKETING_GUERRILLA.md    # Marketing campaigns (SMS, Email, AI Calls, Push)
├── PHASE_12_ADDITIONAL_SYSTEMS.md     # Verification, Rewards, Receipts, FAQ, Audit, Subscriptions
└── scheme/                            # Database schema definitions
```

## Business Model

- **Commission**: 3% on all processed payments
- **Premium Tier**: AI-powered customer service features (Vapi)
- **Vendor Subscriptions**: Starter (Free), Pro ($9.99/mo), Business ($24.99/mo)
- **Target Market**: African markets (Pesapal for M-Pesa, mobile money, cards)

## Feature Matrix

### Buyer App (Purl Stores) Features

| Feature | Screen | Phase |
|---------|--------|-------|
| Authentication (Email, Phone, Social) | login, signup, forgot_password | 1 |
| Onboarding & Interests | onboarding, interests | 12 |
| **Home Feed (Store Posts)** | home | **8** |
| **Stories View** | story_view | **8** |
| Product Discovery | discover, search, categories | 2 |
| Product Details | product_detail | 2 |
| Store/Vendor Profile | store_profile, vendor_detail | 2 |
| Store Map/Location | store_map | 2 |
| Shopping Cart | cart | 3 |
| Checkout | checkout | 3, 4 |
| Order Tracking | order, my_orders, order_history | 3, 5 |
| Delivery Tracking | delivery | 5 |
| BNPL Plans | bnpl_plans, bnpl_subscription | 10 |
| Wishlist/Favorites | wishlist, favorites | 10 |
| Messages/Chat | messages, chat_detail | 6 |
| Notifications | notifications, notifications_settings | 6 |
| User Profile | profile, edit_profile | 1 |
| Addresses | addresses | 1 |
| Payment Methods | payment_methods | 4 |
| Receipts | receipts | 12 |
| Help & Support | help_support | 12 |
| Privacy & Security | privacy_security, privacy_consent | 1 |
| Language Settings | language | 12 |
| About | about | 12 |

### Seller App (Purl Admin) Features

| Feature | Screen | Phase |
|---------|--------|-------|
| Authentication | login, signup, forgot_password, verify_code | 1 |
| Subscription Plans | subscription | 12 |
| Store Setup | store_setup | 2 |
| Dashboard | dashboard, home | 9 |
| Store Profile | store | 2 |
| Products Management | products | 2 |
| Inventory | inventory | 3 |
| Orders | orders | 3 |
| Delivery/Shipping | delivery, shipping, request_delivery | 5, 12 |
| Payments | payments | 4 |
| Discounts/Coupons | discounts | 10 |
| Analytics | analytics | 9 |
| Marketing (SMS, Email, Calls, Push) | marketing | 11 |
| **Social Feed/Stories** | socials | **8** |
| Team/Users (RBAC) | users | 1B |
| Messages/Chat | messages, chat | 6 |
| Notifications | notifications | 6 |
| Settings | settings | 12 |
| Menu | menu | - |

## Security Requirements

- HTTPS encryption for all data transmission
- Data encryption at rest
- 30-minute session timeout
- Suspicious activity detection and account locking
- No storage of complete payment card details (PCI compliance via Pesapal)
