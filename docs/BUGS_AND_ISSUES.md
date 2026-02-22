# Bugs and Issues - POP Platform

**Last Updated**: February 22, 2026  
**Status**: Pre-Launch Bug Tracking

---

## Critical Issues (Must Fix Before Launch)

### 🔴 Issue #1: Auth Bug
**Priority**: CRITICAL  
**Affected Apps**: All apps  
**Status**: ⏳ Pending Investigation

**Description**:
[Details needed - what is the auth bug?]

**Steps to Reproduce**:
1. [To be documented]

**Expected Behavior**:
[To be documented]

**Actual Behavior**:
[To be documented]

**Possible Causes**:
- Firebase Auth configuration issue
- Token refresh problem
- Session persistence issue
- Google Sign-In configuration

**Action Items**:
- [ ] Document exact bug behavior
- [ ] Reproduce consistently
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Test across all apps
- [ ] Verify on multiple devices

---

### 🔴 Issue #2: Card Payment Bug
**Priority**: HIGH  
**Affected Apps**: POP (Buyer)  
**Status**: ⏳ Pending Investigation

**Description**:
[Details needed - what is the card payment bug?]

**Steps to Reproduce**:
1. [To be documented]

**Expected Behavior**:
Card payment should process successfully through Flutterwave

**Actual Behavior**:
[To be documented]

**Possible Causes**:
- Flutterwave API integration issue
- 3DES encryption problem
- Redirect URL handling
- Payment verification failure
- Secret keys not configured

**Decision Required**:
- Option A: Fix the card payment bug
- Option B: Remove card payment option (keep mobile money only)

**Action Items**:
- [ ] Document exact bug behavior
- [ ] Check Flutterwave logs
- [ ] Test with Flutterwave test cards
- [ ] Verify Secret Manager keys
- [ ] Decide: Fix or Remove
- [ ] Implement solution
- [ ] Test thoroughly

---

### 🔴 Issue #3: Seller App Discover Screen Bug
**Priority**: HIGH  
**Affected Apps**: POP Seller  
**Status**: ⏳ Pending Investigation

**Description**:
[Details needed - what is the discover screen bug?]

**Steps to Reproduce**:
1. [To be documented]

**Expected Behavior**:
[To be documented]

**Actual Behavior**:
[To be documented]

**Possible Causes**:
- Data loading issue
- UI rendering problem
- Firestore query error
- State management issue

**Action Items**:
- [ ] Document exact bug behavior
- [ ] Reproduce consistently
- [ ] Check console logs
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Test thoroughly

---

## Resolved Issues

### ✅ Issue: Notification Permission Timing
**Status**: ✅ Resolved  
**Resolution**: Moved notification permission request to after login

### ✅ Issue: Wishlist Showing Dummy Data
**Status**: ✅ Resolved  
**Resolution**: Connected to real Firestore data with optimistic updates

### ✅ Issue: Message Routing to Dummy Screens
**Status**: ✅ Resolved  
**Resolution**: Implemented real-time messaging service

### ✅ Issue: Product Specifications Formatting
**Status**: ✅ Resolved  
**Resolution**: Added proper date, weight, and boolean formatting

### ✅ Issue: Home Feed Logo Showing "G"
**Status**: ✅ Resolved  
**Resolution**: Replaced with PURL logo (will update to POP)

### ✅ Issue: Post Images Too Large
**Status**: ✅ Resolved  
**Resolution**: Added maxHeight: 400px constraint

---

## Known Limitations

### Mobile Money Only
- Currently only MTN and Airtel mobile money supported
- Card payments may be removed if bug not fixed

### Delivery Radius
- Courier notifications limited to 2km radius
- May need adjustment based on real-world usage

### AI Features
- Not yet implemented (in progress this week)

---

## Testing Checklist

### Authentication Testing
- [ ] Email/password signup
- [ ] Email/password login
- [ ] Google Sign-In
- [ ] Phone authentication
- [ ] Password reset
- [ ] Session persistence
- [ ] Logout functionality
- [ ] Multi-device login

### Payment Testing
- [ ] Mobile money (MTN)
- [ ] Mobile money (Airtel)
- [ ] Card payment (if keeping)
- [ ] Payment verification
- [ ] Order creation after payment
- [ ] Payment failure handling
- [ ] Refund processing

### Delivery Testing
- [ ] Self-delivery option
- [ ] Request POP Rider
- [ ] Courier notification (2km radius)
- [ ] Courier acceptance
- [ ] Delivery tracking
- [ ] Delivery completion
- [ ] Photo proof upload
- [ ] Status synchronization

### Messaging Testing
- [ ] Buyer to seller messages
- [ ] Seller to buyer messages
- [ ] Real-time updates
- [ ] Offline message persistence
- [ ] Push notifications
- [ ] Unread count badges

### Order Flow Testing
- [ ] Add to cart
- [ ] Update cart quantities
- [ ] Checkout process
- [ ] Order creation
- [ ] Order status updates
- [ ] Order history
- [ ] Order tracking

### Inventory Testing
- [ ] Stock updates on order
- [ ] Low-stock alerts
- [ ] Out-of-stock display
- [ ] Inventory tracking

---

## Bug Reporting Template

When reporting new bugs, please include:

```markdown
### Bug Title
**Priority**: [CRITICAL/HIGH/MEDIUM/LOW]
**Affected Apps**: [POP/POP Seller/POP Rider]
**Status**: [New/In Progress/Fixed/Closed]

**Description**:
Clear description of the bug

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**:
What should happen

**Actual Behavior**:
What actually happens

**Screenshots/Logs**:
[Attach if available]

**Device Info**:
- Device: [e.g., Samsung Galaxy S21]
- OS: [e.g., Android 12]
- App Version: [e.g., 1.0.0]

**Additional Context**:
Any other relevant information
```

---

## Next Steps

1. **Document all three critical bugs** with full details
2. **Prioritize fixes** based on launch timeline
3. **Assign developers** to each bug
4. **Set deadlines** for each fix
5. **Test thoroughly** after fixes
6. **Verify on multiple devices** and OS versions

---

**For urgent bugs, contact the development team immediately.**
