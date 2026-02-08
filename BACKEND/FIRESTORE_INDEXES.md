# Firestore Indexes Documentation

This document explains all the composite indexes required for the PURL marketplace application and why they are necessary.

## Overview

Firestore requires composite indexes when queries combine multiple fields with filtering (`where`) and/or ordering (`orderBy`). These indexes optimize query performance and are essential for the app to function properly.

---

## Index 1: Products Discovery (Basic)

**Collection ID:** `products`  
**Query Scope:** Collection group  
**Fields Indexed:**
- `isActive` (Ascending)
- `createdAt` (Descending)

**Index ID:** `CiCAgQyNxHEx`

### Purpose
This index powers the main product discovery feed in the buyer app. It allows users to browse all active products across all stores, sorted by newest first.

### Used In
- `purl-stores-app(buyer)/lib/services/product_service.dart` - `getDiscoverProductsStream()`
- Discover screen product grid
- Store profile product listings

### Why It's Needed
Combines filtering (only active products) with sorting (newest first) across all stores using a collection group query.

---

## Index 2: Products by Category

**Collection ID:** `products`  
**Query Scope:** Collection group  
**Fields Indexed:**
- `isActive` (Ascending)
- `categoryId` (Ascending)
- `createdAt` (Descending)

**Index ID:** `CiCAgJUpaMk`

### Purpose
Enables category-filtered product browsing. Users can filter products by categories like "Apparel", "Electronics", "Automotive", etc., while still seeing only active products sorted by date.

### Used In
- `purl-stores-app(buyer)/lib/services/product_service.dart` - `getDiscoverProductsStream()` with category filter
- Discover screen category tabs
- Categories screen

### Why It's Needed
Adds an additional filter (category) on top of the basic product query, requiring a composite index with three fields.

---

## Index 3: Featured Products

**Collection ID:** `products`  
**Query Scope:** Collection group  
**Fields Indexed:**
- `isActive` (Ascending)
- `isFeatured` (Ascending)

**Index ID:** `CiCAgQs3v6K` (Building)

### Purpose
Displays premium/featured products that stores have promoted. These appear prominently in the app to drive more visibility.

### Used In
- `purl-stores-app(buyer)/lib/services/product_service.dart` - `getFeaturedProductsStream()`
- Home screen featured section
- Special promotions

### Why It's Needed
Filters products by two boolean fields simultaneously (active AND featured), requiring a composite index.

---

## Index 4: Product Search

**Collection ID:** `products`  
**Query Scope:** Collection group  
**Fields Indexed:**
- `isActive` (Ascending)
- `name` (Ascending)

**Index ID:** `CiCAgJE9uJ` (Building)

### Purpose
Powers the product search functionality, allowing users to search for products by name while ensuring only active products are returned.

### Used In
- `purl-stores-app(buyer)/lib/services/product_service.dart` - `searchProducts()`
- Search bar in discover screen
- Global product search

### Why It's Needed
Combines filtering (active products) with text-based ordering (alphabetical by name) for search results.

---

## Index 5: Conversations

**Collection ID:** `conversations`  
**Query Scope:** Collection  
**Fields Indexed:**
- `participants` (Array)
- `lastMessageTime` (Descending)

**Index ID:** `CiCAg3F3oIK`

### Purpose
Manages the messaging system between buyers and sellers. Shows conversations sorted by most recent activity.

### Used In
- `purl-stores-app(buyer)/lib/services/messages_service.dart` - `getUserConversations()`, `getStoreConversations()`
- `purl-admin-app(seller)/lib/services/messages_service.dart` - `getStoreConversations()`
- Messages screen in both buyer and seller apps

### Why It's Needed
Filters conversations by participant (using array-contains) and sorts by last message time, requiring a composite index.

---

## Index 6: Product Questions

**Collection ID:** `questions`  
**Query Scope:** Collection  
**Fields Indexed:**
- `isPublic` (Ascending)
- `createdAt` (Descending)

**Index ID:** `CiCAg7Z4EK`

### Purpose
Displays Q&A on product detail pages. Shows only public questions sorted by newest first, allowing buyers to ask questions and sellers to answer.

### Used In
- `purl-stores-app(buyer)/lib/services/product_questions_service.dart` - `getProductQuestions()`
- Product detail screen - Questions tab
- Seller dashboard for answering questions

### Why It's Needed
Filters questions by visibility (public only) and sorts by date, requiring a composite index on the subcollection.

---

## Index 7: Unread Messages

**Collection ID:** `messages`  
**Query Scope:** Collection  
**Fields Indexed:**
- `senderId` (Ascending)
- `read` (Ascending)

**Index ID:** `CiCAgjmLEx` (Building)

### Purpose
Efficiently marks messages as read when a user opens a conversation. Finds all unread messages from the other participant.

### Used In
- `purl-stores-app(buyer)/lib/services/messages_service.dart` - `markAsRead()`
- `purl-admin-app(seller)/lib/services/messages_service.dart` - `markAsRead()`
- Message read receipts and unread counts

### Why It's Needed
Filters messages by sender (not equal to current user) AND read status (false), requiring a composite index.

---

## Index 8: Store Orders

**Collection ID:** `orders`  
**Query Scope:** Collection  
**Fields Indexed:**
- `createdAt` (Descending)

**Index ID:** Not required (single field)

### Purpose
Displays all orders for a specific store, sorted by newest first. Sellers can see incoming orders and manage fulfillment.

### Used In
- `purl-admin-app(seller)/lib/services/order_service.dart` - `getStoreOrdersStream()`
- Seller app Orders screen
- Order management and fulfillment

### Why It's Needed
This is a simple single-field query on a subcollection (`/stores/{storeId}/orders`), so no composite index is required. Firestore automatically indexes single fields.

### Query Structure
```dart
_firestore
  .collection('stores')
  .doc(storeId)
  .collection('orders')
  .orderBy('createdAt', descending: true)
  .snapshots()
```

---

## Index Management

### Automatic Creation
When you first run a query that needs an index, Firestore will throw an error with a direct link to create the index. Click the link and Firebase will auto-generate it.

### Manual Creation
You can also create indexes manually in Firebase Console:
1. Go to Firestore Database
2. Click on "Indexes" tab
3. Click "Add Index"
4. Fill in the collection ID, query scope, and fields as specified above

### Index Status
- **Enabled**: Index is ready and queries will work
- **Building**: Index is being created (can take a few minutes for large datasets)
- **Error**: Index creation failed (check configuration)

---

## Performance Considerations

### Collection vs Collection Group
- **Collection**: Queries within a specific path (e.g., messages under a specific conversation)
- **Collection Group**: Queries across all collections with the same name (e.g., all products across all stores)

Collection group queries are more powerful but require more careful index management.

### Index Size
Each index consumes storage and affects write performance slightly. However, the performance benefit for reads far outweighs the cost.

### Best Practices
1. Only create indexes you actually use
2. Monitor index usage in Firebase Console
3. Delete unused indexes to save storage
4. Test queries in development before deploying

---

## Troubleshooting

### Query Fails with "Index Required" Error
1. Check the error message for the index creation link
2. Click the link to auto-create the index
3. Wait for the index to finish building
4. Retry the query

### Index Building Takes Too Long
- Normal for large datasets (can take hours)
- Check Firebase Console for progress
- Queries will fail until building completes

### Query Still Fails After Creating Index
- Verify the index fields match exactly (including ascending/descending)
- Check the query scope (Collection vs Collection Group)
- Ensure the index status is "Enabled" not "Building"

---

## Summary

All 8 indexes/queries are essential for the PURL marketplace to function properly:

1. ✅ **Products Discovery** - Browse all products
2. ✅ **Products by Category** - Filter by category
3. 🔄 **Featured Products** - Show promoted items
4. 🔄 **Product Search** - Search functionality
5. ✅ **Conversations** - Messaging system
6. ✅ **Product Questions** - Q&A on products
7. 🔄 **Unread Messages** - Read receipts
8. ✅ **Store Orders** - Seller order management (no index needed)

**Legend:**
- ✅ Enabled and working
- 🔄 Building (will be ready soon)

---

*Last Updated: February 8, 2026*
