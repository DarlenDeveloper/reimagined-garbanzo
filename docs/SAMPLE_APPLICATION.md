# Sample Application - Design Rules & Implementation Guide

**Created:** February 23, 2026  
**Status:** Active Reference Document

---

## 🎨 Design Rules Summary

### Color Rules
1. **Main Red**: `#fb2a0a` - Primary brand color, splash screens
2. **Dark Red**: `#e02509` - Secondary/hover states  
3. **Button Red**: `#b71000` - ALL buttons and CTAs
4. **Black**: `#000000` - Text, icons
5. **White**: `#FFFFFF` - Backgrounds

### Critical Design Rules

#### ❌ NEVER USE:
- **Gradients** - Always use solid colors only
- **Borders on text inputs** - Use `InputBorder.none` always
- **Shadows** - Do not add unless explicitly requested
- **Old color values** - Only use the colors listed above

#### ✅ ALWAYS USE:
- **Border Radius = Height / 2** for buttons and interactive elements
  - 52px button height = 26px border radius
  - 100px element = 50px border radius
- **Solid Button Color**: `#b71000` for all buttons
- **No borders on TextField**: Use filled backgrounds with `InputBorder.none`
- **Poppins font** for all text

---

## 📐 Component Specifications

### Buttons
```dart
// Standard button
Container(
  height: 52,
  decoration: BoxDecoration(
    color: Color(0xFFb71000), // Button Red - SOLID ONLY
    borderRadius: BorderRadius.circular(26), // height / 2
  ),
  child: Center(
    child: Text(
      'Button Text',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
)
```

### Text Fields
```dart
// Standard text field
Container(
  height: 52,
  decoration: BoxDecoration(
    color: Colors.grey[50],
    borderRadius: BorderRadius.circular(26), // height / 2
  ),
  child: TextField(
    decoration: InputDecoration(
      hintText: 'Placeholder text',
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      filled: false,
      border: InputBorder.none,        // NO BORDERS
      enabledBorder: InputBorder.none, // NO BORDERS
      focusedBorder: InputBorder.none, // NO BORDERS
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    style: GoogleFonts.poppins(fontSize: 15),
  ),
)
```

### Social Sign-In Buttons
```dart
// Google button - White with border
Container(
  height: 52,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26), // height / 2
    border: Border.all(color: Colors.grey[300]!, width: 1.5),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset('assets/images/googlelogo.png', width: 24, height: 24),
      SizedBox(width: 12),
      Text('Continue with Google', style: GoogleFonts.poppins(...)),
    ],
  ),
)

// Apple button - Black with white icon
Container(
  height: 52,
  decoration: BoxDecoration(
    color: Colors.black,
    borderRadius: BorderRadius.circular(26), // height / 2
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.apple, size: 24, color: Colors.white),
      SizedBox(width: 12),
      Text('Continue with Apple', style: GoogleFonts.poppins(color: Colors.white, ...)),
    ],
  ),
)
```

### Logo Display
```dart
// Logo with rounded corners (NOT circular)
ClipRRect(
  borderRadius: BorderRadius.circular(24), // Fixed value, not height/2
  child: Image.asset(
    'assets/images/popstoreslogo.PNG',
    width: 100,
    height: 100,
    fit: BoxFit.cover,
  ),
)
```

---

## 🎯 Auth Screen Layout Pattern

### Structure
1. **Top spacing**: 60px
2. **Logo**: 100x100 with 24px border radius
3. **Welcome text**: 28px bold, 24px spacing below logo
4. **Subtitle**: 15px regular, grey[600]
5. **Social buttons**: 48px spacing, 16px between buttons
6. **Divider**: 32px spacing with "or sign in with email" text
7. **Form fields**: 32px spacing, 20px between fields
8. **Action button**: 32px spacing above
9. **Bottom link**: 32px spacing, 40px bottom padding

### Spacing Scale
- Small: 8px
- Medium: 16px
- Large: 24px
- XLarge: 32px
- XXLarge: 48px
- Top: 60px

---

## 🚫 Common Mistakes to Avoid

1. ❌ Using `#c72008` for buttons (OLD) → ✅ Use `#b71000`
2. ❌ Adding `BoxShadow` by default → ✅ Only when requested
3. ❌ Using `OutlineInputBorder` → ✅ Use `InputBorder.none`
4. ❌ Using `LinearGradient` → ✅ Use solid colors
5. ❌ Random border radius values → ✅ Use height / 2
6. ❌ Circular logo (height/2) → ✅ Use 24px border radius

---

## 📱 Implementation Checklist

### For Each Auth Screen:
- [ ] Logo: 100x100 with 24px border radius
- [ ] Google button: White background, grey border, Google logo image
- [ ] Apple button: Black background, white Apple icon (Icons.apple)
- [ ] All buttons: height 52, borderRadius 26
- [ ] All text fields: height 52, borderRadius 26, no borders
- [ ] Main action button: #b71000 solid color
- [ ] No shadows anywhere
- [ ] No gradients anywhere
- [ ] Poppins font throughout
- [ ] Proper spacing (60, 48, 32, 24, 20, 16, 8)

---

## 🎨 Color Constants

```dart
// Brand colors - Use these exact values
static const Color popRed = Color(0xFFfb2a0a);        // Main brand
static const Color popDarkRed = Color(0xFFe02509);    // Hover states
static const Color popButtonRed = Color(0xFFb71000);  // Buttons ONLY
```

---

## 📝 Notes

- These rules were established during the POP rebranding phase
- All auth screens must follow this exact pattern
- Consistency is critical across all screens
- When in doubt, refer to `sign_screen.dart` as the reference implementation

---

**Last Updated:** February 23, 2026  
**Reference Screen:** `purl-stores-app(buyer)/lib/screens/sign_screen.dart`


---

## 📱 Product Detail Screen Redesign

**Status:** Planned  
**Priority:** HIGH  
**Reference:** Inspired by clean e-commerce product pages

### Design Goals
1. Clean, minimal layout with focus on product
2. Large, prominent product images
3. Clear visual hierarchy
4. Easy variant selection
5. Prominent Add to Cart action
6. All brand rules applied

### Layout Structure

```
┌─────────────────────────────┐
│ [←] Product Name      [♡][🛒]│ ← Header (white bg)
├─────────────────────────────┤
│                             │
│     [Product Image]         │ ← Large image (swipeable)
│                             │
│  [●][○][○][○]              │ ← Image indicators
│                             │
│ [thumb][thumb][thumb][thumb]│ ← Thumbnail gallery
├─────────────────────────────┤
│ Store Name ✓                │ ← Store info
│ Tap to view store      [💬] │
├─────────────────────────────┤
│ Product Name                │ ← Product info
│ Short description...        │
│                             │
│ $519  $553                  │ ← Price (red, strikethrough)
├─────────────────────────────┤
│ Size                        │ ← Variants
│ [L] [M] [XL] [XXL] [3XL]   │
│                             │
│ Color                       │
│ [●][●][●][●]               │
├─────────────────────────────┤
│ Quantity                    │
│ [-]  1  [+]                │
├─────────────────────────────┤
│ Details | Reviews | Q&A     │ ← Tabs
│ ─────                       │
│ [Tab Content]               │
│                             │
├─────────────────────────────┤
│ [   Add to Cart - $519   ]  │ ← Fixed bottom button
└─────────────────────────────┘
```

### Component Specifications

#### Header
- Height: 56px
- Background: White
- Back button: 40x40, borderRadius 20
- Title: Poppins 18px SemiBold
- Icons: Wishlist (heart), Cart with badge

#### Product Image
- Full width
- Aspect ratio: 1:1
- Swipeable PageView
- Indicators: 8px dots, active = main red
- Thumbnails: 60x60, borderRadius 12, 8px spacing

#### Store Card
- Height: 60px
- Background: grey[50]
- BorderRadius: 16
- Store logo: 40x40, borderRadius 20
- Verification badge: main red
- Message button: 40x40, borderRadius 20

#### Price Display
- Current price: Poppins 24px Bold, main red (#fb2a0a)
- Compare price: Poppins 18px, grey, strikethrough

#### Variant Selectors
**Size Pills:**
- Height: 44px
- BorderRadius: 22 (height/2)
- Unselected: grey[100], black text
- Selected: main red, white text
- Spacing: 8px

**Color Circles:**
- Size: 44x44
- BorderRadius: 22 (circular)
- Border: 2px, selected = main red

#### Quantity Selector
- Height: 44px
- Buttons: 44x44, borderRadius 22
- Background: grey[100]
- Number: Poppins 16px SemiBold

#### Add to Cart Button
- Height: 56px
- BorderRadius: 28 (height/2)
- Background: button red (#b71000)
- Text: Poppins 16px SemiBold, white
- Fixed at bottom with padding

### Brand Rules Applied
✅ Main red (#fb2a0a) for: price, active variants, verification badge
✅ Button red (#b71000) for: Add to Cart button
✅ Border radius = height / 2 for all interactive elements
✅ Poppins font throughout
✅ No gradients
✅ No shadows (except subtle on bottom button)
✅ Clean white background

### Key Features to Maintain
- All variant selection logic
- Add to cart functionality
- Wishlist toggle
- Store messaging
- Product specifications
- Reviews system
- Q&A system
- Image gallery
- Currency conversion
- Stock status
- Quantity limits

### Implementation Notes
- Keep all existing services and backend logic
- Maintain state management
- Preserve navigation flow
- Keep error handling
- Maintain loading states
- Preserve analytics tracking

---

**Critical Rule:**
🚫 NO SHARP CORNERS ANYWHERE
✅ Use height/2 border radius on ALL elements including:
- Buttons
- Text fields
- Cards
- Tabs (even tab indicators)
- Containers
- Images (except full-width hero images)

**Next Steps:**
1. Create clean UI with new layout (IN PROGRESS)
2. Wire up existing backend functionality
3. Test all user flows
4. Verify brand consistency

**Implementation Status:**
- File backed up as `product_detail_screen_old.dart`
- Original file: 1546 lines (too large for single rewrite)
- Approach: Systematic redesign maintaining all functionality
