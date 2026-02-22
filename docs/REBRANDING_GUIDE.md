# Rebranding Guide: PURL/Wibble → POP

**Target Completion**: Before Launch (This Week)  
**Status**: Awaiting Assets

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

## Required Assets (Awaiting)

### Color Palette
- [ ] Primary color
- [ ] Secondary color
- [ ] Accent color
- [ ] Background colors
- [ ] Text colors
- [ ] Error/success/warning colors
- [ ] Gradient definitions (if any)

### Logo Assets
- [ ] POP main logo (SVG + PNG)
- [ ] POP Seller logo (SVG + PNG)
- [ ] POP Rider logo (SVG + PNG)
- [ ] App icons (1024x1024 for all apps)
- [ ] Splash screen assets
- [ ] In-app branding elements

### Typography
- [ ] Primary font family
- [ ] Secondary font family (if different)
- [ ] Font weights to use

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
