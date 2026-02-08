#!/bin/bash

echo "🚀 Deploying Cloud Functions to africa-south1 (Johannesburg - Closest to Uganda/Kenya)"
echo ""

# Build TypeScript
echo "📦 Building TypeScript..."
cd "$(dirname "$0")"
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Deploy to Firebase
echo "🌍 Deploying to africa-south1..."
firebase deploy --only functions

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed!"
    exit 1
fi

echo ""
echo "✅ Deployment successful!"
echo ""
echo "📊 Expected latency:"
echo "   Uganda → africa-south1: 50-100ms ✅"
echo "   Kenya → africa-south1: 40-80ms ✅"
echo "   Total notification delivery: 100-200ms 🚀"
echo ""
echo "🔍 View logs with: firebase functions:log"
echo ""
