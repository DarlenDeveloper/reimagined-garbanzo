# Purl Marketplace - Brand Guidelines

**Version:** 2.0  
**Last Updated:** February 23, 2026  
**Status:** Official Brand Standards

---

## 🎨 Brand Colors

### Primary Colors

#### Main Red
- **Hex:** `#fb2a0a`
- **RGB:** `rgb(251, 42, 10)`
- **Usage:** Primary brand color, headers, highlights, active states, splash screen
- **Flutter:** `Color(0xFFfb2a0a)`

#### Dark Red
- **Hex:** `#e02509`
- **RGB:** `rgb(224, 37, 9)`
- **Usage:** Hover states, secondary elements, accents
- **Flutter:** `Color(0xFFe02509)`

#### Button Red
- **Hex:** `#b71000`
- **RGB:** `rgb(183, 16, 0)`
- **Usage:** Buttons, CTAs, interactive elements
- **Flutter:** `Color(0xFFb71000)`
- **IMPORTANT:** Always use solid color, NO GRADIENTS

### Neutral Colors

#### Black
- **Hex:** `#000000`
- **RGB:** `rgb(0, 0, 0)`
- **Usage:** Text, icons, borders, backgrounds
- **Flutter:** `Colors.black` or `Color(0xFF000000)`

#### White
- **Hex:** `#FFFFFF`
- **RGB:** `rgb(255, 255, 255)`
- **Usage:** Backgrounds, text on dark backgrounds, cards
- **Flutter:** `Colors.white` or `Color(0xFFFFFFFF)`

### Color Palette Summary
```dart
// Brand Colors
const Color purlRed = Color(0xFFfb2a0a);        // Main brand color
const Color purlDarkRed = Color(0xFFe02509);    // Secondary/hover
const Color purlButtonRed = Color(0xFFb71000);  // Buttons/CTAs - NO GRADIENTS
const Color purlBlack = Color(0xFF000000);      // Text/icons
const Color purlWhite = Color(0xFFFFFFFF);      // Backgrounds

// Grays (for UI elements)
const Color gray50 = Color(0xFFFAFAFA);
const Color gray100 = Color(0xFFF5F5F5);
const Color gray200 = Color(0xFFEEEEEE);
const Color gray300 = Color(0xFFE0E0E0);
const Color gray400 = Color(0xFFBDBDBD);
const Color gray500 = Color(0xFF9E9E9E);
const Color gray600 = Color(0xFF757575);
const Color gray700 = Color(0xFF616161);
const Color gray800 = Color(0xFF424242);
const Color gray900 = Color(0xFF212121);
```

---

## 🔤 Typography

### Font Family
**Primary:** Google Fonts - Poppins

### Font Weights
- **Light:** 300 - Subtle text, captions
- **Regular:** 400 - Body text, descriptions
- **Medium:** 500 - Subheadings, labels
- **SemiBold:** 600 - Section headers, emphasis
- **Bold:** 700 - Main headings, titles

### Font Sizes
```dart
// Headings
const double heading1 = 32.0;  // Page titles
const double heading2 = 24.0;  // Section headers
const double heading3 = 20.0;  // Subsection headers
const double heading4 = 18.0;  // Card titles

// Body
const double bodyLarge = 16.0;   // Primary body text
const double bodyMedium = 14.0;  // Secondary body text
const double bodySmall = 12.0;   // Captions, labels

// Tiny
const double caption = 11.0;     // Timestamps, metadata
const double tiny = 10.0;        // Badges, tags
```

### Text Styles
```dart
// Example usage
Text(
  'Welcome to Purl',
  style: GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: purlBlack,
  ),
)
```

---

## 🖼️ Logo Usage

### Logo Files Location
**Path:** `~/Downloads/` (to be moved to assets)

### Logo Variants

#### Primary Logo
- **File:** `purl-logo-primary.png`
- **Usage:** App icon, splash screen, main branding
- **Background:** Transparent
- **Format:** PNG with transparency
- **Minimum Size:** 48x48px
- **Recommended Size:** 512x512px

#### Horizontal Logo
- **File:** `purl-logo-horizontal.png`
- **Usage:** Headers, navigation bars, emails
- **Background:** Transparent
- **Format:** PNG with transparency

#### Icon Only
- **File:** `purl-icon.png`
- **Usage:** Favicon, small spaces, app icon
- **Background:** Transparent
- **Format:** PNG with transparency

#### POP AI Logo
- **File:** `popailogo.png`
- **Usage:** AI Shopping Assistant feature
- **Background:** Transparent
- **Size:** 56x56px (UI), 120x120px (large)
- **Format:** PNG with transparency

### Logo Rules
✅ **DO:**
- Use on white or light backgrounds
- Maintain aspect ratio
- Use transparent PNG files
- Ensure minimum clear space around logo
- Use official logo files only

❌ **DON'T:**
- Add backgrounds or circles to logos
- Distort or stretch logos
- Change logo colors
- Add effects (shadows, gradients)
- Use low-resolution versions

### Clear Space
Minimum clear space around logo: **20% of logo height**

---

## 🎯 UI Components

### Buttons

#### Primary Button
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: purlButtonRed,  // #B71000
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  ),
  child: Text(
    'Shop Now',
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

#### Secondary Button
```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: purlBlack,
    side: BorderSide(color: Colors.grey[300]!, width: 1),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text(
    'Cancel',
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

#### Text Button
```dart
TextButton(
  onPressed: () {},
  style: TextButton.styleFrom(
    foregroundColor: purlRed,  // #EB1700
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  child: Text(
    'Learn More',
    style: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

### Text Inputs

#### Standard Input
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Search products...',
    hintStyle: GoogleFonts.poppins(
      fontSize: 14,
      color: Colors.grey[400],
    ),
    filled: true,
    fillColor: Colors.grey[100],
    border: InputBorder.none,  // NO BORDERS
    enabledBorder: InputBorder.none,  // NO BORDERS
    focusedBorder: InputBorder.none,  // NO BORDERS
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  style: GoogleFonts.poppins(fontSize: 14),
)
```

**CRITICAL RULE:** All text inputs must have `border: InputBorder.none` - NO visible borders!

### Cards

#### Product Card
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: // Card content
)
```

#### Info Card
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(12),
  ),
  child: // Card content
)
```

### Icons

#### Icon Style
- **Package:** `iconsax` (preferred) or Material Icons
- **Size:** 20-24px for UI elements, 16-18px for inline
- **Color:** `purlBlack` for primary, `Colors.grey[600]` for secondary

```dart
Icon(
  Iconsax.shopping_cart,
  size: 24,
  color: purlBlack,
)
```

### Badges

#### Verification Badge
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.verified, size: 12, color: Colors.white),
      SizedBox(width: 4),
      Text(
        'Verified',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
)
```

#### Status Badge
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: purlRed.withOpacity(0.1),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    'New',
    style: GoogleFonts.poppins(
      fontSize: 11,
      color: purlRed,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

---

## 📐 Spacing & Layout

### Spacing Scale
```dart
const double space4 = 4.0;
const double space8 = 8.0;
const double space12 = 12.0;
const double space16 = 16.0;
const double space20 = 20.0;
const double space24 = 24.0;
const double space32 = 32.0;
const double space40 = 40.0;
const double space48 = 48.0;
```

### Border Radius
```dart
// RULE: Always use height / 2 for border radius
const double buttonHeight = 52.0;
const double buttonRadius = 26.0; // 52 / 2

// Examples:
BorderRadius.circular(height / 2)  // For buttons
BorderRadius.circular(50)          // For 100px logo
BorderRadius.circular(26)          // For 52px button
```

### Padding Guidelines
- **Screen padding:** 16-20px
- **Card padding:** 16px
- **Button padding:** 14px vertical, 24px horizontal
- **List item padding:** 12-16px

---

## 🎭 Visual Style

### Shadows
**IMPORTANT: Do not add shadows unless explicitly requested**

If shadows are needed:
```dart
// Subtle shadow (only when requested)
BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
  offset: Offset(0, 2),
)
```

### Elevation
- **Level 0:** Flat surfaces (backgrounds)
- **Level 1:** Cards, list items
- **Level 2:** Buttons, chips
- **Level 3:** Floating action buttons
- **Level 4:** Modals, dialogs

### Opacity
- **Disabled:** 0.4
- **Subtle:** 0.6
- **Medium:** 0.8
- **Full:** 1.0

---

## 🚫 What NOT to Use

### Deprecated Colors
❌ **Green colors** - No longer part of brand
❌ **Blue (except verification badge)** - Use red instead
❌ **Purple, orange, yellow** - Not in brand palette

### Deprecated Styles
❌ **Borders on text inputs** - Use filled backgrounds only
❌ **Gradients** - Use solid colors ONLY (especially for buttons)
❌ **Shadows** - Do not add shadows unless explicitly requested
❌ **Drop shadows on text** - Use proper contrast instead
❌ **Logos with background circles** - Use transparent PNGs

### Border Radius Rule
✅ **Always use height / 2 for border radius** on buttons and containers
- Example: 52px height button = 26px border radius
- Example: 100px logo = 50px border radius

---

## 📱 App-Specific Guidelines

### Buyer App (purl-stores-app)
- Primary color: `purlRed` (#fb2a0a)
- Buttons: `purlButtonRed` (#b71000) - SOLID COLOR ONLY, NO GRADIENTS
- Active states: `purlDarkRed` (#e02509)
- Background: White
- Cards: White with subtle shadow

### Seller App (purl-admin-app)
- Same color scheme as buyer app
- Dashboard uses gray backgrounds
- Charts use red color scale
- Status indicators use semantic colors (green=success, red=error)

### Courier App (purl_courier_app)
- Same color scheme as buyer/seller apps
- Map markers use `purlRed`
- Route lines use `purlDarkRed`

---

## 🎨 Color Usage Examples

### Primary Actions
- **Add to Cart:** `purlButtonRed`
- **Buy Now:** `purlButtonRed`
- **Checkout:** `purlButtonRed`
- **Submit:** `purlButtonRed`

### Secondary Actions
- **Cancel:** Gray outline button
- **Back:** Black text button
- **Skip:** Gray text button

### Status Colors
- **Success:** `Color(0xFF10B981)` (Green)
- **Error:** `purlRed` (#fb2a0a)
- **Warning:** `Color(0xFFF59E0B)` (Amber)
- **Info:** `Color(0xFF3B82F6)` (Blue)

### Text Colors
- **Primary text:** `purlBlack` (#000000)
- **Secondary text:** `Colors.grey[600]`
- **Disabled text:** `Colors.grey[400]`
- **Link text:** `purlRed` (#fb2a0a)

---

## 📋 Implementation Checklist

### For Each Screen:
- [ ] Replace all green colors with red
- [ ] Remove borders from text inputs
- [ ] Use Poppins font throughout
- [ ] Apply correct button styles
- [ ] Use transparent logo PNGs
- [ ] Verify spacing and padding
- [ ] Check text contrast ratios
- [ ] Test on light and dark backgrounds

### For Each Component:
- [ ] Follow color guidelines
- [ ] Use correct font weights
- [ ] Apply proper border radius
- [ ] Use appropriate shadows
- [ ] Ensure accessibility (contrast)

---

## 🔗 Resources

### Design Files
- Logo files: `~/Downloads/` → Move to `assets/images/`
- Brand colors: See color palette above
- Typography: Google Fonts Poppins

### Code References
- Color constants: Create `lib/constants/colors.dart`
- Text styles: Create `lib/constants/text_styles.dart`
- Component styles: Create `lib/constants/component_styles.dart`

### External Links
- Google Fonts Poppins: https://fonts.google.com/specimen/Poppins
- Iconsax Icons: https://pub.dev/packages/iconsax
- Material Design: https://m3.material.io/

---

## 📞 Brand Contact

For brand-related questions or approvals:
- **Brand Manager:** [Name]
- **Design Lead:** [Name]
- **Email:** brand@purl.co.za

---

**Last Review:** February 23, 2026  
**Next Review:** March 23, 2026
