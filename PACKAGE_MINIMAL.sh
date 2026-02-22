#!/bin/bash

echo "📦 Creating minimal deployment package..."

# Create temp directory
rm -rf vapi-deploy-minimal
mkdir -p vapi-deploy-minimal

# Copy only essential files
echo "📋 Copying essential files only..."

# Firebase config files
cp .firebaserc vapi-deploy-minimal/
cp firebase.json vapi-deploy-minimal/
cp firestore.indexes.json vapi-deploy-minimal/
cp firestore.rules vapi-deploy-minimal/
cp storage.rules vapi-deploy-minimal/

# Functions folder - NO node_modules
mkdir -p vapi-deploy-minimal/functions
cp functions/package.json vapi-deploy-minimal/functions/
cp functions/package-lock.json vapi-deploy-minimal/functions/
cp functions/tsconfig.json vapi-deploy-minimal/functions/
cp functions/.gitignore vapi-deploy-minimal/functions/

# Copy source code only
cp -r functions/src vapi-deploy-minimal/functions/

# Create deployment script
cat > vapi-deploy-minimal/deploy.sh << 'EOF'
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
EOF

chmod +x vapi-deploy-minimal/deploy.sh

# Create zip
echo "🗜️  Creating zip file..."
cd vapi-deploy-minimal
zip -r ../vapi-minimal.zip . -q
cd ..

echo ""
echo "✅ Minimal deployment package created: vapi-minimal.zip"
echo ""
echo "📤 Upload to GCP Cloud Shell and run:"
echo "   unzip vapi-minimal.zip -d vapi-fix"
echo "   cd vapi-fix"
echo "   bash deploy.sh"
echo ""
du -h vapi-minimal.zip
