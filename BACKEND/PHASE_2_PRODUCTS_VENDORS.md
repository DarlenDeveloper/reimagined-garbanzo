# Phase 2: Product & Vendor Management

## Overview

Implement product catalog management, vendor store profiles, and category organization using Cloud Firestore and Cloud Storage.

## Firestore Collections

### Categories Collection

```
/categories/{categoryId}
├── id: string
├── name: string
├── slug: string
├── icon: string
├── imageUrl: string?
├── parentId: string? (for subcategories)
├── productCount: number
├── isActive: boolean
├── sortOrder: number
└── createdAt: timestamp
```

### Products Collection

```
/products/{productId}
├── id: string
├── vendorId: string (ref to /vendors)
├── vendorName: string (denormalized)
├── name: string
├── slug: string
├── description: string
├── categoryId: string
├── categoryName: string (denormalized)
├── price: number
├── compareAtPrice: number? (original price for discounts)
├── currency: string (default: 'KES')
├── images: array
│   ├── url: string
│   ├── thumbnailUrl: string
│   └── sortOrder: number
├── variants: array
│   ├── id: string
│   ├── name: string (e.g., "Size", "Color")
│   ├── value: string (e.g., "Large", "Red")
│   ├── price: number?
│   ├── sku: string
│   └── stock: number
├── specs: map (key-value specifications)
├── tags: string[]
├── rating: number
├── reviewCount: number
├── totalSold: number
├── stock: number (for non-variant products)
├── lowStockThreshold: number
├── trackInventory: boolean
├── isActive: boolean
├── isPublished: boolean
├── isFeatured: boolean
├── createdAt: timestamp
├── updatedAt: timestamp
└── publishedAt: timestamp?
```

### Product Reviews Subcollection

```
/products/{productId}/reviews/{reviewId}
├── id: string
├── userId: string
├── userName: string
├── userAvatar: string?
├── rating: number (1-5)
├── title: string?
├── content: string
├── images: string[]
├── isVerifiedPurchase: boolean
├── helpfulCount: number
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Vendor Stores (Extended)

```
/vendors/{vendorId}/settings
├── payoutSchedule: 'daily' | 'weekly' | 'monthly'
├── payoutMethod: 'mpesa' | 'bank'
├── payoutDetails: map (encrypted)
├── lowStockAlerts: boolean
├── orderNotifications: boolean
├── chatNotifications: boolean
└── autoAcceptOrders: boolean
```

## Cloud Storage Structure

```
/vendors/{vendorId}/
├── logo.{ext}
├── banner.{ext}
└── products/
    └── {productId}/
        ├── image_0.{ext}
        ├── image_1.{ext}
        └── thumb_0.{ext}
```

## Image Processing

### Cloud Function for Image Optimization

```typescript
// functions/src/storage/onImageUpload.ts
export const processProductImage = functions.storage
  .object()
  .onFinalize(async (object) => {
    if (!object.name?.includes('/products/')) return;
    
    // Generate thumbnail (300x300)
    // Optimize original (max 1200px width)
    // Update Firestore with URLs
  });
```

### Image Requirements

| Type | Max Size | Dimensions | Format |
|------|----------|------------|--------|
| Product Image | 5MB | 1200x1200 | JPEG, PNG, WebP |
| Thumbnail | Auto | 300x300 | WebP |
| Store Logo | 2MB | 500x500 | JPEG, PNG |
| Store Banner | 5MB | 1200x400 | JPEG, PNG |

## API Endpoints (Cloud Functions)

### Product Management

```typescript
// Create Product
POST /api/vendors/{vendorId}/products
Body: { name, description, price, categoryId, images[], variants[], specs }

// Update Product
PUT /api/vendors/{vendorId}/products/{productId}
Body: { ...fields to update }

// Delete Product (soft delete)
DELETE /api/vendors/{vendorId}/products/{productId}

// Get Vendor Products
GET /api/vendors/{vendorId}/products?page=1&limit=20&status=active

// Bulk Update Stock
PATCH /api/vendors/{vendorId}/products/stock
Body: { updates: [{ productId, stock }] }
```

### Category Management (Admin)

```typescript
// Get Categories
GET /api/categories

// Get Category Products
GET /api/categories/{categoryId}/products?page=1&limit=20
```

### Public Product APIs

```typescript
// Get Featured Products
GET /api/products/featured?limit=10

// Get Product Details
GET /api/products/{productId}

// Search Products
GET /api/products/search?q=keyword&category=&minPrice=&maxPrice=&sort=

// Get Product Reviews
GET /api/products/{productId}/reviews?page=1&limit=10
```

## Firestore Indexes

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "categoryId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "isFeatured", "order": "ASCENDING" },
        { "fieldPath": "rating", "order": "DESCENDING" }
      ]
    }
  ]
}
```

## Security Rules

```javascript
// Products
match /products/{productId} {
  allow read: if resource.data.isActive == true || 
              request.auth.uid == resource.data.vendorId;
  allow create: if request.auth != null && 
                request.auth.uid == request.resource.data.vendorId;
  allow update: if request.auth.uid == resource.data.vendorId;
  allow delete: if false; // Soft delete only
}

// Reviews
match /products/{productId}/reviews/{reviewId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update: if request.auth.uid == resource.data.userId;
  allow delete: if request.auth.uid == resource.data.userId;
}

// Categories
match /categories/{categoryId} {
  allow read: if true;
  allow write: if false; // Admin only via Cloud Functions
}
```

## Vendor Dashboard Queries

```dart
// Get vendor's products
final products = await FirebaseFirestore.instance
  .collection('products')
  .where('vendorId', isEqualTo: vendorId)
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get();

// Get low stock products
final lowStock = await FirebaseFirestore.instance
  .collection('products')
  .where('vendorId', isEqualTo: vendorId)
  .where('trackInventory', isEqualTo: true)
  .where('stock', isLessThanOrEqualTo: 10)
  .get();
```

## Implementation Checklist

- [ ] Create Firestore collections and indexes
- [ ] Set up Cloud Storage buckets
- [ ] Implement image upload and processing
- [ ] Build product CRUD Cloud Functions
- [ ] Implement category management
- [ ] Build vendor product management screens
- [ ] Build buyer product browsing screens
- [ ] Implement product search
- [ ] Implement product reviews
- [ ] Test all product flows
