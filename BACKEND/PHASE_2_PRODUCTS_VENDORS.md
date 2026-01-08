# Phase 2: Product & Vendor Management

## Overview

Implement product catalog management, vendor store profiles, and category organization using Cloud Firestore and Cloud Storage.

## Implementation Status

| Component | Status | Location |
|-----------|--------|----------|
| Product Model | ✅ Complete | `purl-admin-app(seller)/lib/models/product.dart` |
| ProductService (CRUD) | ✅ Complete | `purl-admin-app(seller)/lib/services/product_service.dart` |
| ImageService | ✅ Complete | `purl-admin-app(seller)/lib/services/image_service.dart` |
| CurrencyService | ✅ Complete | `purl-admin-app(seller)/lib/services/currency_service.dart` |
| Category Taxonomy | ✅ Complete | `purl-admin-app(seller)/lib/data/category_taxonomy.dart` |
| Products Screen UI | ✅ Complete | `purl-admin-app(seller)/lib/screens/products_screen.dart` |
| Add Product Sheet | ✅ Complete | With image picker, category selection, dynamic attributes |
| Edit Product Sheet | ✅ Complete | Edit name, price, stock, images, description, active status |
| Currency Selection | ✅ Complete | `purl-admin-app(seller)/lib/screens/currency_selection_screen.dart` |
| Inventory Screen | ✅ Complete | `purl-admin-app(seller)/lib/screens/inventory_screen.dart` |
| UI Integration | ✅ Complete | Real-time Firestore stream connected |
| Buyer App Products | ❌ Pending | `purl-stores-app(buyer)` |
| Product Reviews | ❌ Pending | - |
| Cloud Functions | ❌ Pending | - |

---

## Firestore Structure

### Store Currencies Collection

Stores the default currency for each store. Checked on app startup - if not set, user is prompted to select.

```
/storeCurrencies/{storeId}
├── currency: string              // e.g., 'KES', 'USD', 'EUR'
└── updatedAt: timestamp
```

### Products Subcollection (Under Stores)

Products are stored as a subcollection under stores for efficient queries, security, and scalability.

```
/stores/{storeId}/products/{productId}
├── name: string
├── slug: string
├── description: string
├── categoryId: string              // Top-level: 'electronics', 'apparel', etc.
├── subcategoryId: string?          // Second-level: 'cell_phones', 'clothing', etc.
├── productTypeId: string?          // Third-level: 'smartphones', 'tshirts', etc.
├── categoryPath: string?           // Full path: 'electronics/cell_phones/smartphones'
├── condition: string?              // 'New', 'Used', 'Refurbished', 'Collectible'
├── price: number
├── compareAtPrice: number?         // Original price for showing discounts
├── currency: string                // Default: 'KES'
├── images: array
│   ├── url: string
│   ├── thumbnailUrl: string?
│   └── sortOrder: number
├── variants: array
│   ├── id: string
│   ├── name: string                // e.g., "Size", "Color"
│   ├── value: string               // e.g., "Large", "Red"
│   ├── price: number?              // Override price for variant
│   ├── sku: string?
│   └── stock: number
├── specs: map                      // Category-specific attributes
│   └── {attributeName}: dynamic    // e.g., {'brand': 'Apple', 'storage': '256GB'}
├── tags: string[]
├── stock: number                   // For non-variant products
├── lowStockThreshold: number       // Default: 5
├── trackInventory: boolean         // Default: true
├── isActive: boolean               // Visible to buyers
├── isPublished: boolean            // Listed on marketplace
├── isFeatured: boolean             // Highlighted in store
├── rating: number                  // Average rating (0.0-5.0)
├── reviewCount: number
├── totalSold: number
├── createdAt: timestamp
├── updatedAt: timestamp
└── publishedAt: timestamp?
```

### Product Reviews Subcollection

```
/stores/{storeId}/products/{productId}/reviews/{reviewId}
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

---

## Cloud Storage Structure

```
/stores/{storeId}/
├── logo.{ext}
├── banner.{ext}
└── products/{productId}/
    ├── image_0_{timestamp}.{ext}
    ├── image_1_{timestamp}.{ext}
    └── ...
```

### Image Requirements

| Type | Max Size | Dimensions | Formats |
|------|----------|------------|---------|
| Product Image | 5MB | 1200x1200 | JPEG, PNG, WebP |
| Store Logo | 5MB | 1200x1200 | JPEG, PNG, WebP |
| Store Banner | 5MB | 1200x1200 | JPEG, PNG, WebP |

---

## Implemented Services

### ProductService

Location: `purl-admin-app(seller)/lib/services/product_service.dart`

#### Create Operations
```dart
// Create a new product
Future<String> createProduct({
  required String storeId,
  required String name,
  required double price,
  required String categoryId,
  String? subcategoryId,
  String? productTypeId,
  String? condition,
  String description = '',
  String currency = 'KES',
  double? compareAtPrice,
  List<ProductImage> images = const [],
  List<ProductVariant> variants = const [],
  Map<String, dynamic> specs = const {},
  List<String> tags = const [],
  int stock = 0,
  int lowStockThreshold = 5,
  bool trackInventory = true,
  bool isActive = true,
  bool isPublished = false,
  bool isFeatured = false,
});
```

#### Read Operations
```dart
// Get single product
Future<Product?> getProductById(String storeId, String productId);

// Get products with filtering and pagination
Future<List<Product>> getProducts(
  String storeId, {
  bool? isActive,
  String? categoryId,
  int limit = 50,
  DocumentSnapshot? startAfter,
  String orderBy = 'createdAt',
  bool descending = true,
});

// Real-time stream
Stream<List<Product>> getProductsStream(String storeId, {...});

// Specialized queries
Future<List<Product>> getLowStockProducts(String storeId);
Future<List<Product>> getOutOfStockProducts(String storeId);
Future<List<Product>> searchProducts(String storeId, String query, {int limit = 20});
Future<int> getProductCount(String storeId, {bool? isActive});
```

#### Update Operations
```dart
// Update specific fields
Future<void> updateProduct(String storeId, String productId, Map<String, dynamic> updates);

// Update from model
Future<void> updateProductFromModel(Product product);

// Toggle operations
Future<void> toggleProductActive(String storeId, String productId);
Future<void> toggleProductPublished(String storeId, String productId);
Future<void> toggleProductFeatured(String storeId, String productId);

// Stock management
Future<void> updateStock(String storeId, String productId, int newStock);
Future<void> adjustStock(String storeId, String productId, int adjustment);
Future<void> bulkUpdateStock(String storeId, Map<String, int> stockUpdates);

// Image management
Future<void> updateImages(String storeId, String productId, List<ProductImage> images);
Future<void> addImage(String storeId, String productId, ProductImage image);

// Specs management
Future<void> updateSpecs(String storeId, String productId, Map<String, dynamic> specs);
```

#### Delete Operations
```dart
// Soft delete (recommended)
Future<void> deleteProduct(String storeId, String productId);

// Hard delete (only for unsold products)
Future<void> hardDeleteProduct(String storeId, String productId);
```

#### Other Operations
```dart
// Duplicate a product
Future<String> duplicateProduct(String storeId, String productId, {String? newName});
```

### ImageService

Location: `purl-admin-app(seller)/lib/services/image_service.dart`

```dart
// Pick images
Future<XFile?> pickImage({ImageSource source, int maxWidth, int maxHeight, int imageQuality});
Future<List<XFile>> pickMultipleImages({int maxWidth, int maxHeight, int imageQuality, int? limit});
Future<List<XFile>> pickProductImages(); // Up to 10 images

// Upload product images
Future<ProductImage> uploadProductImage({
  required String storeId,
  required String productId,
  required File file,
  required int sortOrder,
  void Function(double)? onProgress,
});

Future<List<ProductImage>> uploadProductImages({
  required String storeId,
  required String productId,
  required List<XFile> files,
  void Function(int current, int total, double progress)? onProgress,
});

// Delete images
Future<void> deleteProductImage({required String storeId, required String productId, required String imageUrl});
Future<void> deleteAllProductImages({required String storeId, required String productId});

// Store images
Future<String> uploadStoreLogo(String storeId, File file);
Future<String> uploadStoreBanner(String storeId, File file);
```

---

## Product Model

Location: `purl-admin-app(seller)/lib/models/product.dart`

### Classes

#### ProductImage
```dart
class ProductImage {
  final String url;
  final String? thumbnailUrl;
  final int sortOrder;
}
```

#### ProductVariant
```dart
class ProductVariant {
  final String id;
  final String name;       // e.g., "Size", "Color"
  final String value;      // e.g., "Large", "Red"
  final double? price;     // Override price
  final String? sku;
  final int stock;
}
```

#### Product
```dart
class Product {
  // Identifiers
  final String id;
  final String storeId;
  
  // Basic info
  final String name;
  final String? slug;
  final String description;
  
  // Category hierarchy
  final String categoryId;
  final String? subcategoryId;
  final String? productTypeId;
  final String? categoryPath;
  final String? condition;
  
  // Pricing
  final double price;
  final double? compareAtPrice;
  final String currency;
  
  // Media & variants
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final Map<String, dynamic> specs;
  final List<String> tags;
  
  // Inventory
  final int stock;
  final int lowStockThreshold;
  final bool trackInventory;
  
  // Status
  final bool isActive;
  final bool isPublished;
  final bool isFeatured;
  
  // Stats
  final double rating;
  final int reviewCount;
  final int totalSold;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  
  // Computed properties
  String get stockStatus;        // 'In Stock', 'Low Stock', 'Out of Stock', 'Not Tracked'
  bool get hasVariants;
  int get totalStock;            // Sum of variant stocks or base stock
  String? get primaryImageUrl;
  int? get discountPercentage;
}
```

---

## Category Taxonomy

Location: `purl-admin-app(seller)/lib/data/category_taxonomy.dart`

### Categories (11 total)

| ID | Name | Subcategories |
|----|------|---------------|
| `apparel` | Apparel & Fashion | Clothing, Shoes, Jewelry & Accessories |
| `electronics` | Electronics & Technology | Cell Phones, Computers, TVs & Home Entertainment, Cameras & Photography |
| `automotive` | Automotive | Vehicles, Auto Parts & Accessories |
| `home_living` | Home & Living | Furniture, Home Appliances, Home Decor |
| `beauty` | Beauty & Personal Care | Skincare, Makeup, Hair Care, Fragrances |
| `baby_kids` | Baby & Kids | Baby Gear, Kids Clothing, Toys & Games |
| `sports` | Sports & Outdoors | Sports Equipment, Outdoor Gear, Fitness |
| `books` | Books & Media | Books, Music, Movies |
| `art` | Art & Collectibles | Fine Art, Collectibles, Memorabilia |
| `grocery` | Grocery & Food | Packaged Foods, Beverages, Fresh & Frozen |
| `other` | Other | General, Services, Handmade & Crafts, Vintage & Antiques, Digital Products |

### Taxonomy Helper Methods
```dart
class CategoryTaxonomy {
  static List<Category> get categories;
  static Category? getCategoryById(String id);
  static Subcategory? getSubcategoryById(String categoryId, String subcategoryId);
  static ProductType? getProductTypeById(String categoryId, String subcategoryId, String productTypeId);
}
```

### Condition Rules by Category

| Category | Allowed Conditions |
|----------|-------------------|
| Baby & Kids | New only |
| Beauty | New only |
| Grocery | New only |
| Apparel (Clothing/Shoes) | New, Used |
| Electronics | New, Used, Refurbished |
| Watches, Fine Jewelry | New, Used, Refurbished, Collectible |
| Books, Art | New, Used, Collectible |
| Other | Varies by subcategory |

---

## Security Rules

```javascript
// Store-scoped products
match /stores/{storeId}/products/{productId} {
  // Anyone can read active products
  allow read: if resource.data.isActive == true;
  
  // Store members can read all products (including inactive)
  allow read: if request.auth != null && 
              request.auth.uid in get(/databases/$(database)/documents/stores/$(storeId)).data.authorizedUsers;
  
  // Only store members can create/update
  allow create, update: if request.auth != null && 
                        request.auth.uid in get(/databases/$(database)/documents/stores/$(storeId)).data.authorizedUsers;
  
  // No hard deletes (soft delete via isActive = false)
  allow delete: if false;
}

// Product reviews
match /stores/{storeId}/products/{productId}/reviews/{reviewId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update, delete: if request.auth.uid == resource.data.userId;
}
```

---

## Firestore Indexes

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
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
        { "fieldPath": "trackInventory", "order": "ASCENDING" },
        { "fieldPath": "stock", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## Usage Examples

### Creating a Product

```dart
final productService = ProductService();

final productId = await productService.createProduct(
  storeId: 'store123',
  name: 'iPhone 15 Pro Max',
  price: 189999,
  categoryId: 'electronics',
  subcategoryId: 'cell_phones',
  productTypeId: 'smartphones',
  condition: 'New',
  description: 'Latest iPhone with A17 Pro chip',
  currency: 'KES',
  specs: {
    'brand': 'Apple',
    'model': 'iPhone 15 Pro Max',
    'storage': '256GB',
    'color': ['Black Titanium', 'White Titanium'],
    'carrierLock': 'Unlocked',
  },
  stock: 10,
  isActive: true,
);
```

### Uploading Product Images

```dart
final imageService = ImageService();

// Pick images
final files = await imageService.pickProductImages();

// Upload with progress
final images = await imageService.uploadProductImages(
  storeId: 'store123',
  productId: productId,
  files: files,
  onProgress: (current, total, progress) {
    print('Uploading image $current of $total: ${(progress * 100).toInt()}%');
  },
);

// Update product with images
await productService.updateImages('store123', productId, images);
```

### Fetching Products

```dart
// Get all active products
final products = await productService.getProducts(
  'store123',
  isActive: true,
  orderBy: 'createdAt',
  descending: true,
);

// Get products by category
final electronics = await productService.getProducts(
  'store123',
  categoryId: 'electronics',
);

// Real-time stream
productService.getProductsStream('store123').listen((products) {
  // Update UI
});
```

---

## Implementation Checklist

- [x] Create Product model with Firestore serialization
- [x] Create ProductService with full CRUD operations
- [x] Create ImageService for Firebase Storage
- [x] Implement category taxonomy with 11 categories
- [x] Add "Other" catch-all category
- [x] Add taxonomy helper methods
- [x] Store access verification on all write operations
- [x] Connect ProductsScreen UI to ProductService
- [x] Implement image picker in add product flow
- [x] Add loading/error states to UI
- [x] Implement product editing screen
- [x] Implement inventory screen with real-time data
- [x] Add stock update functionality with quick adjust buttons
- [x] Add iOS permissions (NSPhotoLibraryUsageDescription, NSCameraUsageDescription)
- [x] Add Android permissions (READ_MEDIA_IMAGES, CAMERA)
- [ ] Build buyer app product browsing
- [ ] Implement product search with Algolia (optional)
- [ ] Implement product reviews
- [ ] Deploy Firestore security rules
- [ ] Create Firestore indexes
- [ ] Test all product flows
