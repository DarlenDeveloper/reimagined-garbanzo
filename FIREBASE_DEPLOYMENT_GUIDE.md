# Firebase Deployment Guide - Moving from Test Mode to Production

## 🚨 Current Situation
You received an email from Firebase stating that your Firestore database is in **Test Mode** and will stop accepting requests in 2 days. This is because test mode allows unrestricted access to your database, which is insecure for production apps.

## ✅ What We've Built
Your app has the following Firebase integrations:

### Buyer App (purl-stores-app)
- **Authentication**: Email/password, Google Sign-In
- **Product Discovery**: Browse products from all stores
- **Shopping Cart**: Add items, manage quantities
- **Orders**: Create orders with markup pricing
- **Social Features**: Posts, stories, messages, followers
- **Wishlist**: Save favorite products

### Seller App (purl-admin-app)
- **Authentication**: Email/password, Google Sign-In
- **Store Management**: Create and manage stores
- **RBAC**: Invite runners with 4-digit codes
- **Product Management**: Full CRUD operations
- **Inventory Tracking**: Stock management
- **Order Management**: View and process orders

## 📋 Next Steps

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Initialize Firebase in Your Project
Navigate to your project root directory and run:
```bash
firebase init firestore
```

When prompted:
- Select your existing Firebase project: **purlstores**
- Accept the default `firestore.rules` file (we've already created it)
- Accept the default `firestore.indexes.json` file

### Step 4: Deploy Security Rules
```bash
firebase deploy --only firestore:rules
```

This will upload the `firestore.rules` file to your Firebase project and replace the test mode rules.

### Step 5: Verify Deployment
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **purlstores** project
3. Navigate to **Firestore Database** → **Rules**
4. Verify that the rules match the content of your `firestore.rules` file
5. Check that the rules are published and active

## 🔒 Security Rules Overview

The deployed rules provide:

### Store Access Control
- **Public Read**: Anyone can browse stores and products (needed for buyer app)
- **Authenticated Write**: Only authorized users can modify store data
- **RBAC**: Store owners and runners have access via `authorizedUsers` array

### User Data Protection
- **Private**: Users can only access their own cart, orders, and wishlist
- **Isolated**: No user can read another user's private data

### Order Security
- **Buyers**: Can create orders for themselves
- **Sellers**: Can view and update orders for their stores
- **Immutable**: Orders cannot be deleted (preserve history)

### Social Features
- **Public Read**: Posts and stories are publicly visible
- **Owner Control**: Only creators can edit/delete their content
- **Authenticated Actions**: Must be logged in to post, comment, like

## 🧪 Testing After Deployment

### Test 1: Buyer App
1. Open the buyer app
2. Browse products (should work - public read)
3. Sign in with a test account
4. Add items to cart (should work - authenticated user)
5. Create an order (should work - user owns the order)

### Test 2: Seller App
1. Open the seller app
2. Sign in with a store owner account
3. View your products (should work - authorized user)
4. Try to edit another store's products (should fail - not authorized)
5. Create a new product (should work - authorized user)

### Test 3: Security
1. Try to access Firestore directly without authentication (should fail)
2. Try to read another user's cart (should fail)
3. Try to delete an order (should fail - orders are immutable)

## 📊 Firestore Indexes

Some queries in your app may require composite indexes. If you see errors like:
```
The query requires an index
```

Firebase will provide a link to create the index automatically. Click the link and wait for the index to build (usually 1-5 minutes).

Common indexes you might need:
- `stores/{storeId}/products`: `isActive` + `createdAt`
- `stores/{storeId}/orders`: `userId` + `createdAt`
- Collection group `products`: `isActive` + `categoryId` + `createdAt`

## 🚀 Production Checklist

- [ ] Deploy Firestore security rules
- [ ] Test buyer app functionality
- [ ] Test seller app functionality
- [ ] Verify authentication works
- [ ] Create necessary Firestore indexes
- [ ] Monitor Firebase Console for errors
- [ ] Set up Firebase billing (if needed for scale)
- [ ] Enable Firebase App Check (optional, for additional security)

## 💡 Important Notes

1. **Test Mode vs Production**: Test mode allows all reads/writes. Production rules enforce authentication and authorization.

2. **Breaking Changes**: After deploying rules, any unauthenticated requests will fail. Make sure users are signed in before accessing protected data.

3. **Indexes**: Some queries may fail until you create the required indexes. Firebase will tell you which ones are needed.

4. **Monitoring**: Check Firebase Console → Firestore → Usage tab to monitor requests and errors.

5. **Backup**: Your data is safe. Deploying rules doesn't affect existing data, only access permissions.

## 🆘 Troubleshooting

### "Permission Denied" Errors
- Check that the user is authenticated (`firebase.auth().currentUser`)
- Verify the user has access to the resource (e.g., in `authorizedUsers` array)
- Check Firebase Console → Firestore → Rules for syntax errors

### "Index Required" Errors
- Click the link in the error message to create the index
- Wait 1-5 minutes for the index to build
- Retry the query

### Rules Not Updating
- Run `firebase deploy --only firestore:rules` again
- Check Firebase Console to verify the rules are published
- Clear app cache and restart

## 📞 Need Help?
If you encounter issues:
1. Check Firebase Console → Firestore → Rules for errors
2. Review the error messages in your app logs
3. Test with Firebase Emulator Suite for local debugging
4. Ask me for help with specific error messages

---

**Remember**: You have 2 days to deploy these rules before Firebase blocks all requests to your database. Deploy as soon as possible!
