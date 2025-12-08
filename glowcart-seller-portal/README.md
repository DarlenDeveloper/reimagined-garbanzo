# GLOWCART Seller Portal

The seller dashboard for GLOWCART multivendor ecommerce platform.

## Features

### ✅ Implemented (Dummy Data)

- **Authentication** - Login with dummy auth (any email/password works)
- **Dashboard** - Overview with sales metrics, charts, and recent orders
- **Products** - Product catalog management with search and filters
- **Orders** - Order management with status tracking and actions
- **Inventory** - Stock level tracking with low stock alerts
- **Deliveries** - Uber API delivery tracking and management
- **Shipping** - Skynet shipping system integration with label generation
- **Analytics** - Detailed sales analytics and revenue breakdown
- **Payments** - Transaction history and payout management
- **Users** - Team member and role management with permissions
- **Profile** - Store profile and settings management
- **Notifications** - Real-time notifications center

## Tech Stack

- **Framework**: Next.js 14+ with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Chart.js with react-chartjs-2
- **Icons**: Lucide React
- **State Management**: React Context API

## Getting Started

### Prerequisites

- Node.js 18+ installed
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Demo Login

Use any email and password to login. The app uses dummy authentication for demonstration purposes.

Example:
- Email: `seller@glowcart.com`
- Password: `anything`

## Project Structure

```
glowcart-seller-portal/
├── app/
│   ├── dashboard/          # Dashboard pages
│   │   ├── analytics/      # Analytics page
│   │   ├── inventory/      # Inventory management
│   │   ├── notifications/  # Notifications center
│   │   ├── orders/         # Order management
│   │   ├── payments/       # Payments & payouts
│   │   ├── products/       # Product catalog
│   │   ├── profile/        # Store profile
│   │   └── layout.tsx      # Dashboard layout
│   ├── layout.tsx          # Root layout
│   └── page.tsx            # Login page
├── components/
│   ├── auth/               # Authentication components
│   ├── dashboard/          # Dashboard components
│   └── ui/                 # Reusable UI components
├── lib/
│   ├── auth-context.tsx    # Authentication context
│   ├── dummy-data.ts       # Dummy data for demo
│   └── utils.ts            # Utility functions
└── types/
    └── index.ts            # TypeScript types
```

## Features Overview

### Dashboard
- Real-time metrics (sales, orders, earnings, commission)
- Sales trend chart
- Top products by revenue
- Recent orders list

### Products
- Product grid view
- Search and filter functionality
- Product status badges (active, out of stock)
- Quick edit and delete actions

### Orders
- Order list with status filters
- Detailed order information
- Accept/reject order actions
- Delivery address display

### Inventory
- Stock level tracking
- Low stock and out of stock alerts
- Inline quantity editing
- Search functionality

### Analytics
- Comprehensive sales metrics
- Revenue breakdown with commission
- Top products analysis
- Sales trend visualization
- Export functionality (CSV/PDF)

### Payments
- Available balance display
- Transaction history
- Commission breakdown (3%)
- Payout request functionality

### Profile
- Store information management
- Business hours configuration
- Logo and banner upload
- Account settings

### Notifications
- Unread notification count
- Notification types (orders, stock, payouts)
- Mark as read functionality
- Real-time updates

### Deliveries
- Uber API integration display
- Delivery status tracking
- Driver information
- Pickup and dropoff addresses
- Real-time tracking links

### Shipping
- Skynet shipping system integration
- Tracking number management
- Shipping label download
- Package dimensions and weight
- Shipment status tracking

### User Management
- Team member management
- Role-based access control (Owner, Admin, Manager, Staff)
- Permission management
- User status tracking
- Activity monitoring

## Next Steps

### Backend Integration
1. Replace dummy data with real API calls
2. Implement actual authentication with JWT
3. Connect to Go backend services
4. Integrate Chipper Cash payment API
5. Integrate Uber delivery API
6. Integrate Skynet shipping system

### Additional Features
- Real-time WebSocket notifications
- Advanced product management (variants, bulk upload)
- Order tracking with delivery status
- Advanced analytics with date range selection
- Multi-currency support
- Multi-language support
- AI customer service (premium feature)

## Environment Variables

Create a `.env.local` file:

```env
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_CHIPPER_CASH_API_KEY=your_key_here
```

## License

Proprietary - GLOWCART Platform
