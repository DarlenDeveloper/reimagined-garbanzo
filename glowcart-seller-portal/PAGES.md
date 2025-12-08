# GLOWCART Seller Portal - Page Overview

## All Available Pages

### 1. Authentication
- **Route**: `/`
- **File**: `app/page.tsx`
- **Features**: Login form with dummy authentication

### 2. Dashboard (Overview)
- **Route**: `/dashboard`
- **File**: `app/dashboard/page.tsx`
- **Features**: 
  - Sales metrics cards
  - Sales trend chart
  - Top products
  - Recent orders

### 3. Products
- **Route**: `/dashboard/products`
- **File**: `app/dashboard/products/page.tsx`
- **Features**:
  - Product grid view
  - Search functionality
  - Status badges
  - Edit/Delete actions

### 4. Orders
- **Route**: `/dashboard/orders`
- **File**: `app/dashboard/orders/page.tsx`
- **Features**:
  - Order list with filters
  - Status tracking
  - Accept/Reject actions
  - Delivery address display

### 5. Inventory
- **Route**: `/dashboard/inventory`
- **File**: `app/dashboard/inventory/page.tsx`
- **Features**:
  - Stock level tracking
  - Low stock alerts
  - Inline quantity editing
  - Search functionality

### 6. Deliveries (NEW)
- **Route**: `/dashboard/deliveries`
- **File**: `app/dashboard/deliveries/page.tsx`
- **Features**:
  - Uber API delivery tracking
  - Driver information
  - Pickup/Dropoff addresses
  - Real-time status updates
  - Tracking links

### 7. Shipping (NEW)
- **Route**: `/dashboard/shipping`
- **File**: `app/dashboard/shipping/page.tsx`
- **Features**:
  - Skynet shipping integration
  - Tracking number management
  - Shipping label download
  - Package dimensions/weight
  - Status tracking

### 8. Analytics
- **Route**: `/dashboard/analytics`
- **File**: `app/dashboard/analytics/page.tsx`
- **Features**:
  - Comprehensive metrics
  - Revenue breakdown
  - Top products analysis
  - Sales trends
  - Export functionality

### 9. Payments
- **Route**: `/dashboard/payments`
- **File**: `app/dashboard/payments/page.tsx`
- **Features**:
  - Available balance
  - Transaction history
  - Commission breakdown (3%)
  - Payout requests

### 10. Users (NEW)
- **Route**: `/dashboard/users`
- **File**: `app/dashboard/users/page.tsx`
- **Features**:
  - Team member management
  - Role-based access (Owner, Admin, Manager, Staff)
  - Permission management
  - User status tracking
  - Activity monitoring

### 11. Profile
- **Route**: `/dashboard/profile`
- **File**: `app/dashboard/profile/page.tsx`
- **Features**:
  - Store information
  - Logo/Banner upload
  - Business hours
  - Account settings

### 12. Notifications
- **Route**: `/dashboard/notifications`
- **File**: `app/dashboard/notifications/page.tsx`
- **Features**:
  - Unread count
  - Notification types
  - Mark as read
  - Real-time updates

## Navigation Structure

The sidebar includes all pages in this order:
1. Dashboard
2. Products
3. Orders
4. Inventory
5. Deliveries ⭐ NEW
6. Shipping ⭐ NEW
7. Analytics
8. Payments
9. Users ⭐ NEW
10. Profile
11. Notifications

## New Features Added

### Deliveries Page
- Integration with Uber Delivery API
- Track delivery status in real-time
- View driver information and contact details
- Monitor pickup and dropoff locations
- Access tracking URLs
- Retry failed deliveries

### Shipping Page
- Integration with Skynet Shipping System
- Generate and download shipping labels
- Track shipments with tracking numbers
- View package dimensions and weight
- Monitor shipment status
- Search by tracking number or order ID

### User Management Page
- Add and manage team members
- Assign roles (Owner, Admin, Manager, Staff)
- Configure permissions per role
- Track user activity and last login
- Activate/Deactivate users
- View role-specific permissions

## Role Permissions

### Owner
- Full access to all features
- Billing and settings management

### Admin
- Manage products, orders, inventory
- View analytics
- Manage users

### Manager
- Manage products, orders, inventory
- View analytics

### Staff
- Manage orders
- View products

## Integration Points

### Uber API (Deliveries)
- Delivery request creation
- Real-time status tracking
- Driver assignment
- Tracking URL generation

### Skynet (Shipping)
- Shipping label generation
- Tracking number creation
- Package tracking
- Status updates

### Chipper Cash (Payments)
- Payment processing
- 3% commission calculation
- Payout management
- Transaction history

## Dummy Data

All pages use dummy data from `lib/dummy-data.ts`:
- `DUMMY_PRODUCTS`
- `DUMMY_ORDERS`
- `DUMMY_INVENTORY`
- `DUMMY_TRANSACTIONS`
- `DUMMY_METRICS`
- `DUMMY_NOTIFICATIONS`
- `DUMMY_DELIVERIES` ⭐ NEW
- `DUMMY_SHIPMENTS` ⭐ NEW
- `DUMMY_USERS` ⭐ NEW

## Next Steps

1. Connect to real backend API
2. Implement actual Uber API integration
3. Implement actual Skynet API integration
4. Implement actual Chipper Cash integration
5. Add real-time WebSocket notifications
6. Implement actual authentication with JWT
