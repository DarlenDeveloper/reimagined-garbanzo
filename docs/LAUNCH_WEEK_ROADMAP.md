# Launch Week Roadmap - POP Platform

**Target Launch Date**: This Week (February 2026)  
**Status**: Pre-Production Development

---

## Critical Tasks for Launch

### 1. AI Customer Service Feature ⏳
**Priority**: HIGH  
**Apps**: POP Seller

**Requirements**:
- Integrate AI service (Vapi or similar)
- Auto-respond to common buyer inquiries
- AI-generated response suggestions for sellers
- Context-aware conversation handling
- Premium feature (subscription required)

**Implementation Steps**:
- [ ] Choose AI service provider
- [ ] Set up API integration
- [ ] Create AI service in Flutter
- [ ] Build UI for AI responses
- [ ] Add premium feature gate
- [ ] Test conversation flows

---

### 2. Request Delivery for Unknown Orders ⏳
**Priority**: HIGH  
**Apps**: POP Seller

**Requirements**:
- Sellers can request delivery for orders from buyers not in the system
- Manual order entry (buyer details, items, delivery address)
- Same delivery flow as regular orders
- Notify nearby POP Riders
- Track delivery status

**Implementation Steps**:
- [ ] Create "Manual Order" screen in seller app
- [ ] Add form for buyer details and items
- [ ] Create delivery request from manual order
- [ ] Integrate with existing delivery system
- [ ] Test end-to-end flow

---

### 3. Fix Seller App Discover Screen Bug 🐛
**Priority**: HIGH  
**Apps**: POP Seller

**Issue**: [Need details - what's the bug?]

**Steps**:
- [ ] Identify the bug
- [ ] Reproduce the issue
- [ ] Fix the bug
- [ ] Test thoroughly
- [ ] Verify on multiple devices

---

### 4. Fix Auth Bug 🐛
**Priority**: CRITICAL  
**Apps**: All apps

**Issue**: [Need details - what's the auth bug?]

**Steps**:
- [ ] Identify the auth issue
- [ ] Check Firebase Auth configuration
- [ ] Fix authentication flow
- [ ] Test login/logout/signup
- [ ] Verify session persistence

---

### 5. Remove Card Payments Bug 🐛
**Priority**: HIGH  
**Apps**: POP (Buyer)

**Issue**: [Need details - what's the card payment bug?]

**Options**:
- Fix the bug in card payment flow
- OR Remove card payment option entirely (keep mobile money only)

**Steps**:
- [ ] Identify the card payment issue
- [ ] Decide: Fix or Remove
- [ ] Implement solution
- [ ] Test payment flows
- [ ] Verify with Flutterwave test cards

---

### 6. AI Product Scanner & Remove Search ⏳
**Priority**: HIGH  
**Apps**: POP (Buyer)

**Requirements**:
- AI can scan/analyze all products in the platform
- Buyers use AI to find products (no manual search)
- Natural language queries ("I need red shoes for running")
- AI recommends products based on query
- Remove traditional search bar

**Implementation Steps**:
- [ ] Choose AI/ML service (OpenAI, Google Vision, etc.)
- [ ] Index all products for AI search
- [ ] Build AI query service
- [ ] Create AI chat interface in buyer app
- [ ] Remove search bar from discover screen
- [ ] Add AI assistant button/icon
- [ ] Test various product queries
- [ ] Handle edge cases (no results, unclear queries)

---

### 7. Rebrand to POP 🎨
**Priority**: CRITICAL  
**Apps**: All apps

**Requirements**:
- Update app names (POP, POP Seller, POP Rider)
- Apply new color palette (to be provided)
- Update logos and branding assets
- Update splash screens
- Update app icons
- Update all text references

**Implementation Steps**:
- [ ] Receive new color palette
- [ ] Receive new logo assets
- [ ] Update theme files in all apps
- [ ] Replace Wibble/PURL references with POP
- [ ] Update app names in pubspec.yaml
- [ ] Update launcher icons
- [ ] Update splash screens
- [ ] Update Firebase project display name
- [ ] Test UI consistency across all screens

**Files to Update**:
- `purl-admin-app(seller)/pubspec.yaml` → name: "pop_seller"
- `purl-stores-app(buyer)/pubspec.yaml` → name: "pop"
- `purl_courier_app/pubspec.yaml` → name: "pop_rider"
- Theme files in all apps
- Asset files (logos, icons)
- README.md

---

### 8. Update Package Names 📦
**Priority**: HIGH (Before Deployment)  
**Apps**: All apps

**Current**:
- Seller: `com.purl.admin`
- Buyer: `com.purl.stores`
- Courier: `com.example.purl_courier_app`

**New**:
- Seller: `com.pop.seller`
- Buyer: `com.pop.app`
- Courier: `com.pop.rider`

**Implementation Steps**:
- [ ] Update Android package names
- [ ] Update iOS bundle identifiers
- [ ] Update Firebase app configurations
- [ ] Update google-services.json files
- [ ] Update GoogleService-Info.plist files
- [ ] Rebuild and test all apps

---

### 9. Final Testing & QA ✅
**Priority**: CRITICAL  
**Apps**: All apps

**Test Scenarios**:
- [ ] Complete user flows (signup → purchase → delivery)
- [ ] Payment processing (mobile money)
- [ ] Delivery coordination (seller → rider → buyer)
- [ ] Messaging between all parties
- [ ] Push notifications
- [ ] AI features (customer service, product scanner)
- [ ] Order management
- [ ] Inventory updates
- [ ] Multi-device testing
- [ ] Network failure scenarios
- [ ] Edge cases and error handling

---

### 10. Production Deployment 🚀
**Priority**: CRITICAL  
**Apps**: All apps

**Pre-Deployment Checklist**:
- [ ] All bugs fixed
- [ ] All features implemented
- [ ] Branding updated to POP
- [ ] Package names updated
- [ ] Firebase project configured
- [ ] Flutterwave live keys configured
- [ ] Google Maps API keys configured
- [ ] Cloud Functions deployed
- [ ] Firestore indexes built
- [ ] Security rules reviewed
- [ ] Privacy policy and terms updated
- [ ] App store assets prepared
- [ ] Release notes written

**Deployment Steps**:
- [ ] Build release APKs/IPAs
- [ ] Test release builds
- [ ] Submit to Google Play Store
- [ ] Submit to Apple App Store
- [ ] Monitor for crashes/errors
- [ ] Prepare customer support

---

## Known Issues to Address

### Seller App
1. **Discover Screen Bug** - [Details needed]

### Buyer App
1. **Card Payment Bug** - [Details needed]

### All Apps
1. **Auth Bug** - [Details needed]

---

## Dependencies & Blockers

### Waiting On:
- [ ] New POP color palette
- [ ] New POP logo assets
- [ ] AI service provider decision
- [ ] Bug details for issues #3, #4, #5

### External Services:
- Flutterwave (live keys needed)
- Google Maps API (production keys)
- AI service API keys
- Firebase production configuration

---

## Timeline Estimate

**Day 1-2**:
- Fix critical bugs (auth, card payment, discover screen)
- Implement AI customer service
- Implement manual order delivery request

**Day 3-4**:
- Implement AI product scanner
- Remove search functionality
- Rebrand to POP (colors, logos, names)

**Day 5**:
- Update package names
- Final testing and QA
- Build release versions

**Day 6-7**:
- Deploy to production
- Submit to app stores
- Monitor and support

---

## Post-Launch Priorities

1. Monitor crash reports and errors
2. Gather user feedback
3. Fix critical bugs immediately
4. Plan feature enhancements
5. Scale infrastructure as needed

---

## Contact & Support

**Development Team**: [Your team details]  
**Firebase Project**: purlstores-za  
**Region**: africa-south1

---

**Last Updated**: February 22, 2026  
**Next Review**: Daily during launch week
