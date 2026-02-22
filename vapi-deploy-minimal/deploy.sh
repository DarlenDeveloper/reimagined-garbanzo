#!/bin/bash
echo "🚀 Deploying VAPI Webhook Fix"
echo "=============================="
echo ""
echo "📦 Installing dependencies..."
cd functions
npm install
echo ""
echo "🔨 Building TypeScript..."
npm run build
cd ..
echo ""
echo "🚀 Deploying webhook function..."
firebase deploy --only functions:vapiWebhook --force
echo ""
echo "✅ Deployment complete!"
