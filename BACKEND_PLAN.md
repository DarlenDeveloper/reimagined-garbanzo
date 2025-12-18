# GlowCart Backend Planning Document

## Overview

This document outlines the Go backend architecture needed to support:
1. **Seller Portal** (Next.js) - Vendor management dashboard
2. **Buyer App** (Flutter) - Customer mobile application

---

## 1. Data Models Summary

### From Seller Portal (TypeScript Types)

| Entity | Key Fields |
|--------|------------|
| **Vendor** | vendorId, email, storeName, description, logoUrl, bannerUrl, contactEmail, phoneNumber, businessType, subscriptionTier (free/premium), status |
| **Product** | productId, vendorId, name, description, price, currency, categoryId, images[], variants[], sku, status |
| **ProductVariant** | variantId, productId, name, sku, priceAdjustment |
| **InventoryItem** | productId, productName, variantId, quantity, lowStockAlert, threshold |
| **Order** | orderId, vendorId, buyerId, items[], totalAmount, currency, status, deliveryAddress |
| **OrderItem** | productId, productName, quantity, price, variantId |
| **OrderEvent** | eventId, orderId, eventType, description, createdAt |
| **Transaction** | transactionId, orderId, vendorId, grossAmount, commission, netAmount, currency, status |
| **Notification** | notificationId, vendorId, type, title, message, readAt, createdAt |
| **Delivery** | deliveryId, orderId, deliveryProvider (uber/manual), status, pickupAddress, dropoffAddress, driverName, driverPhone, trackingUrl |
| **Shipment** | shipmentId, orderId, shippingProvider (skynet), trackingNumber, shippingLabelUrl, status, weight, dimensions |
| **User** | userId, vendorId, email, name, role (owner/admin/manager/staff), permissions[], status |
| **SocialPost** | postId, vendorId, content, mediaUrl, mediaType, likes, comments, shares, views, expiresAt |
| **Follower** | id, name, email, followedAt |

### From Buyer App (Dart Models)

| Entity | Key Fields |
|--------|------------|
| **Product** | id, name, description, price, imageUrl, category, vendorId, vendorName, rating, reviewCount, isFavorite, specs |
| **Vendor** | id, name, description, logoUrl, location, rating, reviewCount, followerCount, productCount, isFollowing, isVerified |
| **Category** | id, name, icon, productCount |
| **CartItem** | id, product, quantity |
| **SocialPost** | id, vendorId, vendorName, vendorLogo, content, imageUrl, likes, comments, isLiked, createdAt, expiresAt, hasDiscount, discountPercent, promoCode, postType |
| **User** | id, name, email, avatarUrl, phone, addresses[] |
| **Address** | street, city, state, postalCode, country |

---

## 2. API Endpoints Required

### Authentication Service
```
POST   /api/v1/auth/register          - Vendor registration
POST   /api/v1/auth/login             - Vendor/Buyer login
POST   /api/v1/auth/logout            - Logout
POST   /api/v1/auth/refresh           - Refresh token
POST   /api/v1/auth/forgot-password   - Request password reset
POST   /api/v1/auth/reset-password    - Confirm password reset
GET    /api/v1/auth/me                - Get current user
```

### Vendor Service
```
GET    /api/v1/vendors/:id            - Get vendor profile
PUT    /api/v1/vendors/:id            - Update vendor profile
POST   /api/v1/vendors/:id/logo       - Upload logo
POST   /api/v1/vendors/:id/banner     - Upload banner
GET    /api/v1/vendors/:id/hours      - Get business hours
PUT    /api/v1/vendors/:id/hours      - Update business hours
GET    /api/v1/vendors/:id/stats      - Get vendor statistics
```

### Product Service
```
GET    /api/v1/products               - List products (with filters)
POST   /api/v1/products               - Create product
GET    /api/v1/products/:id           - Get product details
PUT    /api/v1/products/:id           - Update product
DELETE /api/v1/products/:id           - Delete product (soft)
POST   /api/v1/products/:id/images    - Upload product images
GET    /api/v1/products/:id/specs     - Get product specifications
PUT    /api/v1/products/:id/specs     - Update product specifications

GET    /api/v1/categories             - List categories
GET    /api/v1/categories/:id         - Get category with products
```

### Inventory Service
```
GET    /api/v1/inventory              - List inventory (by vendor)
GET    /api/v1/inventory/:productId   - Get product inventory
PUT    /api/v1/inventory/:productId   - Update inventory quantity
GET    /api/v1/inventory/alerts       - Get low stock alerts
PUT    /api/v1/inventory/:productId/threshold - Update threshold
```

### Order Service
```
GET    /api/v1/orders                 - List orders (with filters)
POST   /api/v1/orders                 - Create order (from buyer app)
GET    /api/v1/orders/:id             - Get order details
PUT    /api/v1/orders/:id/accept      - Accept order
PUT    /api/v1/orders/:id/reject      - Reject order
PUT    /api/v1/orders/:id/ready       - Mark ready for delivery
PUT    /api/v1/orders/:id/status      - Update order status
GET    /api/v1/orders/:id/events      - Get order timeline
```

### Payment Service
```
GET    /api/v1/payments/transactions  - List transactions
GET    /api/v1/payments/balance       - Get available balance
POST   /api/v1/payments/payout        - Request payout
GET    /api/v1/payments/payouts       - List payout history
POST   /api/v1/payments/refund        - Process refund
```

### Delivery Service (Uber Integration)
```
POST   /api/v1/deliveries             - Create delivery request
GET    /api/v1/deliveries             - List deliveries
GET    /api/v1/deliveries/:id         - Get delivery details
PUT    /api/v1/deliveries/:id/cancel  - Cancel delivery
GET    /api/v1/deliveries/:id/track   - Get tracking info
POST   /api/v1/deliveries/:id/retry   - Retry failed delivery
```

### Shipping Service (Skynet Integration)
```
POST   /api/v1/shipments              - Create shipment
GET    /api/v1/shipments              - List shipments
GET    /api/v1/shipments/:id          - Get shipment details
GET    /api/v1/shipments/:id/label    - Download shipping label
GET    /api/v1/shipments/:id/track    - Get tracking info
```

### Notification Service
```
GET    /api/v1/notifications          - List notifications
PUT    /api/v1/notifications/:id/read - Mark as read
PUT    /api/v1/notifications/read-all - Mark all as read
DELETE /api/v1/notifications/:id      - Delete notification
GET    /api/v1/notifications/unread-count - Get unread count
```

### Analytics Service
```
GET    /api/v1/analytics/dashboard    - Get dashboard metrics
GET    /api/v1/analytics/sales        - Get sales data
GET    /api/v1/analytics/products     - Get product performance
GET    /api/v1/analytics/export       - Export reports (CSV/PDF)
```

### Social/Feed Service
```
GET    /api/v1/social/posts           - List posts (feed)
POST   /api/v1/social/posts           - Create post
GET    /api/v1/social/posts/:id       - Get post details
DELETE /api/v1/social/posts/:id       - Delete post
POST   /api/v1/social/posts/:id/like  - Like post
DELETE /api/v1/social/posts/:id/like  - Unlike post
GET    /api/v1/social/followers       - Get followers
POST   /api/v1/social/follow/:vendorId - Follow vendor
DELETE /api/v1/social/follow/:vendorId - Unfollow vendor
```

### User Management Service (Seller Portal)
```
GET    /api/v1/users                  - List team members
POST   /api/v1/users                  - Add team member
GET    /api/v1/users/:id              - Get user details
PUT    /api/v1/users/:id              - Update user
DELETE /api/v1/users/:id              - Remove user
PUT    /api/v1/users/:id/role         - Update user role
PUT    /api/v1/users/:id/status       - Activate/deactivate user
```

### Buyer-Specific Endpoints
```
GET    /api/v1/buyer/feed             - Get social feed
GET    /api/v1/buyer/discover         - Discover products/vendors
GET    /api/v1/buyer/search           - Search products
GET    /api/v1/buyer/cart             - Get cart
POST   /api/v1/buyer/cart             - Add to cart
PUT    /api/v1/buyer/cart/:id         - Update cart item
DELETE /api/v1/buyer/cart/:id         - Remove from cart
GET    /api/v1/buyer/wishlist         - Get wishlist
POST   /api/v1/buyer/wishlist         - Add to wishlist
DELETE /api/v1/buyer/wishlist/:id     - Remove from wishlist
GET    /api/v1/buyer/orders           - Get buyer orders
GET    /api/v1/buyer/addresses        - Get saved addresses
POST   /api/v1/buyer/addresses        - Add address
PUT    /api/v1/buyer/addresses/:id    - Update address
DELETE /api/v1/buyer/addresses/:id    - Delete address
```

---

## 3. Complete Service Architecture (39 Services)

### Service Folders: `BACKEND/scheme/`

| # | Service | Description |
|---|---------|-------------|
| 1 | `address/` | Delivery/pickup addresses for buyers and vendors |
| 2 | `ai-customer-service/` | AI-powered customer support (Premium) |
| 3 | `analytics/` | Dashboard metrics, sales trends, reports |
| 4 | `audit-log/` | Activity tracking for compliance |
| 5 | `auth/` | Authentication, sessions, password management |
| 6 | `bnpl/` | Buy Now Pay Later subscriptions & installments |
| 7 | `buyer/` | Buyer accounts and profiles |
| 8 | `cart/` | Shopping cart management |
| 9 | `category/` | Product categories and spec templates |
| 10 | `chat/` | Buyer-vendor messaging |
| 11 | `coupon/` | Discount codes and promo campaigns |
| 12 | `delivery/` | Local delivery via Uber API |
| 13 | `faq/` | FAQs and help articles |
| 14 | `follower/` | Buyer-vendor follow relationships |
| 15 | `interests/` | User interests for personalization |
| 16 | `inventory/` | Stock levels and low stock alerts |
| 17 | `location/` | Geolocation and store maps |
| 18 | `media/` | File uploads and S3 integration |
| 19 | `notification/` | In-app notifications |
| 20 | `oauth/` | Social login (Google, Facebook, Apple) |
| 21 | `order/` | Orders and order lifecycle |
| 22 | `payment/` | Transactions, payouts, refunds (Chipper Cash) |
| 23 | `product/` | Products, variants, specifications |
| 24 | `push-notification/` | Mobile push via FCM/APNs |
| 25 | `question/` | Product Q&A |
| 26 | `rbac/` | Role-based access control |
| 27 | `receipt/` | Digital receipts |
| 28 | `report/` | Report generation (CSV/PDF) |
| 29 | `review/` | Product and vendor reviews |
| 30 | `rewards/` | Loyalty points and membership tiers |
| 31 | `search/` | Product search and discovery |
| 32 | `settings/` | User and vendor preferences |
| 33 | `shipping/` | Long-distance shipping via Skynet |
| 34 | `social/` | Vendor posts, likes, comments |
| 35 | `story/` | Ephemeral vendor stories |
| 36 | `subscription/` | Vendor premium subscriptions |
| 37 | `vendor/` | Vendor profiles and team management |
| 38 | `webhook/` | External webhook handling |
| 39 | `wishlist/` | Buyer wishlists and favorites |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        API Gateway                               │
│  (Rate limiting, Auth validation, Request routing, CORS)        │
└─────────────────────────────────────────────────────────────────┘
                                │
    ┌───────────────────────────┼───────────────────────────┐
    │                           │                           │
    ▼                           ▼                           ▼
┌─────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│ AUTH LAYER  │    │   CORE COMMERCE     │    │   LOGISTICS     │
├─────────────┤    ├─────────────────────┤    ├─────────────────┤
│ auth        │    │ product             │    │ delivery (Uber) │
│ oauth       │    │ category            │    │ shipping(Skynet)│
│ rbac        │    │ inventory           │    │ address         │
│ settings    │    │ order               │    │ location        │
└─────────────┘    │ cart                │    └─────────────────┘
                   │ payment (Chipper)   │
                   │ receipt             │
                   └─────────────────────┘
    │                           │                           │
    ▼                           ▼                           ▼
┌─────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│ USER MGMT   │    │   SOCIAL/ENGAGE     │    │   SUPPORT       │
├─────────────┤    ├─────────────────────┤    ├─────────────────┤
│ vendor      │    │ social              │    │ chat            │
│ buyer       │    │ story               │    │ notification    │
│ follower    │    │ review              │    │ push-notif      │
│ interests   │    │ question            │    │ faq             │
└─────────────┘    │ wishlist            │    │ ai-customer-svc │
                   └─────────────────────┘    └─────────────────┘
    │                           │                           │
    ▼                           ▼                           ▼
┌─────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│ MONETIZE    │    │   ANALYTICS/OPS     │    │   INFRA         │
├─────────────┤    ├─────────────────────┤    ├─────────────────┤
│ subscription│    │ analytics           │    │ media (S3)      │
│ bnpl        │    │ report              │    │ search          │
│ coupon      │    │ audit-log           │    │ webhook         │
│ rewards     │    └─────────────────────┘    └─────────────────┘
└─────────────┘
```

---

## 4. Database Schema (PostgreSQL)

### Auth & Users (~10 tables)
- users, sessions, refresh_tokens, password_resets, verification_codes
- oauth_providers, oauth_connections
- roles, permissions, role_permissions, user_roles

### Vendor Management (~8 tables)
- vendors, vendor_users, vendor_settings, vendor_locations
- vendor_subscriptions, subscription_payments, subscription_features
- vendor_verification

### Buyer Management (~6 tables)
- buyers, buyer_preferences
- reward_points, point_transactions, reward_tiers, reward_catalog

### Product & Catalog (~8 tables)
- products, product_variants, product_specifications, product_images
- categories, category_specs
- user_interests, interest_categories, behavior_signals

### Inventory (~3 tables)
- inventory, inventory_movements, low_stock_alerts

### Order & Cart (~8 tables)
- orders, order_items, order_events, order_cancellations
- carts, cart_items, abandoned_cart_reminders
- receipts, receipt_emails

### Payment (~6 tables)
- transactions, payouts, payment_methods, refunds
- bnpl_subscriptions, bnpl_plans, bnpl_payments

### Delivery & Shipping (~5 tables)
- deliveries, delivery_attempts
- shipments, shipment_events
- addresses, address_validation_cache

### Social & Engagement (~12 tables)
- social_posts, post_likes, post_comments, post_shares
- stories, story_views, story_highlights
- follows, follower_stats
- reviews, review_responses, review_votes, review_reports
- questions, answers, answer_votes

### Wishlist & Coupons (~5 tables)
- wishlists, wishlist_items, price_alerts
- coupons, coupon_usage, promo_campaigns

### Notifications (~5 tables)
- notifications, notification_templates, notification_preferences
- device_tokens, push_notifications, push_campaigns

### Chat (~3 tables)
- conversations, messages, message_attachments

### Analytics & Reporting (~6 tables)
- daily_metrics, product_analytics, sales_trends, top_products
- report_requests, scheduled_reports

### Support (~5 tables)
- faq_categories, faqs, help_articles
- ai_conversations, ai_messages, ai_knowledge_base, ai_escalations

### Infrastructure (~6 tables)
- media_files, upload_sessions
- search_history, search_suggestions
- webhook_endpoints, webhook_deliveries, incoming_webhooks
- audit_logs, login_history

**Total: ~100+ tables across 39 services**

---

## 5. External Integrations

### Chipper Cash (Payments)
- Payment processing
- 3% commission calculation
- Payout processing
- Refund handling
- Transaction webhooks

### Uber Delivery API
- Create delivery requests
- Real-time tracking
- Driver assignment
- Status webhooks
- Cancellation handling

### Skynet Shipping
- Generate shipping labels
- Create tracking numbers
- Track shipments
- Status updates

### AWS S3
- Product images
- Vendor logos/banners
- Shipping labels
- Report exports

---

## 6. Key Business Logic

### Commission Calculation
```
commission = grossAmount * 0.03
netAmount = grossAmount - commission
```

### Order Status Flow
```
pending → processing → ready → in_transit → delivered
                   ↘ cancelled (with refund)
```

### Inventory Management
- Decrement on order placement
- Increment on order cancellation
- Low stock alerts when quantity <= threshold
- Out of stock when quantity = 0

### Social Post Expiration
- Free tier: 24 hours
- Premium tier: 7 days

### User Roles & Permissions
| Role | Permissions |
|------|-------------|
| Owner | All |
| Admin | manage_products, manage_orders, manage_inventory, view_analytics, manage_users |
| Manager | manage_products, manage_orders, manage_inventory, view_analytics |
| Staff | manage_orders, view_products |

---

## 7. Tech Stack

- **Language**: Go 1.21+
- **Framework**: Gin (HTTP routing)
- **Database**: PostgreSQL 15+
- **Cache**: Redis
- **Queue**: RabbitMQ
- **Storage**: AWS S3
- **Auth**: JWT + Redis sessions

---

## 8. Project Structure (Proposed)

```
glowcart-backend/
├── cmd/
│   ├── api/              # Main API server
│   └── worker/           # Background workers
├── internal/
│   ├── config/           # Configuration
│   ├── middleware/       # Auth, logging, rate limiting
│   ├── handlers/         # HTTP handlers
│   │   ├── auth/
│   │   ├── vendor/
│   │   ├── product/
│   │   ├── order/
│   │   ├── payment/
│   │   ├── inventory/
│   │   ├── delivery/
│   │   ├── shipping/
│   │   ├── notification/
│   │   ├── analytics/
│   │   ├── social/
│   │   └── buyer/
│   ├── services/         # Business logic
│   ├── repository/       # Database access
│   ├── models/           # Data models
│   ├── dto/              # Request/Response DTOs
│   └── integrations/     # External APIs
│       ├── chipper/
│       ├── uber/
│       ├── skynet/
│       └── s3/
├── pkg/
│   ├── auth/             # JWT utilities
│   ├── validator/        # Input validation
│   ├── response/         # Standard responses
│   └── utils/            # Helpers
├── migrations/           # Database migrations
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── .env.example
├── go.mod
└── go.sum
```

---

## 9. Implementation Priority

### Phase 1: Foundation (Week 1-2)
1. Project setup & configuration
2. Database schema & migrations
3. `auth/` - Authentication, JWT, sessions
4. `oauth/` - Google, Facebook, Apple login
5. `rbac/` - Roles and permissions
6. `media/` - S3 file uploads

### Phase 2: User Management (Week 3)
7. `vendor/` - Vendor profiles, team members
8. `buyer/` - Buyer accounts
9. `address/` - Address management
10. `settings/` - User preferences

### Phase 3: Catalog (Week 4-5)
11. `category/` - Categories and spec templates
12. `product/` - Products, variants, specifications
13. `inventory/` - Stock management, alerts
14. `search/` - Product search and discovery

### Phase 4: Commerce (Week 6-7)
15. `cart/` - Shopping cart
16. `order/` - Order lifecycle
17. `payment/` - Chipper Cash integration
18. `receipt/` - Digital receipts

### Phase 5: Logistics (Week 8-9)
19. `delivery/` - Uber API integration
20. `shipping/` - Skynet integration
21. `location/` - Geolocation features
22. `webhook/` - External webhooks

### Phase 6: Social & Engagement (Week 10-11)
23. `social/` - Posts, likes, comments
24. `story/` - Ephemeral stories
25. `follower/` - Follow relationships
26. `review/` - Product reviews
27. `question/` - Product Q&A
28. `wishlist/` - Favorites

### Phase 7: Notifications (Week 12)
29. `notification/` - In-app notifications
30. `push-notification/` - FCM/APNs
31. `chat/` - Buyer-vendor messaging

### Phase 8: Monetization (Week 13-14)
32. `subscription/` - Vendor premium
33. `bnpl/` - Buy Now Pay Later
34. `coupon/` - Discounts and promos
35. `rewards/` - Loyalty program

### Phase 9: Analytics & Support (Week 15-16)
36. `analytics/` - Dashboard metrics
37. `report/` - CSV/PDF exports
38. `faq/` - Help content
39. `ai-customer-service/` - AI support (Premium)

### Phase 10: Polish (Week 17-18)
40. `audit-log/` - Activity tracking
41. `interests/` - Personalization
42. Security hardening
43. Performance optimization
44. Load testing

---

## 10. Next Steps

Ready to start implementation? We can begin with:
1. **Project scaffolding** - Set up Go project structure
2. **Docker Compose** - PostgreSQL, Redis, RabbitMQ
3. **Database migrations** - Create all tables
4. **Auth service** - First microservice

Which would you like to tackle first?
