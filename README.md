# GLOWCART - Multivendor Ecommerce Platform

A comprehensive multivendor ecommerce ecosystem connecting sellers to buyers through a unified platform.

## Project Overview

GLOWCART is a complete ecommerce solution with three main components:

1. **Seller Portal** (Web) - Dashboard for vendors to manage their stores
2. **Marketplace App** (iOS/Android) - Mobile app for buyers to browse and purchase
3. **Backend** (Go) - Microservices architecture handling all business logic

## Platform Features

### Core Features (Free)
- Product catalog management
- Order processing and tracking
- Inventory management
- Payment processing via Chipper Cash (3% commission)
- Delivery coordination via Uber API
- Shipping management via Skynet integration
- Analytics and reporting
- Multi-currency support
- Real-time notifications

### Premium Features
- AI-powered customer service
- Advanced analytics
- Priority support

## Tech Stack

### Seller Portal (✅ Completed)
- **Framework**: Next.js 14+ with TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Chart.js
- **State**: React Context API
- **Status**: Fully functional with dummy data

### Backend (🚧 Planned)
- **Language**: Go 1.21+
- **Framework**: Gin (HTTP), gRPC (microservices)
- **Database**: PostgreSQL 15+
- **Cache**: Redis
- **Queue**: RabbitMQ
- **Storage**: AWS S3

### Marketplace App (📋 Planned)
- **Framework**: Flutter
- **Platforms**: iOS & Android

## Project Structure

```
glowcart/
├── glowcart-seller-portal/    # ✅ Seller web dashboard (COMPLETED)
├── glowcart-marketplace-app/  # 📋 Buyer mobile app (TODO)
├── glowcart-backend/           # 🚧 Backend services (TODO)
└── .kiro/specs/                # Specifications and design docs
```

## Current Status

### ✅ Completed: Seller Portal UI
The seller dashboard is fully functional with:
- Dummy authentication
- Dashboard with metrics and charts
- Product management
- Order management
- Inventory tracking
- Delivery management (Uber API integration)
- Shipping management (Skynet integration)
- Analytics and reporting
- Payment history
- User role management
- Store profile management
- Notifications center

**Access**: http://localhost:3000
**Demo Login**: Use any email/password

### 🚧 Next Phase: Backend Development
Following the spec in `.kiro/specs/seller-web-platform/`:
- Set up Go microservices architecture
- Implement PostgreSQL database
- Build authentication service
- Create product, order, inventory services
- Integrate Chipper Cash API
- Integrate Uber Delivery API
- Integrate Skynet Shipping System
- Implement notification system
- Build analytics service

### 📋 Future: Marketplace Mobile App
- Flutter app for iOS and Android
- Product browsing and search
- Shopping cart and checkout
- Order tracking
- User reviews and ratings

## Revenue Model

- **Platform Fee**: 3% commission on all processed payments
- **Premium Subscription**: AI customer service and advanced features
- **Core Platform**: Free to use for all vendors

## External Integrations

1. **Chipper Cash** - Payment processing
2. **Uber API** - Delivery coordination
3. **Skynet** - Shipping and logistics

## Getting Started

### Seller Portal (Current)

```bash
cd glowcart-seller-portal
npm install
npm run dev
```

Visit http://localhost:3000 and login with any credentials.

### Backend (Coming Soon)

```bash
cd glowcart-backend
# Setup instructions will be added
```

### Marketplace App (Coming Soon)

```bash
cd glowcart-marketplace-app
# Setup instructions will be added
```

## Documentation

- **Requirements**: `.kiro/specs/seller-web-platform/requirements.md`
- **Design**: `.kiro/specs/seller-web-platform/design.md`
- **Tasks**: `.kiro/specs/seller-web-platform/tasks.md`

## Development Roadmap

### Phase 1: Seller Portal UI ✅ (COMPLETED)
- [x] Authentication pages
- [x] Dashboard with metrics
- [x] Product management
- [x] Order management
- [x] Inventory tracking
- [x] Delivery management (Uber API)
- [x] Shipping management (Skynet)
- [x] Analytics and reports
- [x] Payment history
- [x] User role management
- [x] Profile management
- [x] Notifications

### Phase 2: Backend Services 🚧 (IN PROGRESS)
- [ ] Project setup and infrastructure
- [ ] Database schema and migrations
- [ ] Authentication service
- [ ] Vendor service
- [ ] Product service
- [ ] Order service
- [ ] Payment service (Chipper Cash)
- [ ] Delivery service (Uber API)
- [ ] Shipping service (Skynet)
- [ ] Inventory service
- [ ] Notification service
- [ ] Analytics service
- [ ] AI customer service (Premium)

### Phase 3: Marketplace App 📋 (PLANNED)
- [ ] Flutter project setup
- [ ] Product browsing
- [ ] Shopping cart
- [ ] Checkout flow
- [ ] Order tracking
- [ ] User authentication
- [ ] Reviews and ratings

### Phase 4: Integration & Testing 📋 (PLANNED)
- [ ] Connect frontend to backend
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Security audit
- [ ] Load testing

### Phase 5: Deployment 📋 (PLANNED)
- [ ] Infrastructure setup
- [ ] CI/CD pipeline
- [ ] Monitoring and logging
- [ ] Production deployment

## Contributing

This is a proprietary project. Contact the team for contribution guidelines.

## License

Proprietary - GLOWCART Platform

---

**Current Focus**: Backend development following the implementation plan in `.kiro/specs/seller-web-platform/tasks.md`
