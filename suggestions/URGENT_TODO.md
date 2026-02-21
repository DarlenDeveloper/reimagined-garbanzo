# 🚨 URGENT TODO - NOTIFICATION PERMISSION & BACKGROUND TASKS

## ✅ COMPLETED:
- ✅ Cloud Functions deployed and working
- ✅ Order notifications working with correct currency
- ✅ Message notifications working both ways (buyer ↔ seller)
- ✅ Notifications saved to Firestore
- ✅ Multiple device support (FCM token arrays)
- ✅ Professional time format (4m ago, 3hr ago, Mon, Tue, 5/01/26)
- ✅ Post images load with placeholder
- ✅ Custom notification sound added to both apps
- ✅ Share button disabled
- ✅ Logo fixed in buyer app

---

## 🚨 CRITICAL FIXES NEEDED:

### 1. Fix Notification Permission Timing (HIGH PRIORITY)
**Problem:** 
- Notification permission is requested BEFORE user logs in
- FCM token is obtained but can't be saved (no userId yet)
- After login, push notifications don't work until app is reinstalled

**Solution:**
- Move notification permission request to AFTER successful login
- Initialize NotificationService only after user is authenticated
- Request permission on first login or in onboarding flow

**Files to modify:**
- `purl-admin-app(seller)/lib/main.dart` - Remove early notification init
- `purl-stores-app(buyer)/lib/main.dart` - Remove early notification init
- Add permission request after login in auth flow

**Implementation:**
```dart
// After successful login:
await NotificationService().initialize();
await NotificationService().requestPermission();
```

---

### 2. Make Notification Service a Background Task (HIGH PRIORITY)
**Problem:**
- Notification service runs on main thread
- Can block UI during token refresh or permission requests
- Not optimal for production apps

**Solution:**
- Move FCM token operations to background isolate
- Use `compute()` for heavy operations
- Implement proper async/await patterns
- Add retry logic for failed token saves

**Benefits:**
- Smoother UI experience
- Better battery life
- More reliable token management
- Handles network failures gracefully

**Files to modify:**
- `purl-admin-app(seller)/lib/services/notification_service.dart`
- `purl-stores-app(buyer)/lib/services/notification_service.dart`

**Implementation approach:**
```dart
// Use background isolate for token operations
Future<void> _saveFCMTokenInBackground(String token) async {
  await compute(_saveTokenToFirestore, {
    'token': token,
    'userId': userId,
  });
}
```

---

## 📝 ADDITIONAL IMPROVEMENTS:

### 3. Add Token Refresh on App Resume
- Listen to app lifecycle changes
- Refresh FCM token when app comes to foreground
- Ensure token is always up-to-date

### 4. Add Error Handling & Retry Logic
- Retry failed token saves (3 attempts with exponential backoff)
- Log errors to Firebase Crashlytics
- Show user-friendly error messages

### 5. Add Token Cleanup on Logout
- Remove FCM token from Firestore array on logout
- Delete local token from device
- Prevent notifications to logged-out users

---

## 🎯 PRIORITY ORDER:

1. **CRITICAL:** Fix notification permission timing (blocks production use)
2. **HIGH:** Make notification service background task (performance)
3. **MEDIUM:** Add token refresh on app resume (reliability)
4. **LOW:** Add error handling & retry logic (polish)
5. **LOW:** Add token cleanup on logout (security)

---

## 🚀 WHEN TO IMPLEMENT:

**Before Next Release:**
- Fix notification permission timing (Issue #1)
- Make notification service background task (Issue #2)

**Before Public Launch:**
- All remaining improvements
- Add Firebase App Check
- Add comprehensive error logging

---

## 📌 NOTES:

- Current workaround: Users must clear app data and login again
- This affects ALL new users on first install
- Must be fixed before marketing/scaling
- Background tasks will improve battery life significantly
