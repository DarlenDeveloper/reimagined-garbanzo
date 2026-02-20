# Cart Screen UI Redesign

## Overview
Redesign the cart screen to match a premium, minimalist design with cleaner card layouts and better visual hierarchy.

## Current vs Target Design

### Target Design Features
1. **Header**
   - "My Cart" title with item count in grey "(3)"
   - Back arrow on left
   - Clean, minimal header

2. **Cart Items**
   - White rounded cards with subtle shadow
   - Product image on left with light grey background (rounded)
   - Product name in bold
   - "By [Seller Name]" in light grey below product name
   - Current price in bold black
   - Original price strikethrough in grey (if discounted)
   - Quantity controls (- and +) on right side
   - Quantity number displayed between controls
   - "Add To Fav" heart icon (outline) below product
   - Delete/trash icon next to favorite icon

3. **Bottom Section**
   - Simple black "Checkout →" button
   - No visible order summary on main screen
   - Button floats at bottom

4. **Removed Elements**
   - Remove "Orders" button from header
   - Remove promo code section from main view
   - Remove order summary section from main view
   - Simplify to focus on cart items only

## Design Specifications

### Colors
- Background: White (#FFFFFF)
- Card background: White with subtle shadow
- Product image background: Light grey (#F5F5F5)
- Primary text: Black (#000000)
- Secondary text: Grey (#9E9E9E)
- Price: Black bold
- Strikethrough price: Light grey
- Checkout button: Black (#000000)
- Button text: White

### Typography
- Product name: 16px, Semi-bold
- Seller name: 12px, Regular, Grey
- Price: 18px, Bold, Black
- Original price: 14px, Regular, Grey, Strikethrough
- Quantity: 16px, Semi-bold

### Spacing
- Card padding: 16px
- Card margin: 12px horizontal, 8px vertical
- Image size: 80x80px with 12px border radius
- Quantity controls: 32x32px buttons

## Implementation Plan

### Phase 1: Layout Structure
1. Update header to show item count
2. Restructure cart item cards
3. Remove order summary from main view
4. Update bottom button

### Phase 2: Cart Item Card
1. Create new card layout with image on left
2. Add seller name display
3. Implement quantity controls on right
4. Add favorite and delete icons below item
5. Show original price with strikethrough

### Phase 3: Interactions
1. Update quantity increment/decrement
2. Add to favorites functionality
3. Delete item confirmation
4. Smooth animations for quantity changes

### Phase 4: Order Summary
1. Move order summary to checkout screen or bottom sheet
2. Show summary when user taps checkout
3. Include promo code in summary view

## Files to Modify

### Primary Files
- `purl-stores-app(buyer)/lib/screens/cart_screen.dart` - Main cart UI
- `purl-stores-app(buyer)/lib/services/cart_service.dart` - Cart logic (if needed)

### Supporting Files
- May need to update checkout flow to show order summary

## Technical Considerations

1. **Seller Name Display**
   - Need to fetch seller/store name for each item
   - May require additional Firestore queries
   - Consider caching seller names

2. **Favorites Integration**
   - Check if favorites service exists
   - Implement add to favorites from cart

3. **State Management**
   - Maintain current cart functionality
   - Ensure promo codes still work (moved to checkout)
   - Keep multi-store cart logic intact

4. **Performance**
   - Optimize image loading with CachedNetworkImage
   - Minimize rebuilds during quantity changes
   - Use StreamBuilder efficiently

## Testing Checklist
- [ ] Cart items display correctly
- [ ] Quantity controls work
- [ ] Delete item works
- [ ] Add to favorites works
- [ ] Checkout button navigates correctly
- [ ] Order summary shows on checkout
- [ ] Promo codes still functional
- [ ] Multi-store carts handled properly
- [ ] Empty cart state displays
- [ ] Loading states work
- [ ] Animations smooth

## Notes
- Keep existing cart logic intact
- Focus on UI changes only
- Maintain compatibility with payment flow
- Ensure responsive design
- Test with multiple items and stores
