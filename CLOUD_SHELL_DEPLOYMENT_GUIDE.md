# 🚀 Deploy Firebase Functions via Google Cloud Shell

## Why This Works:
Your local network is blocking Firebase deployment, but Google Cloud Shell has direct access to Google Cloud APIs. This bypasses all network issues!

---

## 📋 Step-by-Step Instructions:

### Step 1: Open Google Cloud Shell
1. Go to: **https://console.cloud.google.com/**
2. Make sure you're logged in with: **joseph.birungi@najod.co**
3. Click the **terminal icon** (top right corner) to open Cloud Shell
   - Or go directly to: **https://shell.cloud.google.com/**

### Step 2: Upload Your Project Files

**Option A - Upload as ZIP (Easiest):**
1. On your local machine, create a zip of these folders:
   ```bash
   cd ~/Desktop/PURL/reimagined-garbanzo
   zip -r purl-deploy.zip functions/ firebase.json .firebaserc
   ```
2. In Cloud Shell, click **⋮ (three dots)** → **Upload**
3. Upload `purl-deploy.zip`
4. In Cloud Shell, run:
   ```bash
   unzip purl-deploy.zip
   ls -la  # Verify files are there
   ```

**Option B - Use Cloud Shell Editor:**
1. Click **Open Editor** button in Cloud Shell
2. Create folder structure: `functions/src/`
3. Copy-paste file contents from your local machine
4. Make sure you have:
   - `functions/src/index.ts`
   - `functions/package.json`
   - `functions/tsconfig.json`
   - `firebase.json`
   - `.firebaserc`

**Option C - Git Clone (If you have a repo):**
```bash
git clone <your-repo-url>
cd reimagined-garbanzo
```

### Step 3: Run Deployment Script

```bash
# Make script executable
chmod +x deploy-via-cloud-shell.sh

# Run deployment
./deploy-via-cloud-shell.sh
```

**OR run commands manually:**
```bash
# Set project
firebase use purlstores

# Install and build
cd functions
npm install
npm run build
cd ..

# Deploy
firebase deploy --only functions
```

### Step 4: Wait for Deployment
- Takes 2-3 minutes
- You'll see progress messages
- Wait for "✅ Deploy complete!"

### Step 5: Test
1. Open seller app on phone
2. Place order from buyer app
3. Check if notification arrives!

---

## 🔧 Troubleshooting:

### If you get "Firebase not found":
```bash
npm install -g firebase-tools
firebase login --no-localhost
```

### If you get permission errors:
Make sure you're logged in with the correct Google account (joseph.birungi@najod.co)

### If deployment fails:
Check the error message and run:
```bash
firebase deploy --only functions --debug
```

---

## 📦 Files You Need to Upload:

**Required files:**
```
functions/
  ├── src/
  │   └── index.ts
  ├── package.json
  ├── package-lock.json
  ├── tsconfig.json
firebase.json
.firebaserc
```

**Optional (makes it easier):**
```
deploy-via-cloud-shell.sh
```

---

## ✅ What Gets Deployed:

After successful deployment, these Cloud Functions will be live:

1. **onOrderCreated** - Sends notification when new order is placed
2. **onMessageSent** - Sends notification when message is received
3. **onProductStockUpdate** - Sends notification when stock is low
4. **sendBulkNotification** - Allows bulk notifications to customers

All functions are deployed to **africa-south1** region for low latency.

---

## 🎉 Success Indicators:

You'll know it worked when you see:
```
✔  functions[onOrderCreated(africa-south1)] Successful create operation.
✔  functions[onMessageSent(africa-south1)] Successful create operation.
✔  functions[onProductStockUpdate(africa-south1)] Successful create operation.
✔  functions[sendBulkNotification(africa-south1)] Successful create operation.

✔  Deploy complete!
```

Then test by placing an order - seller should get push notification!

---

## 💡 Pro Tips:

- Cloud Shell sessions timeout after 20 minutes of inactivity
- You can download files from Cloud Shell using the menu
- Cloud Shell has 5GB of persistent storage
- You can reconnect anytime and your files will still be there

---

## 🆘 Need Help?

If deployment fails, copy the error message and we'll troubleshoot together!
