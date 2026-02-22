#!/bin/bash

# 📦 Package everything for GCP Cloud Shell deployment

echo "📦 Creating deployment package..."
echo ""

# Create deployment directory
rm -rf vapi-deployment
mkdir -p vapi-deployment

# Copy necessary files
echo "📋 Copying files..."
cp -r functions vapi-deployment/
cp firebase.json vapi-deployment/
cp .firebaserc vapi-deployment/
cp firestore.indexes.json vapi-deployment/
cp firestore.rules vapi-deployment/
cp storage.rules vapi-deployment/
cp DEPLOY_FROM_GCP_CLOUD_SHELL.sh vapi-deployment/
cp MANUAL_FIRESTORE_SETUP.sh vapi-deployment/

# Copy documentation
mkdir -p vapi-deployment/docs
cp docs/VAPI_*.md vapi-deployment/docs/
cp docs/MANUAL_SETUP_GUIDE.md vapi-deployment/docs/

# Create README for the package
cat > vapi-deployment/README.md << 'EOF'
# VAPI AI Customer Service - Deployment Package

## 🚀 Quick Start (GCP Cloud Shell)

1. Upload this zip file to GCP Cloud Shell
2. Extract: `unzip vapi-deployment.zip`
3. Run: `bash DEPLOY_FROM_GCP_CLOUD_SHELL.sh`

## 📋 What's Included

- All Cloud Functions code (compiled)
- Firebase configuration files
- Firestore indexes
- Setup scripts
- Documentation

## 🔑 Prerequisites

- VAPI secrets already created in Firebase Secret Manager:
  - VAPI_PRIVATE_KEY
  - VAPI_PUBLIC_KEY

## 📚 Documentation

See `docs/` folder for:
- VAPI_IMPLEMENTATION_STATUS.md - Current status
- VAPI_CREDENTIALS.md - API keys and config
- MANUAL_SETUP_GUIDE.md - Manual setup instructions
- VAPI_SUBSCRIPTION_LIFECYCLE.md - How subscriptions work

## 🆘 Troubleshooting

If deployment fails:
1. Check you're logged in: `firebase login`
2. Check project: `firebase use purlstores-za`
3. Try manual setup: `bash MANUAL_FIRESTORE_SETUP.sh`

## ✅ After Deployment

1. Verify functions in Firebase Console
2. Test enableAIService with a test store
3. Make a test call
4. Check call logs in Firestore
EOF

# Create zip file
echo "🗜️  Creating zip file..."
zip -r vapi-deployment.zip vapi-deployment -q

# Cleanup
rm -rf vapi-deployment

echo ""
echo "✅ Deployment package created: vapi-deployment.zip"
echo ""
echo "📤 Upload Instructions:"
echo "1. Go to: https://console.cloud.google.com/cloudshell"
echo "2. Click 'Upload File' (⋮ menu → Upload)"
echo "3. Select vapi-deployment.zip"
echo "4. Run: unzip vapi-deployment.zip"
echo "5. Run: cd vapi-deployment"
echo "6. Run: bash DEPLOY_FROM_GCP_CLOUD_SHELL.sh"
echo ""
echo "📦 Package size:"
du -h vapi-deployment.zip
echo ""
