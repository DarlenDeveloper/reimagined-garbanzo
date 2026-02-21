# Discounts Backend Implementation

## Overview
Implemented real Firestore backend for the Discounts screen in the seller app, replacing dummy data with persistent storage and full CRUD operations.

## Changes Made

### 1. Created Discount Service (`purl-admin-app(seller)/lib/services/discount_service.dart`)

#### Discount Model
- `id`: Unique identifier
- `code`: Discount code (e.g., "SUMMER20")
- `type`: "percentage" or "fixed"
- `value`: Discount value (percentage or amount)
- `usageLimit`: Optional maximum usage count
- `usageCount`: Current usage count
- `status`: "active" or "expired"
- `expiresAt`: Optional expiry date
- `createdAt`: Creation timestamp

#### Service Methods
- `getDiscountsStream(storeId)`: Real-time stream of discounts
- `createDiscount()`: Create new discount with validation
- `updateDiscountStatus()`: Activate/deactivate discounts
- `deleteDiscount()`: Remove discount from Firestore
- `incrementUsage()`: Track discount usage
- `validateDiscountCode()`: Validate and apply discount codes
- `autoExpireDiscounts()`: Auto-expire based on date/usage

#### Helper Methods in Model
- `getExpiryText()`: Returns human-readable expiry status
- `getUsageText()`: Returns usage count (e.g., "45/100" or "12/∞")
- `isValid`: Checks if discount is still valid

### 2. Updated Discounts Screen (`purl-admin-app(seller)/lib/screens/discounts_screen.dart`)

#### Features Implemented
- Real-time discount list using StreamBuilder
- Create discount with:
  - Code input
  - Type selection (percentage/fixed)
  - Value input
  - Optional usage limit
  - Expiry duration in days
- Long-press to show options:
  - Activate/Deactivate
  - Delete
- Empty state when no discounts exist
- Proper currency formatting for fixed amount discounts using CurrencyService
- Loading state while fetching store ID

#### UI Improvements
- Shows discount code in black badge
- Status indicator (Active/Expired) with color coding
- Usage count display
- Days left until expiry
- Proper error handling with snackbar messages

## Firestore Structure

```
/stores/{storeId}/discounts/{discountId}
├── code: string (uppercase)
├── type: string ("percentage" | "fixed")
├── value: number
├── usageLimit: number | null
├── usageCount: number
├── status: string ("active" | "expired")
├── expiresAt: timestamp | null
└── createdAt: timestamp
```

## Usage Flow

### Creating a Discount
1. User taps FAB button
2. Fills in discount details:
   - Code (e.g., "SUMMER20")
   - Type (percentage or fixed amount)
   - Value (e.g., 20 for 20% or 5000 for USh 5,000)
   - Usage limit (optional)
   - Expiry duration in days (default 30)
3. Discount saved to Firestore
4. Appears immediately in list via StreamBuilder

### Managing Discounts
1. Long-press on discount card
2. Options:
   - Activate/Deactivate: Toggle status
   - Delete: Remove from Firestore

### Discount Validation (for future buyer app integration)
- Use `validateDiscountCode()` to check if code is valid
- Checks:
  - Code exists
  - Status is active
  - Not expired by date
  - Usage limit not reached
- Returns discount object if valid, null otherwise

## Integration Points

### For Buyer App (Future)
When implementing discount codes in checkout:

```dart
final discount = await DiscountService().validateDiscountCode(storeId, code);
if (discount != null) {
  // Apply discount
  if (discount.type == 'percentage') {
    final discountAmount = total * (discount.value / 100);
  } else {
    final discountAmount = discount.value;
  }
  
  // Increment usage
  await DiscountService().incrementUsage(storeId, discount.id);
}
```

### Auto-Expiry (Future Cloud Function)
Create a scheduled Cloud Function to run daily:

```typescript
export const autoExpireDiscounts = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    // Get all stores
    const stores = await admin.firestore().collection('stores').get();
    
    for (const store of stores.docs) {
      // Auto-expire discounts for each store
      // (Call the autoExpireDiscounts method logic)
    }
  });
```

## Testing Checklist

- [x] Create discount with percentage type
- [x] Create discount with fixed amount type
- [x] Create discount with usage limit
- [x] Create discount without usage limit (infinite)
- [x] View discounts in real-time
- [x] Deactivate active discount
- [x] Activate expired discount
- [x] Delete discount
- [x] Empty state displays correctly
- [x] Currency formatting for fixed amounts
- [x] Expiry countdown displays correctly

## Notes

- Discounts are stored per store in subcollection
- Real-time updates via StreamBuilder
- Proper error handling with user feedback
- Currency formatting uses CurrencyService for consistency
- Long-press gesture for options (intuitive mobile UX)
- Auto-expiry can be implemented via Cloud Function or called periodically
- Discount validation ready for buyer app integration
