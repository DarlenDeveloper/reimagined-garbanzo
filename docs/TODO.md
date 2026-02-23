# Purl Marketplace - TODO & Pending Work

**Last Updated:** February 23, 2026  
**Status:** Pre-Launch Preparation

---

## 🚀 LAUNCH PRIORITIES

### POP AI Shopping Assistant
**Launch Date:** February 27, 2026 at 19:00 EAT  
**Status:** Backend deployed, UI showing countdown

#### Remaining Work:
1. **Keyword Generation System**
   - [ ] Create `generateProductKeywords` Cloud Function
   - [ ] Integrate with product creation flow in seller app
   - [ ] Create backfill script for existing products
   - [ ] Test keyword generation with various product types
   - [ ] Deploy to production

2. **Search Implementation**
   - [ ] Update `aiShoppingAssistant` to use searchKeywords field
   - [ ] Implement semantic matching algorithm
   - [ ] Add conversation context understanding
   - [ ] Test with real user queries
   - [ ] Optimize for performance

3. **UI Finalization**
   - [ ] Remove countdown timer after launch
   - [ ] Enable chat functionality
   - [ ] Test conversation flow
   - [ ] Add loading states
   - [ ] Handle error cases gracefully

4. **Testing**
   - [ ] Test with 100+ products
   - [ ] Test conversation memory
   - [ ] Test edge cases (no results, ambiguous queries)
   - [ ] Performance testing (response time < 2s)
   - [ ] Load testing (100 concurrent users)

**Documentation:** `docs/AI_SHOPPING_ASSISTANT.md`

---

## 🎨 BRANDING & UI CHANGES

### Global Branding
- [ ] Review all color schemes (remove green, use black)
- [ ] Ensure consistent typography (Poppins font)
- [ ] Remove all borders from text inputs
- [ ] Verify logo usage (transparent PNGs, no backgrounds)
- [ ] Check button styles (black, no green)
- [ ] Review spacing and padding across all screens

### Buyer App (purl-stores-app)
- [ ] Home screen branding review
- [ ] Discover screen branding review
- [ ] Product detail screen branding review
- [ ] Store profile screen branding review
- [ ] Cart and checkout screens
- [ ] Profile and settings screens
- [ ] Search functionality UI
- [ ] Filter and sort UI

### Seller App (purl-admin-app)
- [ ] Dashboard branding review
- [ ] Products screen branding review
- [ ] Orders screen branding review
- [ ] Analytics screen branding review
- [ ] Settings screen branding review
- [ ] AI Customer Service screen branding review

### Courier App (purl_courier_app)
- [ ] Full branding review needed
- [ ] Consistent with buyer/seller apps

**Reference:** `docs/REBRANDING_GUIDE.md`

---

## 🐛 KNOWN ISSUES

### Verification Badge Caching
**Status:** Fixed  
**Details:** Verification badges now cache properly with SharedPreferences  
**Files:** `purl-stores-app(buyer)/lib/screens/home_screen.dart`

### Google Sign-In (Buyer App)
**Status:** Fixed  
**Details:** SHA-1 certificate updated in Firebase, google-services.json updated  
**Files:** `purl-stores-app(buyer)/android/app/google-services.json`

### POP AI Response Parsing
**Status:** Fixed  
**Details:** Image URL parsing handles both string and object formats  
**Files:** `purl-stores-app(buyer)/lib/services/ai_shopping_service.dart`

---

## 📱 FEATURE REQUESTS

### High Priority
- [ ] Push notifications for orders
- [ ] In-app messaging between buyer and seller
- [ ] Product reviews and ratings
- [ ] Wishlist functionality
- [ ] Order tracking with real-time updates
- [ ] Multiple payment methods (M-Pesa, card, etc.)

### Medium Priority
- [ ] Social sharing of products
- [ ] Referral program
- [ ] Loyalty points system
- [ ] Flash sales and promotions
- [ ] Product comparison feature
- [ ] Advanced filters (price range, brand, etc.)

### Low Priority
- [ ] Dark mode
- [ ] Multi-language support
- [ ] Voice search
- [ ] AR product preview
- [ ] Live shopping events

---

## 🔧 TECHNICAL DEBT

### Performance
- [ ] Optimize image loading (implement progressive loading)
- [ ] Add pagination to product lists
- [ ] Implement caching strategy for API calls
- [ ] Reduce app bundle size
- [ ] Optimize Firestore queries (add composite indexes)

### Code Quality
- [ ] Add unit tests for services
- [ ] Add widget tests for critical screens
- [ ] Add integration tests for user flows
- [ ] Improve error handling across the app
- [ ] Add logging and monitoring
- [ ] Document all major functions and classes

### Security
- [ ] Implement App Check properly (currently showing warnings)
- [ ] Add rate limiting to Cloud Functions
- [ ] Implement proper input validation
- [ ] Add security rules testing
- [ ] Audit third-party dependencies

### Infrastructure
- [ ] Set up CI/CD pipeline
- [ ] Implement automated testing
- [ ] Set up staging environment
- [ ] Configure monitoring and alerts
- [ ] Implement backup strategy for Firestore

---

## 📊 ANALYTICS & MONITORING

### To Implement
- [ ] User behavior tracking
- [ ] Product view analytics
- [ ] Search query analytics
- [ ] Conversion funnel tracking
- [ ] Error tracking and reporting
- [ ] Performance monitoring
- [ ] Revenue analytics

### Tools to Integrate
- [ ] Firebase Analytics
- [ ] Crashlytics
- [ ] Performance Monitoring
- [ ] Custom dashboards

---

## 📝 DOCUMENTATION NEEDED

### User Documentation
- [ ] Buyer app user guide
- [ ] Seller app user guide
- [ ] Courier app user guide
- [ ] FAQ section
- [ ] Video tutorials

### Developer Documentation
- [ ] API documentation
- [ ] Architecture overview
- [ ] Deployment guide
- [ ] Contributing guidelines
- [ ] Code style guide

### Business Documentation
- [ ] Product roadmap
- [ ] Feature specifications
- [ ] Marketing materials
- [ ] Support documentation

---

## 🚢 DEPLOYMENT CHECKLIST

### Pre-Launch
- [ ] Complete all high-priority features
- [ ] Fix all critical bugs
- [ ] Complete branding review
- [ ] Test on multiple devices
- [ ] Test on different network conditions
- [ ] Security audit
- [ ] Performance testing
- [ ] Load testing

### Launch Day
- [ ] Deploy latest version to production
- [ ] Enable POP AI (remove countdown)
- [ ] Monitor error rates
- [ ] Monitor performance metrics
- [ ] Have support team ready
- [ ] Prepare rollback plan

### Post-Launch
- [ ] Monitor user feedback
- [ ] Track key metrics
- [ ] Address critical issues immediately
- [ ] Plan first update
- [ ] Gather user testimonials

---

## 📅 TIMELINE

### Week 1 (Feb 23-27, 2026)
- Complete POP AI keyword generation
- Complete branding review
- Fix remaining UI issues
- Testing and QA

### Week 2 (Feb 28 - Mar 6, 2026)
- Launch POP AI
- Monitor and fix issues
- Implement high-priority features
- User feedback collection

### Week 3 (Mar 7-13, 2026)
- Address user feedback
- Implement push notifications
- Add in-app messaging
- Performance optimizations

### Month 2 (Mar 14 - Apr 13, 2026)
- Implement reviews and ratings
- Add wishlist functionality
- Improve search and filters
- Marketing push

---

## 🎯 SUCCESS METRICS

### POP AI Launch
- [ ] 80% of searches return relevant results
- [ ] Average response time < 2 seconds
- [ ] 50% of users try POP AI in first week
- [ ] 30% of POP AI searches result in product views

### Overall App
- [ ] 1000+ active users in first month
- [ ] 100+ products listed
- [ ] 50+ successful orders
- [ ] 4.5+ star rating on app stores
- [ ] < 1% crash rate

---

## 📞 CONTACTS & RESOURCES

### Team
- **Product Owner:** [Name]
- **Lead Developer:** [Name]
- **UI/UX Designer:** [Name]
- **QA Lead:** [Name]

### Resources
- **Firebase Console:** https://console.firebase.google.com/project/purlstores-za
- **GCP Console:** https://console.cloud.google.com/
- **Documentation:** `/docs` folder
- **Design Files:** [Link to Figma/Design files]

---

## 📌 NOTES

### Important Decisions
- All Cloud Functions deployed to `africa-south1` region
- Gemini 1.5 Flash used for AI (cost-effective)
- Conversation history stored locally (privacy)
- Keywords generated server-side (consistency)

### Lessons Learned
- Always verify API enablement before deployment
- Test with real data, not placeholders
- Document as you build, not after
- Plan before implementing (avoid rushing)
- Use proper project IDs, not placeholders

---

**Next Review:** February 27, 2026 (Post-Launch)
