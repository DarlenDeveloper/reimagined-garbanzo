/// Product Category Taxonomy for Purl Marketplace
/// Based on BACKEND/CATEGORY_TAXONOMY.md

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Attribute field types
enum AttributeType { select, multiSelect, text, number, date, boolean }

class ProductAttribute {
  final String name;
  final String label;
  final AttributeType type;
  final List<String>? options;
  final bool required;
  final String? hint;

  const ProductAttribute({
    required this.name,
    required this.label,
    required this.type,
    this.options,
    this.required = false,
    this.hint,
  });
}

class ProductType {
  final String id;
  final String name;
  final List<String> allowedConditions;
  final List<ProductAttribute> attributes;

  const ProductType({
    required this.id,
    required this.name,
    required this.allowedConditions,
    required this.attributes,
  });
}

class Subcategory {
  final String id;
  final String name;
  final List<ProductType> productTypes;

  const Subcategory({
    required this.id,
    required this.name,
    required this.productTypes,
  });
}

class Category {
  final String id;
  final String name;
  final String iconName;
  final List<Subcategory> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.subcategories,
  });

  IconData get icon {
    switch (iconName) {
      case 'shirt':
        return Iconsax.shop;
      case 'mobile':
        return Iconsax.mobile;
      case 'car':
        return Iconsax.car;
      case 'home_2':
        return Iconsax.home_2;
      case 'brush_1':
        return Iconsax.brush_1;
      case 'lovely':
        return Iconsax.lovely;
      case 'weight':
        return Iconsax.weight;
      case 'book':
        return Iconsax.book;
      case 'designtools':
        return Iconsax.designtools;
      case 'shopping_cart':
        return Iconsax.shopping_cart;
      default:
        return Iconsax.box;
    }
  }
}

// Common attribute options
class AttributeOptions {
  static const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  static const genders = ['Men', 'Women', 'Unisex', 'Kids'];
  static const shoeSizesUS = ['4', '4.5', '5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11', '11.5', '12', '13', '14', '15'];
  static const shoeSizesEU = ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50'];
  static const colors = ['Black', 'White', 'Gray', 'Silver', 'Beige', 'Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple', 'Pink', 'Navy', 'Brown', 'Gold', 'Rose Gold', 'Multi-color'];
  static const clothingMaterials = ['Cotton', 'Polyester', 'Linen', 'Wool', 'Silk', 'Denim', 'Leather', 'Synthetic', 'Blend'];
  static const conditions = ['New', 'Used', 'Refurbished', 'Collectible'];
  static const phoneStorage = ['32GB', '64GB', '128GB', '256GB', '512GB', '1TB'];
  static const phoneRam = ['4GB', '6GB', '8GB', '12GB', '16GB'];
  static const laptopRam = ['4GB', '8GB', '16GB', '32GB', '64GB', '128GB'];
  static const storageSize = ['128GB', '256GB', '512GB', '1TB', '2TB', '4TB'];
  static const screenSizes = ['Under 6"', '6.0-6.4"', '6.5-6.9"', '7"+'];
  static const batteryHealth = ['100%', '90-99%', '80-89%', 'Below 80%'];
  static const carrierLock = ['Unlocked', 'Safaricom', 'Airtel', 'MTN', 'Telkom'];
}

// The complete taxonomy
class CategoryTaxonomy {
  static List<Category> get categories => [
    _apparel,
    _electronics,
    _automotive,
    _homeLiving,
    _beauty,
    _babyKids,
    _sports,
    _books,
    _art,
    _grocery,
    _other,
  ];

  static Category? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get subcategory by category and subcategory IDs
  static Subcategory? getSubcategoryById(String categoryId, String subcategoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) return null;
    try {
      return category.subcategories.firstWhere((s) => s.id == subcategoryId);
    } catch (_) {
      return null;
    }
  }

  /// Get product type by full path
  static ProductType? getProductTypeById(String categoryId, String subcategoryId, String productTypeId) {
    final subcategory = getSubcategoryById(categoryId, subcategoryId);
    if (subcategory == null) return null;
    try {
      return subcategory.productTypes.firstWhere((p) => p.id == productTypeId);
    } catch (_) {
      return null;
    }
  }
}


// ============ APPAREL & FASHION ============
final _apparel = Category(
  id: 'apparel',
  name: 'Apparel & Fashion',
  iconName: 'shirt',
  subcategories: [
    Subcategory(
      id: 'clothing',
      name: 'Clothing',
      productTypes: [
        ProductType(
          id: 'tshirts',
          name: 'T-Shirts & Tops',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: AttributeOptions.sizes, required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Nike, Adidas, H&M'),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: AttributeOptions.genders, required: true),
            ProductAttribute(name: 'sleeveLength', label: 'Sleeve Length', type: AttributeType.select, options: ['Sleeveless', 'Short Sleeve', 'Long Sleeve', '3/4 Sleeve'], required: true),
            ProductAttribute(name: 'neckline', label: 'Neckline', type: AttributeType.select, options: ['Crew Neck', 'V-Neck', 'Polo', 'Henley', 'Scoop']),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.multiSelect, options: AttributeOptions.clothingMaterials),
            ProductAttribute(name: 'fit', label: 'Fit', type: AttributeType.select, options: ['Slim', 'Regular', 'Oversized', 'Relaxed']),
          ],
        ),
        ProductType(
          id: 'jeans_pants',
          name: 'Jeans & Pants',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'waistSize', label: 'Waist Size', type: AttributeType.select, options: ['26', '28', '30', '32', '34', '36', '38', '40', '42'], required: true),
            ProductAttribute(name: 'length', label: 'Length (inches)', type: AttributeType.select, options: ['28', '30', '32', '34', '36'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Blue', 'Black', 'Gray', 'White', 'Khaki', 'Navy'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: "e.g., Levi's, Wrangler"),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: AttributeOptions.genders, required: true),
            ProductAttribute(name: 'fit', label: 'Fit', type: AttributeType.select, options: ['Skinny', 'Slim', 'Straight', 'Bootcut', 'Relaxed', 'Wide Leg'], required: true),
            ProductAttribute(name: 'rise', label: 'Rise', type: AttributeType.select, options: ['Low Rise', 'Mid Rise', 'High Rise']),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Denim', 'Chino', 'Corduroy', 'Linen']),
          ],
        ),
        ProductType(
          id: 'dresses',
          name: 'Dresses',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: AttributeOptions.sizes, required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'length', label: 'Length', type: AttributeType.select, options: ['Mini', 'Midi', 'Maxi', 'Knee-Length'], required: true),
            ProductAttribute(name: 'style', label: 'Style', type: AttributeType.select, options: ['Casual', 'Formal', 'Cocktail', 'Evening', 'Bodycon', 'A-Line', 'Wrap'], required: true),
            ProductAttribute(name: 'occasion', label: 'Occasion', type: AttributeType.select, options: ['Everyday', 'Work', 'Party', 'Wedding', 'Beach']),
            ProductAttribute(name: 'sleeveType', label: 'Sleeve Type', type: AttributeType.select, options: ['Sleeveless', 'Short', 'Long', 'Off-Shoulder', 'Spaghetti Strap']),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Cotton', 'Silk', 'Chiffon', 'Satin', 'Polyester']),
          ],
        ),
        ProductType(
          id: 'activewear',
          name: 'Activewear & Sportswear',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: AttributeOptions.sizes, required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Nike, Adidas, Lululemon'),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: AttributeOptions.genders, required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Leggings', 'Sports Bra', 'Tank Top', 'Shorts', 'Track Pants', 'Hoodie'], required: true),
            ProductAttribute(name: 'sport', label: 'Sport', type: AttributeType.select, options: ['Running', 'Yoga', 'Gym', 'Football', 'Basketball', 'Tennis', 'General']),
          ],
        ),
        ProductType(
          id: 'outerwear',
          name: 'Outerwear (Jackets & Coats)',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: AttributeOptions.sizes, required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Black', 'Navy', 'Brown', 'Olive', 'Beige', 'Gray'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: AttributeOptions.genders, required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Bomber', 'Denim Jacket', 'Leather Jacket', 'Parka', 'Trench Coat', 'Puffer', 'Windbreaker'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Leather', 'Denim', 'Nylon', 'Polyester', 'Wool', 'Down']),
            ProductAttribute(name: 'weather', label: 'Weather', type: AttributeType.select, options: ['Waterproof', 'Water-Resistant', 'Insulated', 'Lightweight']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'shoes',
      name: 'Shoes',
      productTypes: [
        ProductType(
          id: 'sneakers',
          name: 'Sneakers',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'sizeUS', label: 'Size (US)', type: AttributeType.select, options: AttributeOptions.shoeSizesUS, required: true),
            ProductAttribute(name: 'sizeEU', label: 'Size (EU)', type: AttributeType.select, options: AttributeOptions.shoeSizesEU),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Nike, Adidas, Jordan'),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: AttributeOptions.genders, required: true),
            ProductAttribute(name: 'style', label: 'Style', type: AttributeType.select, options: ['Low-Top', 'Mid-Top', 'High-Top'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Running', 'Basketball', 'Casual', 'Skateboarding', 'Training']),
            ProductAttribute(name: 'width', label: 'Width', type: AttributeType.select, options: ['Narrow', 'Standard', 'Wide']),
          ],
        ),
        ProductType(
          id: 'boots',
          name: 'Boots',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'sizeUS', label: 'Size (US)', type: AttributeType.select, options: AttributeOptions.shoeSizesUS, required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Black', 'Brown', 'Tan', 'Gray', 'Burgundy'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Men', 'Women', 'Unisex'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Ankle Boots', 'Chelsea', 'Combat', 'Hiking', 'Work Boots', 'Cowboy', 'Knee-High'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Leather', 'Suede', 'Synthetic', 'Rubber'], required: true),
            ProductAttribute(name: 'heelHeight', label: 'Heel Height', type: AttributeType.select, options: ['Flat', 'Low (1-2")', 'Medium (2-3")', 'High (3"+)']),
          ],
        ),
        ProductType(
          id: 'sandals',
          name: 'Sandals & Flip-Flops',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'sizeUS', label: 'Size (US)', type: AttributeType.select, options: AttributeOptions.shoeSizesUS, required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: AttributeOptions.genders, required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Flip-Flops', 'Slides', 'Gladiator', 'Sport Sandals', 'Wedge'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Leather', 'Rubber', 'Synthetic', 'Cork']),
          ],
        ),
        ProductType(
          id: 'formal_shoes',
          name: 'Formal Shoes',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'sizeUS', label: 'Size (US)', type: AttributeType.select, options: AttributeOptions.shoeSizesUS, required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Black', 'Brown', 'Tan', 'Burgundy', 'Navy'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Men', 'Women'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Oxford', 'Derby', 'Loafer', 'Monk Strap', 'Brogue', 'Pump', 'Stiletto'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Leather', 'Patent Leather', 'Suede'], required: true),
          ],
        ),
        ProductType(
          id: 'heels',
          name: 'Heels',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'sizeUS', label: 'Size (US)', type: AttributeType.select, options: ['4', '4.5', '5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11', '11.5', '12'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'heelHeight', label: 'Heel Height', type: AttributeType.select, options: ['Kitten (1-2")', 'Low (2-3")', 'Medium (3-4")', 'High (4"+)'], required: true),
            ProductAttribute(name: 'heelType', label: 'Heel Type', type: AttributeType.select, options: ['Stiletto', 'Block', 'Wedge', 'Cone', 'Platform'], required: true),
            ProductAttribute(name: 'style', label: 'Style', type: AttributeType.select, options: ['Pump', 'Sandal', 'Mule', 'Slingback', 'Ankle Strap'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Leather', 'Suede', 'Satin', 'Patent', 'Synthetic']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'jewelry',
      name: 'Jewelry & Accessories',
      productTypes: [
        ProductType(
          id: 'watches',
          name: 'Watches',
          allowedConditions: ['New', 'Used', 'Refurbished', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Rolex, Seiko, Apple'),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Analog', 'Digital', 'Smart Watch', 'Chronograph', 'Dive Watch'], required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Men', 'Women', 'Unisex'], required: true),
            ProductAttribute(name: 'caseMaterial', label: 'Case Material', type: AttributeType.select, options: ['Stainless Steel', 'Gold', 'Titanium', 'Ceramic', 'Plastic'], required: true),
            ProductAttribute(name: 'bandMaterial', label: 'Band Material', type: AttributeType.select, options: ['Leather', 'Metal', 'Rubber', 'Silicone', 'Nylon'], required: true),
            ProductAttribute(name: 'caseSize', label: 'Case Size', type: AttributeType.select, options: ['Under 36mm', '36-40mm', '40-44mm', '44mm+']),
            ProductAttribute(name: 'movement', label: 'Movement', type: AttributeType.select, options: ['Automatic', 'Quartz', 'Mechanical', 'Solar']),
            ProductAttribute(name: 'waterResistance', label: 'Water Resistance', type: AttributeType.select, options: ['None', '30m', '50m', '100m', '200m+']),
          ],
        ),
        ProductType(
          id: 'rings',
          name: 'Rings',
          allowedConditions: ['New', 'Used', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'ringSize', label: 'Ring Size', type: AttributeType.select, options: ['4', '4.5', '5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11', '12', '13'], required: true),
            ProductAttribute(name: 'metal', label: 'Metal', type: AttributeType.select, options: ['Gold (10K)', 'Gold (14K)', 'Gold (18K)', 'White Gold', 'Rose Gold', 'Platinum', 'Sterling Silver', 'Stainless Steel', 'Titanium'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Engagement', 'Wedding Band', 'Fashion', 'Signet', 'Stackable', 'Statement'], required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Men', 'Women', 'Unisex'], required: true),
            ProductAttribute(name: 'gemstone', label: 'Gemstone', type: AttributeType.select, options: ['Diamond', 'Ruby', 'Sapphire', 'Emerald', 'Pearl', 'Cubic Zirconia', 'None']),
            ProductAttribute(name: 'caratWeight', label: 'Carat Weight', type: AttributeType.text, hint: 'e.g., 0.5, 1.0'),
          ],
        ),
        ProductType(
          id: 'necklaces',
          name: 'Necklaces & Pendants',
          allowedConditions: ['New', 'Used', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'metal', label: 'Metal', type: AttributeType.select, options: ['Gold', 'White Gold', 'Rose Gold', 'Sterling Silver', 'Platinum', 'Stainless Steel'], required: true),
            ProductAttribute(name: 'length', label: 'Length', type: AttributeType.select, options: ['Choker (14-16")', 'Princess (17-19")', 'Matinee (20-24")', 'Opera (28-36")', 'Rope (36"+)'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Chain', 'Pendant', 'Locket', 'Choker', 'Statement', 'Layered'], required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Men', 'Women', 'Unisex'], required: true),
            ProductAttribute(name: 'gemstone', label: 'Gemstone', type: AttributeType.select, options: ['Diamond', 'Pearl', 'Sapphire', 'Ruby', 'None']),
          ],
        ),
        ProductType(
          id: 'earrings',
          name: 'Earrings',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'metal', label: 'Metal', type: AttributeType.select, options: ['Gold', 'White Gold', 'Rose Gold', 'Sterling Silver', 'Platinum'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Stud', 'Hoop', 'Drop', 'Dangle', 'Huggie', 'Chandelier', 'Ear Cuff'], required: true),
            ProductAttribute(name: 'gemstone', label: 'Gemstone', type: AttributeType.select, options: ['Diamond', 'Pearl', 'Sapphire', 'Ruby', 'Cubic Zirconia', 'None']),
            ProductAttribute(name: 'closure', label: 'Closure', type: AttributeType.select, options: ['Push Back', 'Screw Back', 'Lever Back', 'Hook', 'Clip-On']),
          ],
        ),
        ProductType(
          id: 'bracelets',
          name: 'Bracelets',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'metal', label: 'Metal', type: AttributeType.select, options: ['Gold', 'White Gold', 'Rose Gold', 'Sterling Silver', 'Leather', 'Beaded'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Bangle', 'Cuff', 'Chain', 'Tennis', 'Charm', 'Wrap'], required: true),
            ProductAttribute(name: 'length', label: 'Length', type: AttributeType.select, options: ['6"', '6.5"', '7"', '7.5"', '8"', 'Adjustable'], required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Men', 'Women', 'Unisex'], required: true),
          ],
        ),
      ],
    ),
  ],
);


// ============ ELECTRONICS & TECHNOLOGY ============
final _electronics = Category(
  id: 'electronics',
  name: 'Electronics & Technology',
  iconName: 'mobile',
  subcategories: [
    Subcategory(
      id: 'cell_phones',
      name: 'Cell Phones',
      productTypes: [
        ProductType(
          id: 'smartphones',
          name: 'Smartphones',
          allowedConditions: ['New', 'Used', 'Refurbished'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Apple', 'Samsung', 'Google', 'OnePlus', 'Xiaomi', 'Huawei', 'Oppo', 'Vivo', 'Motorola', 'Nokia'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true, hint: 'e.g., iPhone 15 Pro Max'),
            ProductAttribute(name: 'storage', label: 'Storage', type: AttributeType.select, options: AttributeOptions.phoneStorage, required: true),
            ProductAttribute(name: 'ram', label: 'RAM', type: AttributeType.select, options: AttributeOptions.phoneRam),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Black', 'White', 'Silver', 'Gold', 'Blue', 'Green', 'Purple', 'Red'], required: true),
            ProductAttribute(name: 'carrierLock', label: 'Carrier Lock', type: AttributeType.select, options: AttributeOptions.carrierLock, required: true),
            ProductAttribute(name: 'screenSize', label: 'Screen Size', type: AttributeType.select, options: AttributeOptions.screenSizes),
            ProductAttribute(name: 'batteryHealth', label: 'Battery Health', type: AttributeType.select, options: AttributeOptions.batteryHealth),
            ProductAttribute(name: 'includes', label: 'Includes', type: AttributeType.multiSelect, options: ['Original Box', 'Charger', 'Cable', 'Earphones', 'Case']),
          ],
        ),
        ProductType(
          id: 'feature_phones',
          name: 'Feature Phones',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Nokia', 'Samsung', 'Tecno', 'Itel', 'Infinix'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true),
            ProductAttribute(name: 'simType', label: 'SIM Type', type: AttributeType.select, options: ['Single SIM', 'Dual SIM'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Black', 'Blue', 'Red', 'Gold'], required: true),
            ProductAttribute(name: 'batteryCapacity', label: 'Battery Capacity (mAh)', type: AttributeType.text),
          ],
        ),
        ProductType(
          id: 'phone_accessories',
          name: 'Phone Accessories',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Case', 'Screen Protector', 'Charger', 'Cable', 'Earphones', 'Power Bank', 'Car Mount', 'Wireless Charger'], required: true),
            ProductAttribute(name: 'compatibleBrand', label: 'Compatible Brand', type: AttributeType.select, options: ['Apple', 'Samsung', 'Universal', 'Google', 'OnePlus', 'Xiaomi'], required: true),
            ProductAttribute(name: 'compatibleModel', label: 'Compatible Model', type: AttributeType.text, hint: 'e.g., iPhone 15, Galaxy S24'),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Silicone', 'Leather', 'Plastic', 'Tempered Glass', 'TPU']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'computers',
      name: 'Computers',
      productTypes: [
        ProductType(
          id: 'laptops',
          name: 'Laptops',
          allowedConditions: ['New', 'Used', 'Refurbished'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Apple', 'Dell', 'HP', 'Lenovo', 'Asus', 'Acer', 'Microsoft', 'MSI', 'Razer'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true, hint: 'e.g., MacBook Pro 14"'),
            ProductAttribute(name: 'processorBrand', label: 'Processor Brand', type: AttributeType.select, options: ['Intel', 'AMD', 'Apple Silicon'], required: true),
            ProductAttribute(name: 'processorModel', label: 'Processor Model', type: AttributeType.select, options: ['i3', 'i5', 'i7', 'i9', 'Ryzen 3', 'Ryzen 5', 'Ryzen 7', 'Ryzen 9', 'M1', 'M2', 'M3', 'M3 Pro', 'M3 Max'], required: true),
            ProductAttribute(name: 'ram', label: 'RAM', type: AttributeType.select, options: AttributeOptions.laptopRam, required: true),
            ProductAttribute(name: 'storageType', label: 'Storage Type', type: AttributeType.select, options: ['SSD', 'HDD', 'SSD + HDD'], required: true),
            ProductAttribute(name: 'storageSize', label: 'Storage Size', type: AttributeType.select, options: AttributeOptions.storageSize, required: true),
            ProductAttribute(name: 'screenSize', label: 'Screen Size', type: AttributeType.select, options: ['11"', '13"', '14"', '15"', '16"', '17"'], required: true),
            ProductAttribute(name: 'screenResolution', label: 'Screen Resolution', type: AttributeType.select, options: ['HD (1366x768)', 'FHD (1920x1080)', '2K', '4K', 'Retina']),
            ProductAttribute(name: 'gpu', label: 'GPU', type: AttributeType.select, options: ['Integrated', 'NVIDIA GTX', 'NVIDIA RTX', 'AMD Radeon']),
            ProductAttribute(name: 'os', label: 'Operating System', type: AttributeType.select, options: ['Windows 11', 'Windows 10', 'macOS', 'Chrome OS', 'Linux']),
            ProductAttribute(name: 'batteryHealth', label: 'Battery Health', type: AttributeType.select, options: ['Excellent', 'Good', 'Fair']),
          ],
        ),
        ProductType(
          id: 'desktops',
          name: 'Desktop Computers',
          allowedConditions: ['New', 'Used', 'Refurbished'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Apple', 'Dell', 'HP', 'Lenovo', 'Custom Built'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Tower', 'All-in-One', 'Mini PC', 'Workstation'], required: true),
            ProductAttribute(name: 'processorBrand', label: 'Processor Brand', type: AttributeType.select, options: ['Intel', 'AMD', 'Apple Silicon'], required: true),
            ProductAttribute(name: 'processorModel', label: 'Processor Model', type: AttributeType.select, options: ['i3', 'i5', 'i7', 'i9', 'Ryzen 3', 'Ryzen 5', 'Ryzen 7', 'Ryzen 9', 'M1', 'M2'], required: true),
            ProductAttribute(name: 'ram', label: 'RAM', type: AttributeType.select, options: AttributeOptions.laptopRam, required: true),
            ProductAttribute(name: 'storageType', label: 'Storage Type', type: AttributeType.select, options: ['SSD', 'HDD', 'SSD + HDD'], required: true),
            ProductAttribute(name: 'storageSize', label: 'Storage Size', type: AttributeType.select, options: ['256GB', '512GB', '1TB', '2TB', '4TB+'], required: true),
            ProductAttribute(name: 'gpu', label: 'GPU', type: AttributeType.select, options: ['Integrated', 'NVIDIA GTX', 'NVIDIA RTX', 'AMD Radeon']),
            ProductAttribute(name: 'includesMonitor', label: 'Includes Monitor', type: AttributeType.boolean),
          ],
        ),
        ProductType(
          id: 'tablets',
          name: 'Tablets',
          allowedConditions: ['New', 'Used', 'Refurbished'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Apple', 'Samsung', 'Microsoft', 'Lenovo', 'Amazon', 'Huawei'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true, hint: 'e.g., iPad Pro 12.9"'),
            ProductAttribute(name: 'storage', label: 'Storage', type: AttributeType.select, options: ['32GB', '64GB', '128GB', '256GB', '512GB', '1TB'], required: true),
            ProductAttribute(name: 'screenSize', label: 'Screen Size', type: AttributeType.select, options: ['7-8"', '9-10"', '11-12"', '12"+'], required: true),
            ProductAttribute(name: 'connectivity', label: 'Connectivity', type: AttributeType.select, options: ['WiFi Only', 'WiFi + Cellular'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Space Gray', 'Silver', 'Gold', 'Black'], required: true),
            ProductAttribute(name: 'includes', label: 'Includes', type: AttributeType.multiSelect, options: ['Stylus/Pencil', 'Keyboard', 'Case', 'Original Box']),
          ],
        ),
        ProductType(
          id: 'computer_accessories',
          name: 'Computer Accessories',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Monitor', 'Keyboard', 'Mouse', 'Webcam', 'Headset', 'Docking Station', 'External Drive', 'USB Hub'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Logitech, Razer'),
            ProductAttribute(name: 'connectivity', label: 'Connectivity', type: AttributeType.multiSelect, options: ['USB', 'USB-C', 'Bluetooth', 'Wireless', 'HDMI'], required: true),
            ProductAttribute(name: 'compatibleWith', label: 'Compatible With', type: AttributeType.multiSelect, options: ['Windows', 'Mac', 'Linux']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'tvs_entertainment',
      name: 'TVs & Home Entertainment',
      productTypes: [
        ProductType(
          id: 'televisions',
          name: 'Televisions',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Samsung', 'LG', 'Sony', 'TCL', 'Hisense', 'Vizio'], required: true),
            ProductAttribute(name: 'screenSize', label: 'Screen Size', type: AttributeType.select, options: ['32"', '40"', '43"', '50"', '55"', '65"', '75"', '85"+'], required: true),
            ProductAttribute(name: 'displayTechnology', label: 'Display Technology', type: AttributeType.select, options: ['LED', 'QLED', 'OLED', 'Mini-LED', 'LCD'], required: true),
            ProductAttribute(name: 'resolution', label: 'Resolution', type: AttributeType.select, options: ['HD (720p)', 'Full HD (1080p)', '4K UHD', '8K'], required: true),
            ProductAttribute(name: 'smartTV', label: 'Smart TV', type: AttributeType.boolean, required: true),
            ProductAttribute(name: 'smartPlatform', label: 'Smart Platform', type: AttributeType.select, options: ['Tizen', 'webOS', 'Google TV', 'Roku', 'Fire TV', 'Android TV']),
            ProductAttribute(name: 'refreshRate', label: 'Refresh Rate', type: AttributeType.select, options: ['60Hz', '120Hz', '144Hz']),
          ],
        ),
        ProductType(
          id: 'speakers',
          name: 'Speakers & Sound Systems',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Bose', 'Sonos', 'JBL', 'Sony', 'Samsung', 'LG', 'Harman Kardon'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Soundbar', 'Bookshelf', 'Tower', 'Portable Bluetooth', 'Smart Speaker', 'Subwoofer'], required: true),
            ProductAttribute(name: 'connectivity', label: 'Connectivity', type: AttributeType.multiSelect, options: ['Bluetooth', 'WiFi', 'AUX', 'Optical', 'HDMI ARC'], required: true),
            ProductAttribute(name: 'channels', label: 'Channels', type: AttributeType.select, options: ['2.0', '2.1', '3.1', '5.1', '7.1', 'Atmos']),
            ProductAttribute(name: 'voiceAssistant', label: 'Voice Assistant', type: AttributeType.select, options: ['Alexa', 'Google Assistant', 'Siri', 'None']),
          ],
        ),
        ProductType(
          id: 'headphones',
          name: 'Headphones & Earbuds',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Apple', 'Sony', 'Bose', 'Samsung', 'JBL', 'Beats', 'Sennheiser', 'Audio-Technica'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Over-Ear', 'On-Ear', 'In-Ear', 'True Wireless'], required: true),
            ProductAttribute(name: 'connectivity', label: 'Connectivity', type: AttributeType.select, options: ['Wired', 'Bluetooth', 'Both'], required: true),
            ProductAttribute(name: 'noiseCancellation', label: 'Noise Cancellation', type: AttributeType.select, options: ['Active (ANC)', 'Passive', 'None'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Black', 'White', 'Silver', 'Blue', 'Red'], required: true),
            ProductAttribute(name: 'batteryLife', label: 'Battery Life (hours)', type: AttributeType.text),
            ProductAttribute(name: 'microphone', label: 'Microphone', type: AttributeType.boolean),
          ],
        ),
        ProductType(
          id: 'gaming_consoles',
          name: 'Gaming Consoles',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Sony', 'Microsoft', 'Nintendo'], required: true),
            ProductAttribute(name: 'console', label: 'Console', type: AttributeType.select, options: ['PlayStation 5', 'PlayStation 5 Digital', 'PlayStation 4', 'PlayStation 4 Pro', 'Xbox Series X', 'Xbox Series S', 'Xbox One', 'Nintendo Switch', 'Nintendo Switch OLED', 'Nintendo Switch Lite'], required: true),
            ProductAttribute(name: 'storage', label: 'Storage', type: AttributeType.select, options: ['500GB', '825GB', '1TB', '2TB']),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['Black', 'White', 'Special Edition'], required: true),
            ProductAttribute(name: 'includes', label: 'Includes', type: AttributeType.multiSelect, options: ['Controller', 'Games', 'Original Box', 'HDMI Cable']),
            ProductAttribute(name: 'controllerCount', label: 'Controller Count', type: AttributeType.select, options: ['1', '2', '3', '4']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'cameras',
      name: 'Cameras & Photography',
      productTypes: [
        ProductType(
          id: 'dslr_cameras',
          name: 'DSLR Cameras',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Canon', 'Nikon', 'Sony', 'Pentax'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true, hint: 'e.g., Canon EOS 5D Mark IV'),
            ProductAttribute(name: 'sensorType', label: 'Sensor Type', type: AttributeType.select, options: ['Full Frame', 'APS-C', 'Micro 4/3'], required: true),
            ProductAttribute(name: 'megapixels', label: 'Megapixels', type: AttributeType.select, options: ['Under 20MP', '20-30MP', '30-45MP', '45MP+'], required: true),
            ProductAttribute(name: 'lensMount', label: 'Lens Mount', type: AttributeType.select, options: ['Canon EF', 'Canon RF', 'Nikon F', 'Nikon Z', 'Sony A', 'Sony E'], required: true),
            ProductAttribute(name: 'videoResolution', label: 'Video Resolution', type: AttributeType.select, options: ['1080p', '4K', '8K']),
            ProductAttribute(name: 'shutterCount', label: 'Shutter Count', type: AttributeType.text, hint: 'Approximate count'),
            ProductAttribute(name: 'includes', label: 'Includes', type: AttributeType.multiSelect, options: ['Body Only', 'Kit Lens', 'Battery', 'Charger', 'Bag', 'Memory Card']),
          ],
        ),
        ProductType(
          id: 'mirrorless_cameras',
          name: 'Mirrorless Cameras',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Sony', 'Canon', 'Nikon', 'Fujifilm', 'Panasonic', 'Olympus'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true, hint: 'e.g., Sony A7 IV'),
            ProductAttribute(name: 'sensorType', label: 'Sensor Type', type: AttributeType.select, options: ['Full Frame', 'APS-C', 'Micro 4/3'], required: true),
            ProductAttribute(name: 'megapixels', label: 'Megapixels', type: AttributeType.select, options: ['Under 20MP', '20-30MP', '30-45MP', '45MP+'], required: true),
            ProductAttribute(name: 'lensMount', label: 'Lens Mount', type: AttributeType.select, options: ['Sony E', 'Canon RF', 'Nikon Z', 'Fuji X', 'Micro 4/3'], required: true),
            ProductAttribute(name: 'videoResolution', label: 'Video Resolution', type: AttributeType.select, options: ['1080p', '4K', '6K', '8K']),
            ProductAttribute(name: 'ibis', label: 'IBIS (Stabilization)', type: AttributeType.boolean),
            ProductAttribute(name: 'includes', label: 'Includes', type: AttributeType.multiSelect, options: ['Body Only', 'Kit Lens', 'Battery', 'Charger']),
          ],
        ),
        ProductType(
          id: 'camera_lenses',
          name: 'Camera Lenses',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Canon', 'Nikon', 'Sony', 'Sigma', 'Tamron', 'Zeiss', 'Fujifilm'], required: true),
            ProductAttribute(name: 'mount', label: 'Mount', type: AttributeType.select, options: ['Canon EF', 'Canon RF', 'Nikon F', 'Nikon Z', 'Sony E', 'Sony A', 'Fuji X', 'Micro 4/3'], required: true),
            ProductAttribute(name: 'focalLength', label: 'Focal Length', type: AttributeType.text, required: true, hint: 'e.g., 24mm, 24-70mm'),
            ProductAttribute(name: 'aperture', label: 'Aperture', type: AttributeType.text, required: true, hint: 'e.g., f/1.4, f/2.8'),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Prime', 'Zoom', 'Macro', 'Telephoto', 'Wide Angle', 'Fisheye'], required: true),
            ProductAttribute(name: 'imageStabilization', label: 'Image Stabilization', type: AttributeType.boolean),
            ProductAttribute(name: 'autofocus', label: 'Autofocus', type: AttributeType.boolean),
          ],
        ),
        ProductType(
          id: 'action_cameras_drones',
          name: 'Action Cameras & Drones',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['GoPro', 'DJI', 'Insta360', 'Sony'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true, hint: 'e.g., GoPro Hero 12'),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Action Camera', 'Drone', '360 Camera'], required: true),
            ProductAttribute(name: 'videoResolution', label: 'Video Resolution', type: AttributeType.select, options: ['1080p', '4K', '5.3K', '8K'], required: true),
            ProductAttribute(name: 'waterproof', label: 'Waterproof', type: AttributeType.boolean),
            ProductAttribute(name: 'flightTime', label: 'Flight Time (minutes)', type: AttributeType.text, hint: 'For drones only'),
            ProductAttribute(name: 'includes', label: 'Includes', type: AttributeType.multiSelect, options: ['Batteries', 'Memory Card', 'Case', 'Mounts', 'Controller']),
          ],
        ),
      ],
    ),
  ],
);


// ============ AUTOMOTIVE ============
final _automotive = Category(
  id: 'automotive',
  name: 'Automotive',
  iconName: 'car',
  subcategories: [
    Subcategory(
      id: 'vehicles',
      name: 'Vehicles',
      productTypes: [
        ProductType(
          id: 'cars',
          name: 'Cars',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'make', label: 'Make', type: AttributeType.select, options: ['Toyota', 'Honda', 'Nissan', 'BMW', 'Mercedes-Benz', 'Audi', 'Volkswagen', 'Ford', 'Mazda', 'Subaru', 'Hyundai', 'Kia', 'Mitsubishi', 'Suzuki', 'Land Rover', 'Jeep', 'Porsche', 'Lexus'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true, hint: 'e.g., Corolla, Civic'),
            ProductAttribute(name: 'year', label: 'Year', type: AttributeType.text, required: true, hint: 'e.g., 2022'),
            ProductAttribute(name: 'mileage', label: 'Mileage (km)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'fuelType', label: 'Fuel Type', type: AttributeType.select, options: ['Petrol', 'Diesel', 'Hybrid', 'Plug-in Hybrid', 'Electric'], required: true),
            ProductAttribute(name: 'transmission', label: 'Transmission', type: AttributeType.select, options: ['Automatic', 'Manual', 'CVT', 'DCT'], required: true),
            ProductAttribute(name: 'bodyType', label: 'Body Type', type: AttributeType.select, options: ['Sedan', 'SUV', 'Hatchback', 'Coupe', 'Convertible', 'Wagon', 'Pickup', 'Van', 'Crossover'], required: true),
            ProductAttribute(name: 'engineSize', label: 'Engine Size', type: AttributeType.text, required: true, hint: 'e.g., 1.8L, 2.0L'),
            ProductAttribute(name: 'driveType', label: 'Drive Type', type: AttributeType.select, options: ['FWD', 'RWD', 'AWD', '4WD']),
            ProductAttribute(name: 'exteriorColor', label: 'Exterior Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'interiorColor', label: 'Interior Color', type: AttributeType.select, options: ['Black', 'Beige', 'Brown', 'Gray', 'Red']),
            ProductAttribute(name: 'seats', label: 'Seats', type: AttributeType.select, options: ['2', '4', '5', '7', '8+']),
            ProductAttribute(name: 'vehicleCondition', label: 'Condition', type: AttributeType.select, options: ['Excellent', 'Very Good', 'Good', 'Fair'], required: true),
            ProductAttribute(name: 'serviceHistory', label: 'Service History', type: AttributeType.select, options: ['Full', 'Partial', 'None']),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Sunroof', 'Leather Seats', 'Navigation', 'Backup Camera', 'Bluetooth', 'Heated Seats', 'Cruise Control', 'Parking Sensors']),
            ProductAttribute(name: 'registration', label: 'Registration', type: AttributeType.select, options: ['Kenyan', 'Foreign (Duty Paid)', 'Foreign (Duty Not Paid)'], required: true),
          ],
        ),
        ProductType(
          id: 'motorcycles',
          name: 'Motorcycles',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'make', label: 'Make', type: AttributeType.select, options: ['Honda', 'Yamaha', 'Kawasaki', 'Suzuki', 'BMW', 'Harley-Davidson', 'KTM', 'Ducati', 'Bajaj', 'TVS'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true),
            ProductAttribute(name: 'year', label: 'Year', type: AttributeType.text, required: true),
            ProductAttribute(name: 'mileage', label: 'Mileage (km)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'engineSize', label: 'Engine Size (cc)', type: AttributeType.text, required: true, hint: 'e.g., 150, 650, 1000'),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Sport', 'Cruiser', 'Touring', 'Adventure', 'Naked', 'Scooter', 'Dirt Bike', 'Cafe Racer'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'vehicleCondition', label: 'Condition', type: AttributeType.select, options: ['Excellent', 'Very Good', 'Good', 'Fair'], required: true),
          ],
        ),
        ProductType(
          id: 'trucks_commercial',
          name: 'Trucks & Commercial',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'make', label: 'Make', type: AttributeType.select, options: ['Toyota', 'Isuzu', 'Mitsubishi', 'Hino', 'Mercedes-Benz', 'MAN', 'Scania', 'Volvo'], required: true),
            ProductAttribute(name: 'model', label: 'Model', type: AttributeType.text, required: true),
            ProductAttribute(name: 'year', label: 'Year', type: AttributeType.text, required: true),
            ProductAttribute(name: 'mileage', label: 'Mileage (km)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Pickup', 'Light Truck', 'Medium Truck', 'Heavy Truck', 'Trailer', 'Bus'], required: true),
            ProductAttribute(name: 'payloadCapacity', label: 'Payload Capacity (tons)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'fuelType', label: 'Fuel Type', type: AttributeType.select, options: ['Diesel', 'Petrol'], required: true),
            ProductAttribute(name: 'transmission', label: 'Transmission', type: AttributeType.select, options: ['Manual', 'Automatic'], required: true),
            ProductAttribute(name: 'vehicleCondition', label: 'Condition', type: AttributeType.select, options: ['Excellent', 'Very Good', 'Good', 'Fair'], required: true),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'auto_parts',
      name: 'Auto Parts & Accessories',
      productTypes: [
        ProductType(
          id: 'engine_parts',
          name: 'Engine Parts',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'partType', label: 'Part Type', type: AttributeType.select, options: ['Air Filter', 'Oil Filter', 'Spark Plugs', 'Timing Belt', 'Water Pump', 'Alternator', 'Starter Motor', 'Fuel Pump', 'Radiator', 'Turbocharger'], required: true),
            ProductAttribute(name: 'compatibleMakes', label: 'Compatible Makes', type: AttributeType.multiSelect, options: ['Toyota', 'Honda', 'Nissan', 'BMW', 'Mercedes-Benz', 'Volkswagen', 'Ford', 'Universal'], required: true),
            ProductAttribute(name: 'compatibleModels', label: 'Compatible Models', type: AttributeType.text, hint: 'e.g., Corolla, Civic'),
            ProductAttribute(name: 'compatibleYears', label: 'Compatible Years', type: AttributeType.text, required: true, hint: 'e.g., 2015-2020'),
            ProductAttribute(name: 'oemAftermarket', label: 'OEM/Aftermarket', type: AttributeType.select, options: ['OEM (Original)', 'Aftermarket', 'Refurbished'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text),
            ProductAttribute(name: 'partNumber', label: 'Part Number', type: AttributeType.text),
          ],
        ),
        ProductType(
          id: 'tires_wheels',
          name: 'Tires & Wheels',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Tire', 'Wheel/Rim', 'Tire + Wheel Set'], required: true),
            ProductAttribute(name: 'tireSize', label: 'Tire Size', type: AttributeType.text, required: true, hint: 'e.g., 205/55R16'),
            ProductAttribute(name: 'wheelSize', label: 'Wheel Size', type: AttributeType.select, options: ['14"', '15"', '16"', '17"', '18"', '19"', '20"', '21"', '22"']),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Michelin, Bridgestone'),
            ProductAttribute(name: 'season', label: 'Season', type: AttributeType.select, options: ['All-Season', 'Summer', 'Winter', 'All-Terrain']),
            ProductAttribute(name: 'treadDepth', label: 'Tread Depth', type: AttributeType.select, options: ['New', '80%+', '60-80%', '40-60%', 'Below 40%']),
            ProductAttribute(name: 'quantity', label: 'Quantity', type: AttributeType.select, options: ['1', '2', '4'], required: true),
          ],
        ),
        ProductType(
          id: 'car_electronics',
          name: 'Car Electronics',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Head Unit', 'Speakers', 'Amplifier', 'Subwoofer', 'Dash Cam', 'GPS Navigator', 'Reverse Camera', 'Car Alarm'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Pioneer, Sony, JBL'),
            ProductAttribute(name: 'screenSize', label: 'Screen Size', type: AttributeType.select, options: ['7"', '9"', '10"']),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Bluetooth', 'Apple CarPlay', 'Android Auto', 'GPS', 'USB', 'AUX']),
          ],
        ),
      ],
    ),
  ],
);


// ============ HOME & LIVING ============
final _homeLiving = Category(
  id: 'home',
  name: 'Home & Living',
  iconName: 'home_2',
  subcategories: [
    Subcategory(
      id: 'furniture',
      name: 'Furniture',
      productTypes: [
        ProductType(
          id: 'sofas',
          name: 'Sofas & Couches',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['2-Seater', '3-Seater', 'L-Shaped', 'Sectional', 'Sofa Bed', 'Recliner', 'Loveseat'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Leather', 'Fabric', 'Velvet', 'Microfiber', 'Faux Leather'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'seatingCapacity', label: 'Seating Capacity', type: AttributeType.select, options: ['2', '3', '4', '5', '6+'], required: true),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Reclining', 'Storage', 'Convertible', 'USB Ports']),
            ProductAttribute(name: 'assembly', label: 'Assembly', type: AttributeType.select, options: ['Assembled', 'Requires Assembly'], required: true),
          ],
        ),
        ProductType(
          id: 'beds_mattresses',
          name: 'Beds & Mattresses',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Bed Frame', 'Mattress', 'Bed + Mattress Set', 'Bunk Bed', 'Sofa Bed'], required: true),
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['Single (3x6)', 'Double (4x6)', 'Queen (5x6)', 'King (6x6)', 'Super King (6x7)'], required: true),
            ProductAttribute(name: 'frameMaterial', label: 'Frame Material', type: AttributeType.select, options: ['Wood', 'Metal', 'Upholstered', 'Leather']),
            ProductAttribute(name: 'mattressType', label: 'Mattress Type', type: AttributeType.select, options: ['Spring', 'Memory Foam', 'Latex', 'Hybrid', 'Orthopedic']),
            ProductAttribute(name: 'firmness', label: 'Firmness', type: AttributeType.select, options: ['Soft', 'Medium', 'Firm', 'Extra Firm']),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Storage Drawers', 'Headboard', 'Footboard', 'Adjustable']),
            ProductAttribute(name: 'assembly', label: 'Assembly', type: AttributeType.select, options: ['Assembled', 'Requires Assembly'], required: true),
          ],
        ),
        ProductType(
          id: 'tables',
          name: 'Tables',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Dining Table', 'Coffee Table', 'Side Table', 'Console Table', 'Desk', 'Outdoor Table'], required: true),
            ProductAttribute(name: 'shape', label: 'Shape', type: AttributeType.select, options: ['Rectangle', 'Round', 'Square', 'Oval'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Wood', 'Glass', 'Metal', 'Marble', 'MDF'], required: true),
            ProductAttribute(name: 'seatingCapacity', label: 'Seating Capacity', type: AttributeType.select, options: ['2', '4', '6', '8', '10+']),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'extendable', label: 'Extendable', type: AttributeType.boolean),
            ProductAttribute(name: 'assembly', label: 'Assembly', type: AttributeType.select, options: ['Assembled', 'Requires Assembly'], required: true),
          ],
        ),
        ProductType(
          id: 'chairs',
          name: 'Chairs',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Dining Chair', 'Office Chair', 'Accent Chair', 'Bar Stool', 'Recliner', 'Gaming Chair', 'Outdoor Chair'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Wood', 'Metal', 'Plastic', 'Fabric', 'Leather', 'Mesh'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'quantity', label: 'Quantity', type: AttributeType.select, options: ['1', '2', '4', '6', '8'], required: true),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Armrests', 'Swivel', 'Adjustable Height', 'Wheels', 'Lumbar Support']),
            ProductAttribute(name: 'assembly', label: 'Assembly', type: AttributeType.select, options: ['Assembled', 'Requires Assembly'], required: true),
          ],
        ),
        ProductType(
          id: 'storage',
          name: 'Storage & Organization',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Wardrobe', 'Dresser', 'Bookshelf', 'TV Stand', 'Cabinet', 'Shoe Rack', 'Storage Box'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Wood', 'Metal', 'Plastic', 'MDF', 'Fabric'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'shelvesDrawers', label: 'Number of Shelves/Drawers', type: AttributeType.text),
            ProductAttribute(name: 'assembly', label: 'Assembly', type: AttributeType.select, options: ['Assembled', 'Requires Assembly'], required: true),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'appliances',
      name: 'Home Appliances',
      productTypes: [
        ProductType(
          id: 'kitchen_appliances',
          name: 'Kitchen Appliances',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Refrigerator', 'Microwave', 'Blender', 'Toaster', 'Coffee Maker', 'Air Fryer', 'Electric Kettle', 'Food Processor', 'Mixer', 'Rice Cooker', 'Pressure Cooker'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Samsung, LG, Philips'),
            ProductAttribute(name: 'capacity', label: 'Capacity', type: AttributeType.text, hint: 'Liters, Cups, etc.'),
            ProductAttribute(name: 'power', label: 'Power (Watts)', type: AttributeType.text),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['White', 'Black', 'Silver', 'Stainless Steel', 'Red'], required: true),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Digital Display', 'Timer', 'Multiple Speeds', 'Dishwasher Safe']),
            ProductAttribute(name: 'warranty', label: 'Warranty', type: AttributeType.select, options: ['None', '6 Months', '1 Year', '2 Years']),
          ],
        ),
        ProductType(
          id: 'major_appliances',
          name: 'Major Appliances',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Refrigerator', 'Washing Machine', 'Dryer', 'Dishwasher', 'Oven/Range', 'Air Conditioner', 'Water Heater'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.select, options: ['Samsung', 'LG', 'Whirlpool', 'Bosch', 'Miele', 'Haier', 'Hisense'], required: true),
            ProductAttribute(name: 'capacity', label: 'Capacity', type: AttributeType.text, required: true, hint: 'Liters, kg, BTU'),
            ProductAttribute(name: 'energyRating', label: 'Energy Rating', type: AttributeType.select, options: ['A+++', 'A++', 'A+', 'A', 'B', 'C', 'D']),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: ['White', 'Black', 'Silver', 'Stainless Steel'], required: true),
            ProductAttribute(name: 'specificType', label: 'Specific Type', type: AttributeType.select, options: ['Top Load', 'Front Load', 'Side-by-Side', 'French Door', 'Split', 'Window'], required: true),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Inverter', 'Smart/WiFi', 'Ice Maker', 'Steam', 'Quick Wash']),
            ProductAttribute(name: 'warranty', label: 'Warranty', type: AttributeType.select, options: ['None', '1 Year', '2 Years', '5 Years']),
          ],
        ),
        ProductType(
          id: 'cleaning_appliances',
          name: 'Cleaning Appliances',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Vacuum Cleaner', 'Robot Vacuum', 'Steam Mop', 'Carpet Cleaner', 'Pressure Washer'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Dyson, iRobot, Shark'),
            ProductAttribute(name: 'powerSource', label: 'Power Source', type: AttributeType.select, options: ['Corded', 'Cordless', 'Battery'], required: true),
            ProductAttribute(name: 'bagType', label: 'Bag Type', type: AttributeType.select, options: ['Bagless', 'Bagged']),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['HEPA Filter', 'Wet/Dry', 'Self-Emptying', 'App Control']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'home_decor',
      name: 'Home Decor',
      productTypes: [
        ProductType(
          id: 'lighting',
          name: 'Lighting',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Ceiling Light', 'Pendant', 'Chandelier', 'Floor Lamp', 'Table Lamp', 'Wall Sconce', 'LED Strip'], required: true),
            ProductAttribute(name: 'style', label: 'Style', type: AttributeType.select, options: ['Modern', 'Traditional', 'Industrial', 'Minimalist', 'Bohemian'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Metal', 'Glass', 'Fabric', 'Wood', 'Crystal'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'bulbType', label: 'Bulb Type', type: AttributeType.select, options: ['LED', 'Incandescent', 'Halogen', 'Smart Bulb']),
            ProductAttribute(name: 'dimmable', label: 'Dimmable', type: AttributeType.boolean),
          ],
        ),
        ProductType(
          id: 'rugs_carpets',
          name: 'Rugs & Carpets',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Area Rug', 'Runner', 'Round Rug', 'Outdoor Rug', 'Doormat'], required: true),
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['2x3ft', '3x5ft', '4x6ft', '5x7ft', '6x9ft', '8x10ft', '9x12ft', 'Custom'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Wool', 'Cotton', 'Synthetic', 'Jute', 'Silk', 'Polypropylene'], required: true),
            ProductAttribute(name: 'style', label: 'Style', type: AttributeType.select, options: ['Modern', 'Traditional', 'Persian', 'Moroccan', 'Shag', 'Geometric'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'pileHeight', label: 'Pile Height', type: AttributeType.select, options: ['Low', 'Medium', 'High']),
          ],
        ),
        ProductType(
          id: 'wall_art',
          name: 'Wall Art & Decor',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Canvas Print', 'Framed Art', 'Poster', 'Wall Decal', 'Mirror', 'Clock', 'Tapestry'], required: true),
            ProductAttribute(name: 'style', label: 'Style', type: AttributeType.select, options: ['Abstract', 'Modern', 'Traditional', 'Minimalist', 'Photography', 'Typography'], required: true),
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['Small (Under 12")', 'Medium (12-24")', 'Large (24-36")', 'Extra Large (36"+)'], required: true),
            ProductAttribute(name: 'frame', label: 'Frame', type: AttributeType.select, options: ['Framed', 'Unframed', 'Gallery Wrapped']),
            ProductAttribute(name: 'colorTheme', label: 'Color Theme', type: AttributeType.multiSelect, options: AttributeOptions.colors),
          ],
        ),
      ],
    ),
  ],
);


// ============ BEAUTY & PERSONAL CARE ============
final _beauty = Category(
  id: 'beauty',
  name: 'Beauty & Personal Care',
  iconName: 'brush_1',
  subcategories: [
    Subcategory(
      id: 'skincare',
      name: 'Skincare',
      productTypes: [
        ProductType(
          id: 'skincare_products',
          name: 'Skincare Products',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'productType', label: 'Product Type', type: AttributeType.select, options: ['Cleanser', 'Moisturizer', 'Serum', 'Toner', 'Sunscreen', 'Eye Cream', 'Face Mask', 'Exfoliator', 'Face Oil'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., CeraVe, The Ordinary'),
            ProductAttribute(name: 'skinType', label: 'Skin Type', type: AttributeType.multiSelect, options: ['Oily', 'Dry', 'Combination', 'Sensitive', 'Normal', 'All Skin Types'], required: true),
            ProductAttribute(name: 'skinConcern', label: 'Skin Concern', type: AttributeType.multiSelect, options: ['Acne', 'Anti-Aging', 'Hydration', 'Brightening', 'Dark Spots', 'Pores', 'Redness']),
            ProductAttribute(name: 'size', label: 'Size (ml/oz)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'keyIngredients', label: 'Key Ingredients', type: AttributeType.multiSelect, options: ['Hyaluronic Acid', 'Retinol', 'Vitamin C', 'Niacinamide', 'Salicylic Acid', 'AHA/BHA', 'SPF']),
            ProductAttribute(name: 'expiryDate', label: 'Expiry Date', type: AttributeType.date, required: true),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'makeup',
      name: 'Makeup',
      productTypes: [
        ProductType(
          id: 'makeup_products',
          name: 'Makeup Products',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'productType', label: 'Product Type', type: AttributeType.select, options: ['Foundation', 'Concealer', 'Powder', 'Blush', 'Bronzer', 'Highlighter', 'Lipstick', 'Lip Gloss', 'Mascara', 'Eyeliner', 'Eyeshadow', 'Brow Products', 'Setting Spray'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., MAC, Fenty Beauty'),
            ProductAttribute(name: 'shade', label: 'Shade', type: AttributeType.text, required: true),
            ProductAttribute(name: 'finish', label: 'Finish', type: AttributeType.select, options: ['Matte', 'Dewy', 'Satin', 'Shimmer', 'Glitter', 'Natural']),
            ProductAttribute(name: 'coverage', label: 'Coverage', type: AttributeType.select, options: ['Sheer', 'Light', 'Medium', 'Full']),
            ProductAttribute(name: 'size', label: 'Size (ml/g)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'expiryDate', label: 'Expiry Date', type: AttributeType.date, required: true),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'haircare',
      name: 'Haircare',
      productTypes: [
        ProductType(
          id: 'haircare_products',
          name: 'Haircare Products',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'productType', label: 'Product Type', type: AttributeType.select, options: ['Shampoo', 'Conditioner', 'Hair Mask', 'Hair Oil', 'Styling Gel', 'Mousse', 'Hair Spray', 'Heat Protectant', 'Leave-In Conditioner', 'Hair Serum'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Olaplex, Kerastase'),
            ProductAttribute(name: 'hairType', label: 'Hair Type', type: AttributeType.multiSelect, options: ['Straight', 'Wavy', 'Curly', 'Coily', 'All Hair Types'], required: true),
            ProductAttribute(name: 'hairConcern', label: 'Hair Concern', type: AttributeType.multiSelect, options: ['Dry/Damaged', 'Oily', 'Color-Treated', 'Frizzy', 'Thinning', 'Dandruff']),
            ProductAttribute(name: 'size', label: 'Size (ml/oz)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'expiryDate', label: 'Expiry Date', type: AttributeType.date, required: true),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'fragrances',
      name: 'Fragrances',
      productTypes: [
        ProductType(
          id: 'fragrance_products',
          name: 'Fragrances',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Eau de Parfum', 'Eau de Toilette', 'Cologne', 'Body Mist', 'Perfume Oil'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Chanel, Dior'),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Men', 'Women', 'Unisex'], required: true),
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['30ml', '50ml', '75ml', '100ml', '150ml', '200ml'], required: true),
            ProductAttribute(name: 'scentFamily', label: 'Scent Family', type: AttributeType.select, options: ['Floral', 'Woody', 'Fresh', 'Oriental', 'Citrus', 'Aquatic', 'Gourmand']),
            ProductAttribute(name: 'fillLevel', label: 'Fill Level', type: AttributeType.select, options: ['Full', '90%+', '75-90%', '50-75%', 'Below 50%']),
            ProductAttribute(name: 'includesBox', label: 'Includes Box', type: AttributeType.boolean),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'personal_care_tools',
      name: 'Personal Care Tools',
      productTypes: [
        ProductType(
          id: 'beauty_tools',
          name: 'Beauty Tools',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Hair Dryer', 'Flat Iron', 'Curling Iron', 'Electric Shaver', 'Trimmer', 'Electric Toothbrush', 'Facial Cleansing Device', 'LED Mask'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Dyson, GHD'),
            ProductAttribute(name: 'powerSource', label: 'Power Source', type: AttributeType.select, options: ['Corded', 'Cordless', 'Battery'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Heat Settings', 'Ionic', 'Ceramic', 'Titanium', 'Waterproof']),
            ProductAttribute(name: 'warranty', label: 'Warranty', type: AttributeType.select, options: ['None', '6 Months', '1 Year', '2 Years']),
          ],
        ),
      ],
    ),
  ],
);

// ============ BABY & KIDS ============
final _babyKids = Category(
  id: 'baby',
  name: 'Baby & Kids',
  iconName: 'lovely',
  subcategories: [
    Subcategory(
      id: 'baby_gear',
      name: 'Baby Gear',
      productTypes: [
        ProductType(
          id: 'baby_gear_products',
          name: 'Baby Gear',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Stroller', 'Car Seat', 'Baby Carrier', 'High Chair', 'Playpen', 'Baby Swing', 'Bouncer', 'Walker'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Graco, Chicco'),
            ProductAttribute(name: 'ageRange', label: 'Age Range', type: AttributeType.select, options: ['0-6 months', '6-12 months', '1-2 years', '2-4 years'], required: true),
            ProductAttribute(name: 'weightLimit', label: 'Weight Limit (kg)', type: AttributeType.text),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Foldable', 'Reclining', 'Adjustable', 'Travel System Compatible']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'baby_clothing',
      name: 'Baby Clothing',
      productTypes: [
        ProductType(
          id: 'baby_clothes',
          name: 'Baby Clothing',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['Preemie', 'Newborn', '0-3M', '3-6M', '6-9M', '9-12M', '12-18M', '18-24M', '2T', '3T', '4T', '5T'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Onesie', 'Romper', 'Sleepwear', 'Outfit Set', 'Dress', 'Pants', 'Top', 'Jacket'], required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Boy', 'Girl', 'Unisex'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Cotton', 'Organic Cotton', 'Polyester', 'Fleece']),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text),
            ProductAttribute(name: 'season', label: 'Season', type: AttributeType.select, options: ['Summer', 'Winter', 'All Season']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'kids_clothing',
      name: 'Kids Clothing (2-14 years)',
      productTypes: [
        ProductType(
          id: 'kids_clothes',
          name: 'Kids Clothing',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['2T', '3T', '4T', '5', '6', '7', '8', '10', '12', '14'], required: true),
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['T-Shirt', 'Pants', 'Shorts', 'Dress', 'Skirt', 'Jacket', 'Uniform', 'Swimwear'], required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Boy', 'Girl', 'Unisex'], required: true),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors, required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Cotton', 'Polyester', 'Denim', 'Fleece']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'toys_games',
      name: 'Toys & Games',
      productTypes: [
        ProductType(
          id: 'toys',
          name: 'Toys & Games',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Action Figures', 'Dolls', 'Building Blocks', 'Educational', 'Puzzles', 'Board Games', 'Outdoor Toys', 'Remote Control', 'Stuffed Animals', 'Arts & Crafts'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., LEGO, Mattel'),
            ProductAttribute(name: 'ageRange', label: 'Age Range', type: AttributeType.select, options: ['0-2 years', '3-5 years', '6-8 years', '9-12 years', '13+ years'], required: true),
            ProductAttribute(name: 'gender', label: 'Gender', type: AttributeType.select, options: ['Boys', 'Girls', 'Unisex']),
            ProductAttribute(name: 'numberOfPieces', label: 'Number of Pieces', type: AttributeType.text),
            ProductAttribute(name: 'batteryRequired', label: 'Battery Required', type: AttributeType.boolean),
            ProductAttribute(name: 'educationalFocus', label: 'Educational Focus', type: AttributeType.multiSelect, options: ['STEM', 'Motor Skills', 'Creativity', 'Language', 'Math']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'baby_feeding',
      name: 'Baby Feeding',
      productTypes: [
        ProductType(
          id: 'feeding_products',
          name: 'Baby Feeding',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Bottles', 'Nipples', 'Breast Pump', 'Formula', 'Baby Food', 'Bibs', 'Sippy Cups', 'Utensils', 'Sterilizer'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Philips Avent, Dr. Brown\'s'),
            ProductAttribute(name: 'ageRange', label: 'Age Range', type: AttributeType.select, options: ['0-3 months', '3-6 months', '6-12 months', '12+ months'], required: true),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.select, options: ['Plastic', 'Glass', 'Silicone', 'Stainless Steel']),
            ProductAttribute(name: 'bpaFree', label: 'BPA Free', type: AttributeType.boolean),
            ProductAttribute(name: 'quantity', label: 'Quantity', type: AttributeType.text),
            ProductAttribute(name: 'expiryDate', label: 'Expiry Date', type: AttributeType.date),
          ],
        ),
      ],
    ),
  ],
);


// ============ SPORTS & OUTDOORS ============
final _sports = Category(
  id: 'sports',
  name: 'Sports & Outdoors',
  iconName: 'weight',
  subcategories: [
    Subcategory(
      id: 'fitness_equipment',
      name: 'Fitness Equipment',
      productTypes: [
        ProductType(
          id: 'fitness_gear',
          name: 'Fitness Equipment',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Treadmill', 'Exercise Bike', 'Elliptical', 'Rowing Machine', 'Weight Bench', 'Dumbbells', 'Kettlebells', 'Resistance Bands', 'Yoga Mat', 'Pull-Up Bar'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., NordicTrack, Peloton'),
            ProductAttribute(name: 'weightCapacity', label: 'Weight Capacity (kg)', type: AttributeType.text),
            ProductAttribute(name: 'foldable', label: 'Foldable', type: AttributeType.boolean),
            ProductAttribute(name: 'features', label: 'Features', type: AttributeType.multiSelect, options: ['Digital Display', 'Heart Rate Monitor', 'Bluetooth', 'App Compatible']),
            ProductAttribute(name: 'equipmentCondition', label: 'Condition', type: AttributeType.select, options: ['Like New', 'Good', 'Fair']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'sports_equipment',
      name: 'Sports Equipment',
      productTypes: [
        ProductType(
          id: 'football_soccer',
          name: 'Football/Soccer',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Ball', 'Boots', 'Shin Guards', 'Gloves', 'Goal', 'Jersey', 'Shorts'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Nike, Adidas'),
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['3', '4', '5', 'Youth', 'Adult', 'S', 'M', 'L', 'XL', 'XXL'], required: true),
            ProductAttribute(name: 'position', label: 'Position', type: AttributeType.select, options: ['Goalkeeper', 'Outfield']),
          ],
        ),
        ProductType(
          id: 'basketball',
          name: 'Basketball',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Ball', 'Shoes', 'Hoop', 'Jersey', 'Shorts'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Spalding, Wilson'),
            ProductAttribute(name: 'size', label: 'Size', type: AttributeType.select, options: ['5', '6', '7', 'S', 'M', 'L', 'XL', 'XXL'], required: true),
            ProductAttribute(name: 'indoorOutdoor', label: 'Indoor/Outdoor', type: AttributeType.select, options: ['Indoor', 'Outdoor', 'Both']),
          ],
        ),
        ProductType(
          id: 'tennis',
          name: 'Tennis & Racquet Sports',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Racquet', 'Balls', 'Shoes', 'Bag', 'Strings', 'Grip'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Wilson, Babolat'),
            ProductAttribute(name: 'gripSize', label: 'Grip Size', type: AttributeType.select, options: ['4', '4 1/8', '4 1/4', '4 3/8', '4 1/2', '4 5/8']),
            ProductAttribute(name: 'headSize', label: 'Head Size', type: AttributeType.select, options: ['Midsize', 'Mid-Plus', 'Oversize']),
          ],
        ),
        ProductType(
          id: 'golf',
          name: 'Golf',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Clubs', 'Balls', 'Bag', 'Gloves', 'Shoes', 'Rangefinder', 'Cart'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., Titleist, Callaway'),
            ProductAttribute(name: 'clubType', label: 'Club Type', type: AttributeType.select, options: ['Driver', 'Woods', 'Irons', 'Wedges', 'Putter', 'Full Set']),
            ProductAttribute(name: 'flex', label: 'Flex', type: AttributeType.select, options: ['Regular', 'Stiff', 'Senior', 'Ladies']),
            ProductAttribute(name: 'hand', label: 'Hand', type: AttributeType.select, options: ['Right', 'Left'], required: true),
            ProductAttribute(name: 'shaftMaterial', label: 'Shaft Material', type: AttributeType.select, options: ['Steel', 'Graphite']),
          ],
        ),
        ProductType(
          id: 'cycling',
          name: 'Cycling',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Bicycle', 'Helmet', 'Jersey', 'Shorts', 'Gloves', 'Shoes', 'Lights', 'Lock', 'Pump'], required: true),
            ProductAttribute(name: 'bikeType', label: 'Bike Type', type: AttributeType.select, options: ['Road', 'Mountain', 'Hybrid', 'BMX', 'Electric', 'Kids']),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'frameSize', label: 'Frame Size', type: AttributeType.select, options: ['XS', 'S', 'M', 'L', 'XL']),
            ProductAttribute(name: 'wheelSize', label: 'Wheel Size', type: AttributeType.select, options: ['20"', '24"', '26"', '27.5"', '29"', '700c']),
            ProductAttribute(name: 'gears', label: 'Gears', type: AttributeType.select, options: ['Single Speed', '7-Speed', '21-Speed', '24-Speed', '27-Speed']),
            ProductAttribute(name: 'frameMaterial', label: 'Frame Material', type: AttributeType.select, options: ['Aluminum', 'Carbon', 'Steel']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'outdoor_camping',
      name: 'Outdoor & Camping',
      productTypes: [
        ProductType(
          id: 'camping_gear',
          name: 'Camping Gear',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Tent', 'Sleeping Bag', 'Backpack', 'Camping Chair', 'Cooler', 'Lantern', 'Stove', 'Hiking Boots', 'Trekking Poles'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true, hint: 'e.g., The North Face, Columbia'),
            ProductAttribute(name: 'capacity', label: 'Capacity', type: AttributeType.text, hint: 'Person (tents), Liters (backpacks)'),
            ProductAttribute(name: 'seasonRating', label: 'Season Rating', type: AttributeType.select, options: ['2-Season', '3-Season', '4-Season']),
            ProductAttribute(name: 'weight', label: 'Weight (kg)', type: AttributeType.text),
            ProductAttribute(name: 'waterproof', label: 'Waterproof', type: AttributeType.boolean),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors, required: true),
          ],
        ),
      ],
    ),
  ],
);

// ============ BOOKS, MEDIA & ENTERTAINMENT ============
final _books = Category(
  id: 'books',
  name: 'Books, Media & Entertainment',
  iconName: 'book',
  subcategories: [
    Subcategory(
      id: 'books_sub',
      name: 'Books',
      productTypes: [
        ProductType(
          id: 'books_products',
          name: 'Books',
          allowedConditions: ['New', 'Used', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'format', label: 'Format', type: AttributeType.select, options: ['Hardcover', 'Paperback', 'eBook Code'], required: true),
            ProductAttribute(name: 'genre', label: 'Genre', type: AttributeType.select, options: ['Fiction', 'Non-Fiction', 'Mystery', 'Romance', 'Sci-Fi', 'Fantasy', 'Biography', 'Self-Help', 'Business', "Children's", 'Educational', 'Comics/Manga'], required: true),
            ProductAttribute(name: 'language', label: 'Language', type: AttributeType.select, options: ['English', 'Swahili', 'French', 'Arabic', 'Other'], required: true),
            ProductAttribute(name: 'author', label: 'Author', type: AttributeType.text, required: true),
            ProductAttribute(name: 'title', label: 'Title', type: AttributeType.text, required: true),
            ProductAttribute(name: 'isbn', label: 'ISBN', type: AttributeType.text),
            ProductAttribute(name: 'publisher', label: 'Publisher', type: AttributeType.text),
            ProductAttribute(name: 'yearPublished', label: 'Year Published', type: AttributeType.text),
            ProductAttribute(name: 'bookCondition', label: 'Condition', type: AttributeType.select, options: ['Like New', 'Very Good', 'Good', 'Acceptable'], required: true),
            ProductAttribute(name: 'edition', label: 'Edition', type: AttributeType.text, hint: 'e.g., 1st Edition'),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'video_games',
      name: 'Video Games',
      productTypes: [
        ProductType(
          id: 'games',
          name: 'Video Games',
          allowedConditions: ['New', 'Used', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'platform', label: 'Platform', type: AttributeType.select, options: ['PlayStation 5', 'PlayStation 4', 'Xbox Series X/S', 'Xbox One', 'Nintendo Switch', 'PC'], required: true),
            ProductAttribute(name: 'title', label: 'Title', type: AttributeType.text, required: true),
            ProductAttribute(name: 'genre', label: 'Genre', type: AttributeType.select, options: ['Action', 'Adventure', 'RPG', 'Sports', 'Racing', 'Shooter', 'Strategy', 'Puzzle', 'Fighting', 'Simulation'], required: true),
            ProductAttribute(name: 'rating', label: 'Rating', type: AttributeType.select, options: ['E (Everyone)', 'E10+', 'T (Teen)', 'M (Mature)']),
            ProductAttribute(name: 'format', label: 'Format', type: AttributeType.select, options: ['Physical Disc', 'Digital Code'], required: true),
            ProductAttribute(name: 'region', label: 'Region', type: AttributeType.select, options: ['All Regions', 'Region 1', 'Region 2', 'Region Free']),
            ProductAttribute(name: 'includes', label: 'Includes', type: AttributeType.multiSelect, options: ['Original Case', 'Manual', 'DLC Codes']),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'music_vinyl',
      name: 'Music & Vinyl',
      productTypes: [
        ProductType(
          id: 'music',
          name: 'Music & Vinyl',
          allowedConditions: ['New', 'Used', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'format', label: 'Format', type: AttributeType.select, options: ['Vinyl LP', 'CD', 'Cassette', 'Digital Download Code'], required: true),
            ProductAttribute(name: 'genre', label: 'Genre', type: AttributeType.select, options: ['Pop', 'Rock', 'Hip-Hop', 'R&B', 'Electronic', 'Jazz', 'Classical', 'Country', 'Afrobeats', 'Gospel'], required: true),
            ProductAttribute(name: 'artist', label: 'Artist', type: AttributeType.text, required: true),
            ProductAttribute(name: 'albumTitle', label: 'Album Title', type: AttributeType.text, required: true),
            ProductAttribute(name: 'musicCondition', label: 'Condition', type: AttributeType.select, options: ['Mint', 'Near Mint', 'Very Good', 'Good', 'Fair'], required: true),
            ProductAttribute(name: 'speed', label: 'Speed (vinyl)', type: AttributeType.select, options: ['33 RPM', '45 RPM', '78 RPM']),
            ProductAttribute(name: 'specialEdition', label: 'Special Edition', type: AttributeType.boolean),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'movies_tv',
      name: 'Movies & TV Shows',
      productTypes: [
        ProductType(
          id: 'movies',
          name: 'Movies & TV Shows',
          allowedConditions: ['New', 'Used'],
          attributes: [
            ProductAttribute(name: 'format', label: 'Format', type: AttributeType.select, options: ['Blu-ray', '4K UHD', 'DVD', 'Digital Code'], required: true),
            ProductAttribute(name: 'genre', label: 'Genre', type: AttributeType.select, options: ['Action', 'Comedy', 'Drama', 'Horror', 'Sci-Fi', 'Documentary', 'Animation', 'Romance'], required: true),
            ProductAttribute(name: 'title', label: 'Title', type: AttributeType.text, required: true),
            ProductAttribute(name: 'movieRating', label: 'Rating', type: AttributeType.select, options: ['G', 'PG', 'PG-13', 'R', 'NC-17']),
            ProductAttribute(name: 'region', label: 'Region', type: AttributeType.select, options: ['Region A', 'Region B', 'Region Free']),
            ProductAttribute(name: 'edition', label: 'Edition', type: AttributeType.select, options: ['Standard', 'Special Edition', "Collector's", 'Steelbook']),
          ],
        ),
      ],
    ),
  ],
);

// ============ ART & COLLECTIBLES ============
final _art = Category(
  id: 'art',
  name: 'Art & Collectibles',
  iconName: 'designtools',
  subcategories: [
    Subcategory(
      id: 'fine_art',
      name: 'Fine Art',
      productTypes: [
        ProductType(
          id: 'artwork',
          name: 'Fine Art',
          allowedConditions: ['New', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Painting', 'Sculpture', 'Print', 'Photography', 'Mixed Media', 'Digital Art'], required: true),
            ProductAttribute(name: 'medium', label: 'Medium', type: AttributeType.select, options: ['Oil', 'Acrylic', 'Watercolor', 'Charcoal', 'Pastel', 'Bronze', 'Marble', 'Digital'], required: true),
            ProductAttribute(name: 'style', label: 'Style', type: AttributeType.select, options: ['Abstract', 'Contemporary', 'Modern', 'Impressionist', 'Realist', 'Pop Art', 'Minimalist', 'Traditional African'], required: true),
            ProductAttribute(name: 'artist', label: 'Artist', type: AttributeType.text, required: true),
            ProductAttribute(name: 'artTitle', label: 'Title', type: AttributeType.text),
            ProductAttribute(name: 'yearCreated', label: 'Year Created', type: AttributeType.text),
            ProductAttribute(name: 'dimensions', label: 'Dimensions (W x H cm)', type: AttributeType.text, required: true),
            ProductAttribute(name: 'framed', label: 'Framed', type: AttributeType.boolean, required: true),
            ProductAttribute(name: 'signed', label: 'Signed', type: AttributeType.boolean),
            ProductAttribute(name: 'certificate', label: 'Certificate of Authenticity', type: AttributeType.boolean),
            ProductAttribute(name: 'artEdition', label: 'Edition', type: AttributeType.text, hint: 'e.g., 1/50, Open Edition'),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'antiques',
      name: 'Antiques',
      productTypes: [
        ProductType(
          id: 'antique_items',
          name: 'Antiques',
          allowedConditions: ['Collectible'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Furniture', 'Ceramics', 'Glassware', 'Silverware', 'Clocks', 'Textiles', 'Jewelry', 'Books', 'Maps'], required: true),
            ProductAttribute(name: 'eraPeriod', label: 'Era/Period', type: AttributeType.select, options: ['Victorian', 'Art Deco', 'Art Nouveau', 'Mid-Century Modern', 'Colonial', 'Pre-Colonial African'], required: true),
            ProductAttribute(name: 'origin', label: 'Origin', type: AttributeType.text, required: true, hint: 'Country/Region'),
            ProductAttribute(name: 'age', label: 'Age', type: AttributeType.text, required: true, hint: 'Approximate years'),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.text),
            ProductAttribute(name: 'antiqueCondition', label: 'Condition', type: AttributeType.select, options: ['Excellent', 'Very Good', 'Good', 'Fair', 'Restoration Needed'], required: true),
            ProductAttribute(name: 'provenance', label: 'Provenance', type: AttributeType.text, hint: 'History of ownership'),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'coins_currency',
      name: 'Coins & Currency',
      productTypes: [
        ProductType(
          id: 'coins',
          name: 'Coins & Currency',
          allowedConditions: ['Collectible'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Coin', 'Paper Currency', 'Token', 'Medal'], required: true),
            ProductAttribute(name: 'country', label: 'Country', type: AttributeType.text, required: true),
            ProductAttribute(name: 'year', label: 'Year', type: AttributeType.text, required: true),
            ProductAttribute(name: 'denomination', label: 'Denomination', type: AttributeType.text, required: true),
            ProductAttribute(name: 'metalMaterial', label: 'Metal/Material', type: AttributeType.select, options: ['Gold', 'Silver', 'Copper', 'Bronze', 'Nickel', 'Paper'], required: true),
            ProductAttribute(name: 'grade', label: 'Grade', type: AttributeType.select, options: ['MS70', 'MS69', 'MS65', 'AU', 'XF', 'VF', 'F', 'VG', 'G', 'AG', 'Poor']),
            ProductAttribute(name: 'certification', label: 'Certification', type: AttributeType.select, options: ['PCGS', 'NGC', 'Uncertified']),
            ProductAttribute(name: 'mintMark', label: 'Mint Mark', type: AttributeType.text),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'trading_cards',
      name: 'Trading Cards',
      productTypes: [
        ProductType(
          id: 'cards',
          name: 'Trading Cards',
          allowedConditions: ['New', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'category', label: 'Category', type: AttributeType.select, options: ['Sports', 'Pokemon', 'Yu-Gi-Oh', 'Magic: The Gathering', 'Other TCG'], required: true),
            ProductAttribute(name: 'sportGame', label: 'Sport/Game', type: AttributeType.text, required: true),
            ProductAttribute(name: 'playerCharacter', label: 'Player/Character', type: AttributeType.text, required: true),
            ProductAttribute(name: 'year', label: 'Year', type: AttributeType.text, required: true),
            ProductAttribute(name: 'brandSet', label: 'Brand/Set', type: AttributeType.text, required: true, hint: 'e.g., Topps, Panini'),
            ProductAttribute(name: 'cardNumber', label: 'Card Number', type: AttributeType.text),
            ProductAttribute(name: 'grade', label: 'Grade', type: AttributeType.select, options: ['PSA 10', 'PSA 9', 'BGS 10', 'Raw/Ungraded']),
            ProductAttribute(name: 'cardCondition', label: 'Condition', type: AttributeType.select, options: ['Mint', 'Near Mint', 'Excellent', 'Good'], required: true),
            ProductAttribute(name: 'autographed', label: 'Autographed', type: AttributeType.boolean),
            ProductAttribute(name: 'serialNumbered', label: 'Serial Numbered', type: AttributeType.text, hint: 'e.g., /100'),
          ],
        ),
      ],
    ),
  ],
);

// ============ GROCERY & FOOD ============
final _grocery = Category(
  id: 'grocery',
  name: 'Grocery & Food',
  iconName: 'shopping_cart',
  subcategories: [
    Subcategory(
      id: 'packaged_foods',
      name: 'Packaged Foods',
      productTypes: [
        ProductType(
          id: 'packaged',
          name: 'Packaged Foods',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Snacks', 'Cereals', 'Pasta', 'Rice', 'Canned Goods', 'Sauces', 'Condiments', 'Baking', 'Spices'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'dietary', label: 'Dietary', type: AttributeType.multiSelect, options: ['Vegan', 'Vegetarian', 'Gluten-Free', 'Halal', 'Kosher', 'Organic', 'Sugar-Free', 'Keto']),
            ProductAttribute(name: 'weightVolume', label: 'Weight/Volume', type: AttributeType.text, required: true, hint: 'g, kg, ml, L'),
            ProductAttribute(name: 'expiryDate', label: 'Expiry Date', type: AttributeType.date, required: true),
            ProductAttribute(name: 'countryOfOrigin', label: 'Country of Origin', type: AttributeType.text),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'beverages',
      name: 'Beverages',
      productTypes: [
        ProductType(
          id: 'drinks',
          name: 'Beverages',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Water', 'Soft Drinks', 'Juice', 'Tea', 'Coffee', 'Energy Drinks', 'Alcohol'], required: true),
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, required: true),
            ProductAttribute(name: 'volume', label: 'Volume', type: AttributeType.text, required: true, hint: 'ml, L'),
            ProductAttribute(name: 'packSize', label: 'Pack Size', type: AttributeType.select, options: ['Single', '6-Pack', '12-Pack', '24-Pack', 'Case'], required: true),
            ProductAttribute(name: 'dietary', label: 'Dietary', type: AttributeType.multiSelect, options: ['Sugar-Free', 'Diet', 'Organic', 'Caffeine-Free']),
            ProductAttribute(name: 'alcoholContent', label: 'Alcohol Content (%)', type: AttributeType.text),
            ProductAttribute(name: 'expiryDate', label: 'Expiry Date', type: AttributeType.date, required: true),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'fresh_frozen',
      name: 'Fresh & Frozen',
      productTypes: [
        ProductType(
          id: 'fresh',
          name: 'Fresh & Frozen',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'type', label: 'Type', type: AttributeType.select, options: ['Meat', 'Poultry', 'Seafood', 'Dairy', 'Fruits', 'Vegetables', 'Frozen Meals', 'Ice Cream'], required: true),
            ProductAttribute(name: 'storage', label: 'Storage', type: AttributeType.select, options: ['Fresh (Refrigerated)', 'Frozen'], required: true),
            ProductAttribute(name: 'weight', label: 'Weight', type: AttributeType.text, required: true, hint: 'g, kg'),
            ProductAttribute(name: 'organic', label: 'Organic', type: AttributeType.boolean),
            ProductAttribute(name: 'expiryDate', label: 'Expiry Date', type: AttributeType.date, required: true),
            ProductAttribute(name: 'halalCertified', label: 'Halal Certified', type: AttributeType.boolean),
          ],
        ),
      ],
    ),
  ],
);


// ============ OTHER / MISCELLANEOUS ============
/// Catch-all category for products that don't fit into predefined categories.
/// Allows sellers to list any product with basic attributes.
final _other = Category(
  id: 'other',
  name: 'Other',
  iconName: 'box',
  subcategories: [
    Subcategory(
      id: 'general',
      name: 'General',
      productTypes: [
        ProductType(
          id: 'general_product',
          name: 'General Product',
          allowedConditions: ['New', 'Used', 'Refurbished'],
          attributes: [
            ProductAttribute(name: 'brand', label: 'Brand', type: AttributeType.text, hint: 'Enter brand name if applicable'),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.select, options: AttributeOptions.colors),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.text, hint: 'e.g., Plastic, Metal, Wood'),
            ProductAttribute(name: 'dimensions', label: 'Dimensions', type: AttributeType.text, hint: 'L x W x H (cm)'),
            ProductAttribute(name: 'weight', label: 'Weight', type: AttributeType.text, hint: 'e.g., 500g, 2kg'),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'services',
      name: 'Services',
      productTypes: [
        ProductType(
          id: 'service',
          name: 'Service',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'serviceType', label: 'Service Type', type: AttributeType.select, options: ['Repair', 'Installation', 'Consultation', 'Training', 'Cleaning', 'Delivery', 'Custom Work', 'Other'], required: true),
            ProductAttribute(name: 'duration', label: 'Duration', type: AttributeType.text, hint: 'e.g., 1 hour, 2 days'),
            ProductAttribute(name: 'location', label: 'Service Location', type: AttributeType.select, options: ['On-site', 'Remote/Online', 'At Shop', 'Flexible']),
            ProductAttribute(name: 'availability', label: 'Availability', type: AttributeType.text, hint: 'e.g., Mon-Fri 9am-5pm'),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'handmade',
      name: 'Handmade & Crafts',
      productTypes: [
        ProductType(
          id: 'handmade_item',
          name: 'Handmade Item',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'craftType', label: 'Craft Type', type: AttributeType.select, options: ['Jewelry', 'Clothing', 'Home Decor', 'Art', 'Pottery', 'Woodwork', 'Textiles', 'Candles', 'Soap', 'Other'], required: true),
            ProductAttribute(name: 'material', label: 'Materials Used', type: AttributeType.text, required: true, hint: 'e.g., Cotton, Beads, Clay'),
            ProductAttribute(name: 'customizable', label: 'Customizable', type: AttributeType.boolean),
            ProductAttribute(name: 'productionTime', label: 'Production Time', type: AttributeType.text, hint: 'e.g., 3-5 days'),
            ProductAttribute(name: 'color', label: 'Color', type: AttributeType.multiSelect, options: AttributeOptions.colors),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'vintage',
      name: 'Vintage & Antiques',
      productTypes: [
        ProductType(
          id: 'vintage_item',
          name: 'Vintage Item',
          allowedConditions: ['Used', 'Collectible'],
          attributes: [
            ProductAttribute(name: 'era', label: 'Era/Period', type: AttributeType.select, options: ['Pre-1900', '1900-1920s', '1930-1940s', '1950-1960s', '1970-1980s', '1990s', 'Unknown'], required: true),
            ProductAttribute(name: 'itemType', label: 'Item Type', type: AttributeType.text, required: true, hint: 'e.g., Furniture, Jewelry, Decor'),
            ProductAttribute(name: 'origin', label: 'Origin/Country', type: AttributeType.text),
            ProductAttribute(name: 'material', label: 'Material', type: AttributeType.text),
            ProductAttribute(name: 'itemCondition', label: 'Condition Details', type: AttributeType.text, hint: 'Describe any wear, repairs, etc.'),
            ProductAttribute(name: 'provenance', label: 'Provenance', type: AttributeType.text, hint: 'History or origin story if known'),
          ],
        ),
      ],
    ),
    Subcategory(
      id: 'digital',
      name: 'Digital Products',
      productTypes: [
        ProductType(
          id: 'digital_product',
          name: 'Digital Product',
          allowedConditions: ['New'],
          attributes: [
            ProductAttribute(name: 'digitalType', label: 'Type', type: AttributeType.select, options: ['E-book', 'Template', 'Software', 'Music', 'Video', 'Graphics', 'Course', 'Other'], required: true),
            ProductAttribute(name: 'fileFormat', label: 'File Format', type: AttributeType.text, required: true, hint: 'e.g., PDF, MP3, ZIP'),
            ProductAttribute(name: 'fileSize', label: 'File Size', type: AttributeType.text, hint: 'e.g., 50MB'),
            ProductAttribute(name: 'license', label: 'License Type', type: AttributeType.select, options: ['Personal Use', 'Commercial Use', 'Extended License', 'Unlimited']),
            ProductAttribute(name: 'deliveryMethod', label: 'Delivery', type: AttributeType.select, options: ['Instant Download', 'Email Delivery', 'Access Link'], required: true),
          ],
        ),
      ],
    ),
  ],
);
