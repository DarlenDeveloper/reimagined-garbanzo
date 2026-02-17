# Seller Analytics Real Data Implementation

## Date: February 18, 2026

## Current Status
The Analytics screen currently uses all dummy/hardcoded data across 5 tabs:
1. Overview - Revenue, Orders, Visitors, Conversion
2. Sales - Sales breakdown, payment methods
3. Products - Top selling products, categories
4. Traffic - Visitor sources, devices
5. Support - AI calls, resolution rates

## Implementation Plan

### Tab 1: Overview ✅ (Starting)
**Real Data Sources:**
- Revenue: Sum of order totals from Firestore
- Orders: Count of orders
- Visitors: Track from analytics (if available) or estimate from orders
- Conversion: Orders / Visitors ratio
- Revenue Trend: Daily revenue for past 7 days
- Recent Activity: Latest orders from Firestore

**Firestore Queries:**
```dart
// Get orders for date range
stores/{storeId}/orders
  .where('createdAt', '>=', startDate)
  .where('createdAt', '<=', endDate)
  .orderBy('createdAt', descending: true)
```

### Tab 2: Sales (Next)
**Real Data Sources:**
- Total Sales: Sum of all order totals
- Daily Sales Chart: Group orders by day
- Sales Breakdown: Product sales vs shipping vs tips
- Payment Methods: Group by payment method

### Tab 3: Products (Next)
**Real Data Sources:**
- Total Products: Count from products collection
- Active Products: Where status == 'active'
- Low Stock: Where stock < threshold
- Top Selling: Group by product, count sales
- Category Performance: Group by category

### Tab 4: Traffic (Next)
**Real Data Sources:**
- May need to implement basic analytics tracking
- Or use estimates based on order data
- Device breakdown from user agents (if tracked)

### Tab 5: Support (Next)
**Real Data Sources:**
- If AI support system exists, query call logs
- Otherwise, may need to keep as placeholder or remove

## Notes
- Start with Overview tab as it's most important
- Use real Firestore data where available
- Keep UI exactly the same, just replace data source
- Add loading states for async data
- Handle empty states gracefully
