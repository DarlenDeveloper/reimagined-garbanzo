# Quick Fix: Google Sign-In for All Apps

## The Problem
All three apps are missing Android OAuth clients needed for Google Sign-In.

## The Solution (5 minutes total)

### Step 1: Go to Google Cloud Console
Open: https://console.cloud.google.com/apis/credentials?project=purlstores-za

### Step 2: Create 3 OAuth Clients

Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"** for each app:

#### OAuth Client 1: Purl Courier
- Application type: **Android**
- Name: `Purl Courier Android`
- Package name: `com.example.purl_courier_app`
- SHA-1: `83:3E:B1:D9:02:FB:F8:6E:E2:95:08:E4:39:21:0B:73:91:27:8D:77`
- Click **CREATE**

#### OAuth Client 2: Purl Stores (Buyer)
- Application type: **Android**
- Name: `Purl Stores Android`
- Package name: `com.purl.stores`
- SHA-1: `83:3E:B1:D9:02:FB:F8:6E:E2:95:08:E4:39:21:0B:73:91:27:8D:77`
- Click **CREATE**

#### OAuth Client 3: Purl Admin (Seller)
- Application type: **Android**
- Name: `Purl Admin Android`
- Package name: `com.purl.admin`
- SHA-1: `83:3E:B1:D9:02:FB:F8:6E:E2:95:08:E4:39:21:0B:73:91:27:8D:77`
- Click **CREATE**

### Step 3: Download Updated Config Files

After creating all 3 OAuth clients, wait 30 seconds, then:

1. Go to Firebase Console: https://console.firebase.google.com/project/purlstores-za/settings/general
2. Download google-services.json for each app:
   - Purl Courier (com.example.purl_courier_app)
   - Purl Stores (com.purl.stores)
   - Purl Admin (com.purl.admin)

### Step 4: Let me know when done
I'll copy the files to the correct locations and test them.

---

## Why This Happened
When you migrated to the new Firebase project, the Android OAuth clients weren't automatically created. Firebase only creates web clients by default. Android clients need the SHA-1 certificate, which must be added manually.
