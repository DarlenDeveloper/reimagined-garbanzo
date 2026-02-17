#!/bin/bash

echo "🚀 Deploying Buyer App Delivery Fixes"
echo "======================================"
echo ""

# Step 1: Deploy Firestore Indexes
echo "📊 Step 1: Deploying Firestore indexes..."
firebase deploy --only firestore:indexes
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Firestore indexes"
    exit 1
fi
echo "✅ Firestore indexes deployed"
echo ""

# Step 2: Deploy Cloud Functions
echo "☁️  Step 2: Deploying Cloud Functions..."
firebase deploy --only functions:onDeliveryStatusChanged
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Cloud Functions"
    exit 1
fi
echo "✅ Cloud Functions deployed"
echo ""

# Step 3: Instructions for buyer app
echo "📱 Step 3: Rebuild the Buyer App"
echo "================================"
echo ""
echo "Run these commands to rebuild the buyer app:"
echo ""
echo "  cd purl-stores-app\(buyer\)"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter run"
echo ""
echo "⚠️  IMPORTANT: You MUST do 'flutter clean' to clear cached data"
echo "   that's causing the template literal display issue."
echo ""
echo "✅ Backend deployment complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Wait 5-10 minutes for Firestore indexes to build"
echo "   2. Check index status: https://console.firebase.google.com"
echo "   3. Rebuild and test the buyer app"
echo "   4. Verify prices display correctly"
echo "   5. Test order status updates during delivery flow"
echo ""
