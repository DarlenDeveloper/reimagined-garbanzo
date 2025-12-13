# GlowCart Project Update Log

**Date:** December 13, 2025

---

## Completed Today

### Seller Portal (Next.js)
- Socials page with Instagram-style UI
- Product specifications system
- All settings sections
- Notification badge fixes
- Users page 3-column grid view
- Compact notifications with expandable rows

### Marketplace App (Flutter)
- Project setup with Poppins font (google_fonts)
- Theme colors: beige (#F5F0E8), dark green (#1B4332), accent beige (#D4C9B9)

**Onboarding:**
- 3-slide carousel with user-provided images
- Title at top left (light/bold text styling)
- Skip button, line page indicators, circular arrow button
- Gradient beige-to-white background

**Authentication:**
- Auth screen with Google, Apple, Email options (no Facebook)
- Login screen with email/password form
- Signup screen with name, email, password, confirm password, terms checkbox
- Social login icons (Google gradient G, Apple icon)

**Navigation:**
- Custom bottom nav bar (4 tabs: Feed, Discover, Order, Profile)
- Beige background pill container
- Dark green active state with expanding label
- Outline icons for inactive, filled for active
- Smooth animation transitions

**Blank Placeholder Screens:**
- Feed
- Discover
- Order
- Profile

---

## Next Steps

### Marketplace App - Main Screens
1. **Feed Screen** - Social feed from followed vendors
2. **Discover Screen** - Browse products/vendors
3. **Order Screen** - Order history and tracking
4. **Profile Screen** - User profile and settings

### Additional Screens Needed
- Product detail
- Vendor detail
- Cart
- Checkout
- Search
- Categories

### Backend Integration
- API setup
- Authentication flow
- Data models

---

## File Structure

```
glowcart-marketplace-app/glowcart_app/
├── lib/
│   ├── main.dart
│   ├── navigation/
│   │   └── router.dart
│   ├── screens/
│   │   ├── onboarding_screen.dart
│   │   ├── auth_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── main_screen.dart
│   │   ├── feed_screen.dart
│   │   ├── discover_screen.dart
│   │   ├── order_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/
│   │   └── bottom_nav_bar.dart
│   └── theme/
│       ├── colors.dart
│       └── theme.dart
├── assets/
│   └── images/ (user-provided)
└── pubspec.yaml
```

---

## Design Notes

- Font: Poppins (all weights)
- Primary: Dark Green #1B4332
- Background: Beige #F5F0E8
- Accent: #D4C9B9
- Nav bar style: Pill-shaped, expanding active state
