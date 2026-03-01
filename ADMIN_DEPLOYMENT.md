# Admin Dashboard Deployment

## Setup Separate Firebase Site

Your admin dashboard needs its own Firebase hosting site to avoid conflicts with your main website.

### Option 1: Create New Firebase Site (Recommended)

```bash
# Create a new site for admin dashboard
firebase hosting:sites:create pop-admin

# Apply the target
firebase target:apply hosting admin pop-admin

# Deploy only admin dashboard
firebase deploy --only hosting:admin
```

Your admin will be at: `https://pop-admin.web.app`

### Option 2: Use Subdomain

If you have a custom domain:

```bash
# Create site with custom name
firebase hosting:sites:create admin

# Apply target
firebase target:apply hosting admin admin

# Deploy
firebase deploy --only hosting:admin

# Then in Firebase Console:
# Go to Hosting → admin site → Add custom domain
# Add: admin.yourdomain.com
```

Your admin will be at: `https://admin.yourdomain.com`

## Current Configuration

✅ **Website**: `pop-website` folder → main domain
✅ **Admin Dashboard**: `pop-admin-dashboard/dist` folder → separate site

## Deploy Commands

### Deploy Everything
```bash
firebase deploy
```

### Deploy Only Admin Dashboard
```bash
firebase deploy --only hosting:admin
```

### Deploy Only Website
```bash
firebase deploy --only hosting:website
```

### Deploy Only Firestore Rules
```bash
firebase deploy --only firestore:rules
```

## Build Before Deploy

Always build the admin dashboard first:
```bash
cd pop-admin-dashboard
npm run build
cd ..
firebase deploy --only hosting:admin
```

## No Conflicts!

✅ Website and Admin are completely separate
✅ Different URLs
✅ Different build folders
✅ Can deploy independently
✅ Share same Firebase project (Firestore, Auth, etc.)

## Quick Deploy Script

Create `deploy-admin.sh`:
```bash
#!/bin/bash
cd pop-admin-dashboard
npm run build
cd ..
firebase deploy --only hosting:admin
```

Then run:
```bash
chmod +x deploy-admin.sh
./deploy-admin.sh
```
