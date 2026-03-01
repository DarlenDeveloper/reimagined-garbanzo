# 🚀 DEPLOYMENT INSTRUCTIONS

## Pre-Deployment Checklist

### 1. Environment Variables
Ensure `.env` file has all required variables:
```env
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_auth_domain
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_storage_bucket
VITE_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
VITE_FIREBASE_APP_ID=your_app_id
VITE_RECAPTCHA_SITE_KEY=your_recaptcha_site_key
```

### 2. Firebase App Check Setup (Firewall)
1. Go to Firebase Console → App Check
2. Register your app with reCAPTCHA v3
3. Get your reCAPTCHA site key
4. Add it to `.env` as `VITE_RECAPTCHA_SITE_KEY`
5. Enable App Check enforcement for Firestore

### 3. Firestore Security Rules
Already configured in `firestore.rules`:
- Requires authentication for all operations
- Admin-only access enforced

## Build & Deploy

### Step 1: Install Dependencies
```bash
cd pop-admin-dashboard
npm install
```

### Step 2: Build for Production
```bash
npm run build
```

### Step 3: Test Build Locally
```bash
npm run preview
```

### Step 4: Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```

Or deploy everything (hosting + firestore rules):
```bash
firebase deploy
```

## Post-Deployment

### 1. Clear Browser Cache
Users need to clear cache once:
```javascript
// In browser console (F12):
localStorage.removeItem('vite-ui-theme')
```
Then refresh (Ctrl+Shift+R)

### 2. Test Admin Login
1. Navigate to deployed URL
2. Login with admin credentials
3. Verify all pages load correctly
4. Test key actions (approve, reject, etc.)

### 3. Enable App Check Enforcement
In Firebase Console:
1. Go to App Check
2. Enable enforcement for:
   - Firestore
   - Authentication
3. Monitor metrics

## Security Features Enabled

✅ **Firebase Authentication** - Admin-only access
✅ **Firestore Security Rules** - Authentication required
✅ **Firebase App Check** - Bot protection (firewall)
✅ **HTTPS Only** - Enforced by Firebase Hosting
✅ **Route Protection** - AuthContext guards all routes

## Monitoring

After deployment, monitor:
- Firebase Console → App Check → Metrics
- Firebase Console → Authentication → Users
- Firebase Console → Firestore → Usage
- Browser console for any errors

## Troubleshooting

### App Check Errors
If you see App Check errors:
1. Verify reCAPTCHA site key is correct
2. Check domain is registered in reCAPTCHA console
3. Ensure App Check is enabled in Firebase Console

### Authentication Issues
1. Check Firebase Auth is enabled
2. Verify admin users exist in `admins` collection
3. Check Firestore rules allow admin access

### Build Errors
```bash
# Clear cache and rebuild
rm -rf node_modules dist
npm install
npm run build
```

## Success Criteria

✅ Build completes without errors
✅ Preview works locally
✅ Deployment succeeds
✅ Admin can login
✅ All pages display data
✅ App Check is active
✅ No console errors

## You're Live! 🎉

Your admin dashboard is now deployed and protected with:
- Authentication
- Firestore security rules
- Firebase App Check (firewall)
- HTTPS encryption

Staff can access at: `https://your-project.web.app`
