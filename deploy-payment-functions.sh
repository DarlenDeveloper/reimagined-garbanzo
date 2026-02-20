#!/bin/bash

# Flutterwave Payment Functions Deployment Script (Updated for Direct Charges)
# This script deploys the payment-related Cloud Functions with redirect handling

set -e  # Exit on error

echo "🚀 Deploying Flutterwave Payment Functions (Direct Charges)"
echo "============================================================"
echo ""

# Check if we're in the right directory
if [ ! -d "functions" ]; then
    echo "❌ Error: functions directory not found"
    echo "Please run this script from the project root"
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Error: Not logged in to Firebase"
    echo "Run: firebase login"
    exit 1
fi

echo "📦 Installing dependencies..."
cd functions
npm install
echo "✅ Dependencies installed"
echo ""

echo "🔨 Building TypeScript..."
npm run build
echo "✅ Build complete"
echo ""

echo "🔍 Checking secrets..."
echo "⚠️  Make sure you have set up Secret Manager secrets:"
echo "  - FLUTTERWAVE_SECRET_KEY"
echo "  - FLUTTERWAVE_ENCRYPTION_KEY"
echo ""
read -p "Have you set up the secrets? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Set up secrets with:"
    echo "  firebase functions:secrets:set FLUTTERWAVE_SECRET_KEY"
    echo "  firebase functions:secrets:set FLUTTERWAVE_ENCRYPTION_KEY"
    exit 1
fi
echo ""

echo "🚀 Deploying payment functions..."
firebase deploy --only functions:chargeCard,functions:chargeMobileMoney,functions:verifyFlutterwavePayment

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 What's New:"
echo "  ✓ Card payments with redirect handling for 3DS"
echo "  ✓ Mobile money with verification support"
echo "  ✓ Proper status polling for pending payments"
echo ""
echo "📋 Next steps:"
echo "1. Test card payment with test card (5531886652142950)"
echo "2. Test mobile money payment (MTN/Airtel)"
echo "3. Verify redirect handling works properly"
echo "4. Check payment records in Firestore /payments collection"
echo "5. Monitor logs: firebase functions:log"
echo ""

