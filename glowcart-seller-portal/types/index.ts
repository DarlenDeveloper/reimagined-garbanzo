// Vendor Types
export interface Vendor {
  vendorId: string
  email: string
  storeName: string
  description?: string
  logoUrl?: string
  bannerUrl?: string
  contactEmail?: string
  phoneNumber?: string
  businessType?: string
  subscriptionTier: "free" | "premium"
  status: "active" | "inactive"
  createdAt: string
}

// Product Types
export interface Product {
  productId: string
  vendorId: string
  name: string
  description?: string
  price: number
  currency: string
  categoryId?: string
  images: string[]
  variants: ProductVariant[]
  sku?: string
  status: "active" | "inactive" | "out_of_stock"
  createdAt: string
  updatedAt: string
}

export interface ProductVariant {
  variantId: string
  productId: string
  name: string
  sku?: string
  priceAdjustment: number
}

// Inventory Types
export interface InventoryItem {
  productId: string
  productName: string
  variantId?: string
  quantity: number
  lowStockAlert: boolean
  threshold: number
  updatedAt: string
}

// Order Types
export type OrderStatus = "pending" | "processing" | "in_transit" | "delivered" | "cancelled"

export interface Order {
  orderId: string
  vendorId: string
  buyerId: string
  items: OrderItem[]
  totalAmount: number
  currency: string
  status: OrderStatus
  deliveryAddress: Address
  createdAt: string
  updatedAt: string
}

export interface OrderItem {
  productId: string
  productName: string
  quantity: number
  price: number
  variantId?: string
}

export interface Address {
  streetAddress: string
  city: string
  state?: string
  postalCode?: string
  country: string
}

export interface OrderEvent {
  eventId: string
  orderId: string
  eventType: string
  description: string
  createdAt: string
}

// Transaction Types
export interface Transaction {
  transactionId: string
  orderId: string
  vendorId: string
  grossAmount: number
  commission: number
  netAmount: number
  currency: string
  status: string
  processedAt: string
}

// Analytics Types
export interface DashboardMetrics {
  totalSales: number
  orderCount: number
  revenue: number
  commission: number
  netEarnings: number
  period: string
  topProducts: TopProduct[]
  salesTrend: DataPoint[]
}

export interface TopProduct {
  productId: string
  productName: string
  sales: number
  revenue: number
}

export interface DataPoint {
  date: string
  value: number
}

// Notification Types
export interface Notification {
  notificationId: string
  vendorId: string
  type: string
  title: string
  message: string
  readAt?: string
  createdAt: string
}


// Delivery Types
export interface Delivery {
  deliveryId: string
  orderId: string
  deliveryProvider: "uber" | "manual"
  deliveryProviderId?: string
  pickupAddress: Address
  dropoffAddress: Address
  status: "pending" | "assigned" | "picked_up" | "in_transit" | "delivered" | "failed"
  estimatedPickupTime?: string
  actualPickupTime?: string
  estimatedDeliveryTime?: string
  actualDeliveryTime?: string
  trackingUrl?: string
  driverName?: string
  driverPhone?: string
  createdAt: string
  updatedAt: string
}

// Shipment Types
export interface Shipment {
  shipmentId: string
  orderId: string
  shippingProvider: "skynet" | "other"
  trackingNumber: string
  shippingLabelUrl?: string
  status: "pending" | "label_created" | "picked_up" | "in_transit" | "out_for_delivery" | "delivered" | "returned"
  weight?: number
  dimensions?: {
    length: number
    width: number
    height: number
  }
  shippedAt?: string
  deliveredAt?: string
  createdAt: string
  updatedAt: string
}

// User Role Types
export type UserRole = "owner" | "admin" | "manager" | "staff"

export interface User {
  userId: string
  vendorId: string
  email: string
  name: string
  role: UserRole
  permissions: string[]
  status: "active" | "inactive"
  lastLogin?: string
  createdAt: string
}
