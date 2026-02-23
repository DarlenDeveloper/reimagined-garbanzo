# Rebranding Guide: PURL/Wibble → POP

**Target Completion**: Before Launch (Feb 27, 2026)  
**Status**: IN PROGRESS - Buyer App Phase

---

## Brand Identity

### Old Names
- PURL (original)
- Wibble (current in code)

### New Names
- **POP** - Main brand and buyer app
- **POP Seller** - Vendor app
- **POP Rider** - Courier app

---

## Brand Assets (CONFIRMED)

### Color Palette ✅
See `BRAND_GUIDELINES.md` for complete specifications:
- **Main Red**: #fb2a0a (primary brand color, splash screen)
- **Dark Red**: #d91400 (secondary/hover states)
- **Button Red**: #b71000 (buttons and CTAs)
- **Black**: #000000 (text, icons)
- **White**: #FFFFFF (backgrounds)

### Typography ✅
- **Primary Font**: Poppins (all weights)
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)
- **Usage**: ALL text across all apps must use Poppins

### Logo Assets ✅
- **App Launcher Logo**: `/home/wibbleapp/Downloads/popstoreslogo.PNG`
- **Splash Screen**: `/home/wibbleapp/Downloads/allsplashscreen.PNG` (used for all apps)

---

## CURRENT TASK: Buyer App Rebranding

**App**: `purl-stores-app(buyer)`  
**Priority**: HIGH  
**Scope**: Frontend UI/UX ONLY - NO backend changes

### Requirements

#### 1. Typography (CRITICAL)
- [ ] Replace ALL fonts with Poppins across every screen
- [ ] Apply appropriate weights (Regular, Medium, SemiBold, Bold)
- [ ] Update theme configuration
- [ ] Verify on all screens

#### 2. Naming (CRITICAL)
- [ ] Find and replace "Wibble" → "POP" everywhere
- [ ] Check: Screen titles, labels, text, comments, variable names
- [ ] Maintain proper casing (POP, Pop, pop as contextually appropriate)
- [ ] Update app name in pubspec.yaml
- [ ] Update display name in Android/iOS configs

#### 3. Logo & Splash Screen
- [ ] Copy `/home/wibbleapp/Downloads/popstoreslogo.PNG` to assets
- [ ] Update app launcher icon with popstoreslogo.PNG
- [ ] Copy `/home/wibbleapp/Downloads/allsplashscreen.PNG` to assets
- [ ] Update splash screen to use allsplashscreen.PNG
- [ ] Configure for Android and iOS

#### 4. Colors
- [ ] Apply brand color palette from BRAND_GUIDELINES.md
- [ ] Update theme files with new colors
- [ ] Remove any green colors (not in brand palette)
- [ ] Update button styles to use Button Red (#B71000)
- [ ] Verify contrast and accessibility

### Out of Scope (DO NOT TOUCH)
- ❌ Backend/Cloud Functions
- ❌ Seller app (separate task later)
- ❌ Courier app (separate task later)
- ❌ Database/Firestore
- ❌ Firebase configuration
- ❌ Package names (will change later)

---

## Files to Update

### All Apps - Package Names

#### POP (Buyer App)
**Current**: `com.purl.stores`  
**New**: `com.pop.app`

Files to update:
- `purl-stores-app(buyer)/android/app/build.gradle`
- `purl-stores-app(buyer)/android/app/src/main/AndroidManifest.xml`
- `purl-stores-app(buyer)/ios/Runner.xcodeproj/project.pbxproj`
- `purl-stores-app(buyer)/ios/Runner/Info.plist`

#### POP Seller
**Current**: `com.purl.admin`  
**New**: `com.pop.seller`

Files to update:
- `purl-admin-app(seller)/android/app/build.gradle`
- `purl-admin-app(seller)/android/app/src/main/AndroidManifest.xml`
- `purl-admin-app(seller)/ios/Runner.xcodeproj/project.pbxproj`
- `purl-admin-app(seller)/ios/Runner/Info.plist`

#### POP Rider
**Current**: `com.example.purl_courier_app`  
**New**: `com.pop.rider`

Files to update:
- `purl_courier_app/android/app/build.gradle`
- `purl_courier_app/android/app/src/main/AndroidManifest.xml`
- `purl_courier_app/ios/Runner.xcodeproj/project.pbxproj`
- `purl_courier_app/ios/Runner/Info.plist`

---

### App Names in pubspec.yaml

#### POP (Buyer)
```yaml
# purl-stores-app(buyer)/pubspec.yaml
name: pop
description: "POP - Shop from your favorite stores"
```

#### POP Seller
```yaml
# purl-admin-app(seller)/pubspec.yaml
name: pop_seller
description: "POP Seller - Manage your store and sell products"
```

#### POP Rider
```yaml
# purl_courier_app/pubspec.yaml
name: pop_rider
description: "POP Rider - Deliver with POP"
```

---

### Theme Files (All Apps)

Update color schemes in:
- `lib/theme/app_theme.dart` (or similar)
- `lib/theme/colors.dart` (or similar)
- `lib/constants/colors.dart` (or similar)

Example structure:
```dart
class AppColors {
  static const Color primary = Color(0xFF...); // New POP primary
  static const Color secondary = Color(0xFF...); // New POP secondary
  static const Color accent = Color(0xFF...); // New POP accent
  // ... etc
}
```

---

### Asset Files

#### Replace Logo Files
- `assets/images/wibblelogo.png` → `assets/images/pop_logo.png`
- `assets/images/wibble_seller_launcher.png` → `assets/images/pop_seller_logo.png`
- `assets/images/wibble_courier_logo.png` → `assets/images/pop_rider_logo.png`

#### Update Launcher Icons
Run flutter_launcher_icons after updating:
```bash
flutter pub run flutter_launcher_icons
```

---

### Text References

Search and replace in all files:
- "Wibble" → "POP"
- "PURL" → "POP"
- "wibble" → "pop"
- "purl" → "pop"

Exclude:
- Package names (until ready to change)
- Firebase project ID
- Git history

---

### Firebase Configuration

#### Update App Display Names
Firebase Console → Project Settings → Your apps:
- Purl Stores → POP
- Purl Admin → POP Seller
- Purl Courier → POP Rider

#### Download New Config Files
After package name changes:
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)

---

### Splash Screens

Update splash screen assets:
- Background color (new brand color)
- Logo (new POP logo)
- Duration (keep 4 seconds)

Files to update:
- `android/app/src/main/res/drawable/launch_background.xml`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

---

## Implementation Checklist

### Phase 1: Receive Assets
- [ ] Receive color palette
- [ ] Receive logo files
- [ ] Receive app icons
- [ ] Receive typography guidelines

### Phase 2: Update Theme
- [ ] Update color constants in all apps
- [ ] Update theme files
- [ ] Test UI with new colors
- [ ] Verify contrast and accessibility

### Phase 3: Update Assets
- [ ] Replace logo files
- [ ] Update launcher icons
- [ ] Update splash screens
- [ ] Test on devices

### Phase 4: Update Text
- [ ] Search and replace brand names
- [ ] Update app descriptions
- [ ] Update pubspec.yaml names
- [ ] Update README.md

### Phase 5: Update Package Names
- [ ] Update Android package names
- [ ] Update iOS bundle identifiers
- [ ] Update Firebase app configurations
- [ ] Download new google-services.json
- [ ] Download new GoogleService-Info.plist
- [ ] Test builds

### Phase 6: Testing
- [ ] Build all apps
- [ ] Test on Android devices
- [ ] Test on iOS devices
- [ ] Verify branding consistency
- [ ] Check for missed references

---

## Post-Rebranding Tasks

### App Store Listings
- [ ] Update app names
- [ ] Update descriptions
- [ ] Update screenshots
- [ ] Update promotional graphics
- [ ] Update keywords

### Marketing Materials
- [ ] Update website
- [ ] Update social media
- [ ] Update email templates
- [ ] Update support documentation

### Legal
- [ ] Update terms of service
- [ ] Update privacy policy
- [ ] Update app store agreements

---

## Rollback Plan

If issues arise:
1. Keep old assets in `assets/old/` folder
2. Keep old theme files commented out
3. Document all changes in git commits
4. Test thoroughly before final deployment

---

**Status**: Awaiting color palette and logo assets to begin implementation
