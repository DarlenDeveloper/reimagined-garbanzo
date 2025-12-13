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

### 11. Socials (NEW)
- **Route**: `/dashboard/socials`
- **File**: `app/dashboard/socials/page.tsx`
- **Features**:
  - Store social feed
  - Create posts (24h for free, 7 days for premium)
  - Follower management
  - Engagement metrics (likes, comments, shares, views)
  - Post expiration countdown
  - Media attachments (images, videos)

### 12. Profile
- **Route**: `/dashboard/profile`
- **File**: `app/dashboard/profile/page.tsx`
- **Features**:
  - Store information
  - Logo/Banner upload
  - Business hours
  - Account settings
  - Complete settings sections (checkout, taxes, locations, languages, policies, apps)

### 13. Notifications
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
5. Deliveries
6. Shipping
7. Analytics
8. Payments
9. Socials ⭐ NEW
10. Users
11. Notifications
12. Customer Service (dropdown)
13. Chats
14. Settings/Profile

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
- `DUMMY_DELIVERIES`
- `DUMMY_SHIPMENTS`
- `DUMMY_USERS`
- `DUMMY_SOCIAL_POSTS` ⭐ NEW
- `DUMMY_FOLLOWERS` ⭐ NEW
- `DUMMY_PRODUCT_SPECS` ⭐ NEW (comprehensive specs for all 18 products)

## Product Specifications System ⭐ NEW

The platform supports comprehensive product specifications for ALL product categories:

### Size Charts Available:
- `CLOTHING_SIZE_CHART` - Men's/Women's/Kids tops, bottoms
- `FOOTWEAR_SIZE_CHART` - Men's/Women's/Kids shoes (US, UK, EU, CM)
- `RING_SIZE_CHART` - US, UK, EU with diameter/circumference
- `BRA_SIZE_CHART` - Band and cup sizes
- `TV_SIZE_GUIDE` - Viewing distance recommendations
- `MATTRESS_SIZE_CHART` - All standard sizes with dimensions
- `BICYCLE_SIZE_CHART` - Road and mountain bikes by rider height

### Product Category Specification Templates:
Templates in `PRODUCT_SPEC_TEMPLATES` for easy product creation:

**Electronics:**
- Audio (headphones, speakers, earbuds)
- TV (all sizes, resolutions, smart features)
- Smartphones (cameras, battery, storage)
- Laptops (processor, RAM, graphics)
- Cameras (sensor, megapixels, video)

**Clothing:**
- Tops (size, material, fit, neckline)
- Bottoms (size, rise, inseam)
- Dresses (length, occasion)
- Outerwear (insulation, water resistance)

**Footwear:**
- Sneakers, Boots, Sandals, Formal shoes

**Furniture:**
- Seating, Tables, Storage, Beds

**Beauty:**
- Skincare, Makeup, Haircare, Fragrance

**Vehicles:**
- Cars (engine, transmission, MPG, VIN)
- Motorcycles (displacement, seat height)
- Bicycles (frame size, gears)

**Appliances:**
- Kitchen, Laundry, Climate control

**Sports & Fitness:**
- Equipment, Fitness machines, Outdoor gear

### Type Definitions (in `types/index.ts`):
- `ClothingSpecs` - Full clothing attributes
- `FootwearSpecs` - Shoe specifications
- `ElectronicsSpecs` - General electronics
- `TVSpecs` - Television-specific
- `SmartphoneSpecs` - Mobile phone specs
- `LaptopSpecs` - Computer specifications
- `VehicleSpecs` - Car specifications
- `MotorcycleSpecs` - Motorcycle specs
- `FurnitureSpecs` - Furniture attributes
- `MattressSpecs` - Mattress specifications
- `BeautyProductSpecs` - Cosmetics/skincare
- `FoodProductSpecs` - Food/beverage items
- `SportsEquipmentSpecs` - Sports gear
- `FitnessEquipmentSpecs` - Gym equipment
- `ApplianceSpecs` - Home appliances
- `JewelrySpecs` - Jewelry items
- `WatchSpecs` - Watch specifications
- `BookSpecs` - Books/media
- `ToySpecs` - Toys/games
- `PetProductSpecs` - Pet supplies
- `GardenProductSpecs` - Garden/outdoor
- `ToolSpecs` - Tools/hardware

## Next Steps

1. Connect to real backend API
2. Implement actual Uber API integration
3. Implement actual Skynet API integration
4. Implement actual Chipper Cash integration
5. Add real-time WebSocket notifications
6. Implement actual authentication with JWT
