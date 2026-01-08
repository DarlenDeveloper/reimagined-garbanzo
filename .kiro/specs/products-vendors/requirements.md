# Requirements Document

## Introduction

This feature implements the product category taxonomy system for Purl marketplace. The core focus is enabling sellers to add products with category-specific attributes (size, color, brand, etc.) that power the buyer's search and filter experience. Each category has its own set of required and optional attributes.

## Glossary

- **Seller_App**: The Purl Admin Flutter application used by store owners and runners
- **Buyer_App**: The Purl Stores Flutter application used by shoppers
- **Product**: An item listed for sale with name, price, images, and category-specific attributes
- **Category**: A top-level classification (Electronics, Apparel, Automotive, Home, Beauty, etc.)
- **Subcategory**: A second-level classification within a category (e.g., Cell Phones under Electronics)
- **Attribute**: Category-specific fields that enable filtering (size, color, brand, storage, etc.)
- **Condition**: Product state allowed per category (New, Used, Refurbished, Collectible)
- **Taxonomy**: The hierarchical structure of categories, subcategories, and their attributes
- **Store**: A vendor's shop containing their products
- **ProductService**: Service class handling Firestore CRUD operations for products

## Requirements

### Requirement 1: Category Selection

**User Story:** As a seller, I want to select a category and subcategory for my product, so that it appears in the correct section for buyers.

#### Acceptance Criteria

1. WHEN a seller starts adding a product, THE Seller_App SHALL display a list of top-level categories (Electronics, Apparel, Automotive, Home, Beauty, Baby, Sports, Books, Art, Grocery)
2. WHEN a seller selects a top-level category, THE Seller_App SHALL display subcategories for that category
3. WHEN a seller selects Electronics, THE Seller_App SHALL show subcategories: Cell Phones, Computers, Consumer Electronics, Camera & Photo
4. WHEN a seller selects Apparel, THE Seller_App SHALL show subcategories: Clothing, Shoes, Jewelry, Fine Jewelry
5. WHEN a seller selects Automotive, THE Seller_App SHALL show subcategories: Vehicles, Auto Parts & Accessories
6. WHEN a seller selects a subcategory, THE Seller_App SHALL store the category path (e.g., "electronics/cell_phones")

### Requirement 2: Condition Selection Based on Category

**User Story:** As a seller, I want to see only the conditions allowed for my product category, so that I comply with marketplace rules.

#### Acceptance Criteria

1. WHEN a seller selects Baby Products, THE Seller_App SHALL only allow condition "New"
2. WHEN a seller selects Beauty, THE Seller_App SHALL only allow condition "New"
3. WHEN a seller selects Grocery, THE Seller_App SHALL only allow condition "New"
4. WHEN a seller selects Clothing or Shoes, THE Seller_App SHALL allow conditions "New" and "Used"
5. WHEN a seller selects Electronics (Cell Phones, Computers), THE Seller_App SHALL allow conditions "New", "Used", and "Refurbished"
6. WHEN a seller selects Watches or Fine Jewelry, THE Seller_App SHALL allow conditions "New", "Used", "Collectible", and "Refurbished"
7. WHEN a seller selects Books or Art, THE Seller_App SHALL allow conditions "New", "Used", and "Collectible"

### Requirement 3: Dynamic Attribute Fields for Apparel

**User Story:** As a seller listing clothing or shoes, I want to specify size, color, brand, and material, so that buyers can filter by these attributes.

#### Acceptance Criteria

1. WHEN a seller selects Clothing subcategory, THE Seller_App SHALL display fields: Size (XS-XXXL), Color (palette), Brand (text), Gender (Men/Women/Unisex/Kids), Material (multi-select)
2. WHEN a seller selects Shoes subcategory, THE Seller_App SHALL display fields: Size US (4-15), Size EU (35-50), Color, Brand, Gender, Type (Sneakers/Boots/Sandals/etc.), Material
3. WHEN a seller selects Jewelry subcategory, THE Seller_App SHALL display fields: Type (Necklace/Ring/Bracelet/etc.), Material (Gold/Silver/etc.), Gemstone, Gender
4. THE Seller_App SHALL require Size, Color, and Brand fields for Clothing products
5. THE Seller_App SHALL require Size and Brand fields for Shoes products

### Requirement 4: Dynamic Attribute Fields for Electronic

### Requirement 2: Product Management

**User Story:** As a seller, I want to view, edit, and delete my products, so that I can keep my catalog up to date.

#### Acceptance Criteria

1. WHEN a seller opens the Products screen, THE Seller_App SHALL display all products for their store from Firestore
2. WHEN a seller taps a product, THE Seller_App SHALL display product details with edit and delete options
3. WHEN a seller edits a product, THE ProductService SHALL update the product document in Firestore
4. WHEN a seller deletes a product, THE ProductService SHALL remove the product document from Firestore
5. WHEN a seller toggles product status, THE ProductService SHALL update the isActive field

### Requirement 3: Product Listing for Buyers

**User Story:** As a buyer, I want to browse products from stores, so that I can discover items to purchase.

#### Acceptance Criteria

1. WHEN a buyer opens the home screen, THE Buyer_App SHALL fetch and display products from Firestore
2. WHEN a buyer taps a store, THE Buyer_App SHALL display all active products from that store
3. WHEN a buyer taps a product, THE Buyer_App SHALL display the full product details including images and attributes
4. THE Buyer_App SHALL only display products where isActive equals true

### Requirement 4: Category-Based Filtering

**User Story:** As a buyer, I want to filter products by category and attributes, so that I can find exactly what I'm looking for.

#### Acceptance Criteria

1. WHEN a buyer selects a category filter, THE Buyer_App SHALL query products matching that category
2. WHEN a buyer applies attribute filters (size, color, brand), THE Buyer_App SHALL filter results accordingly
3. WHEN a buyer applies a price range filter, THE Buyer_App SHALL display products within that range
4. WHEN a buyer applies a condition filter, THE Buyer_App SHALL display products matching that condition
5. WHEN multiple filters are applied, THE Buyer_App SHALL combine them with AND logic

### Requirement 5: Product Search

**User Story:** As a buyer, I want to search for products by name or keyword, so that I can quickly find specific items.

#### Acceptance Criteria

1. WHEN a buyer enters a search query, THE Buyer_App SHALL search product names and descriptions
2. WHEN search results are returned, THE Buyer_App SHALL display matching products with relevance
3. WHEN no results are found, THE Buyer_App SHALL display an empty state with suggestions

### Requirement 6: Image Management

**User Story:** As a seller, I want to upload multiple product images, so that buyers can see my products clearly.

#### Acceptance Criteria

1. WHEN a seller adds images, THE Seller_App SHALL allow selecting up to 10 images
2. WHEN images are selected, THE Seller_App SHALL display image previews with reorder capability
3. WHEN a product is saved, THE ProductService SHALL upload images to Firebase Storage
4. WHEN images are uploaded, THE ProductService SHALL store download URLs in the product document
5. IF image upload fails, THEN THE Seller_App SHALL display an error and allow retry

### Requirement 7: Inventory Tracking

**User Story:** As a seller, I want to track product stock levels, so that I don't oversell items.

#### Acceptance Criteria

1. WHEN a seller sets stock quantity, THE ProductService SHALL store the stock value
2. WHEN stock is low (below 5), THE Seller_App SHALL display a "Low Stock" indicator
3. WHEN stock is zero, THE Seller_App SHALL display an "Out of Stock" indicator
4. WHEN a product is out of stock, THE Buyer_App SHALL display it as unavailable

### Requirement 8: Store Profile Display

**User Story:** As a buyer, I want to view store profiles, so that I can learn about sellers before purchasing.

#### Acceptance Criteria

1. WHEN a buyer taps a store, THE Buyer_App SHALL display the store profile with name, logo, and description
2. WHEN viewing a store, THE Buyer_App SHALL display the store's product count
3. WHEN viewing a store, THE Buyer_App SHALL display the store's products in a grid/list view
