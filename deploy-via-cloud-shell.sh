#!/bin/bash
# Firebase Cloud Functions Deployment Script for Google Cloud Shell
# Run this script in Google Cloud Shell to deploy functions

set -e  # Exit on error

echo "🚀 Starting Firebase Functions Deployment via Cloud Shell"
echo "=================================================="

# Check if we're in the right directory
if [ ! -d "functions" ]; then
    echo "❌ Error: 'functions' directory not found!"
    echo "Please make sure you're in the project root directory"
    exit 1
fi

# Set Firebase project
echo ""
echo "📋 Setting Firebase project..."
firebase use purlstores

# Navigate to functions directory
echo ""
echo "📦 Installing dependencies..."
cd functions
npm install

# Build TypeScript
echo ""
echo "🔨 Building TypeScript..."
npm run build

# Go back to root
cd ..

# Deploy functions
echo ""
echo "🚀 Deploying Cloud Functions..."
echo "This may take 2-3 minutes..."
firebase deploy --only functions

echo ""
echo "✅ Deployment Complete!"
echo "=================================================="
echo ""
echo "🎉 Your Cloud Functions are now live!"
echo ""
echo "Deployed functions:"
echo "  - onOrderCreated"
echo "  - onMessageSent"
echo "  - onProductStockUpdate"
echo "  - sendBulkNotification"
echo ""
echo "Test by placing an order in the buyer app!"
