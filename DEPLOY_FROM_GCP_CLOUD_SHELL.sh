#!/bin/bash

# 🚀 VAPI AI Customer Service - GCP Cloud Shell Deployment Script
# This script deploys everything from GCP Cloud Shell where network is stable

set -e  # Exit on error

echo "🎯 Starting VAPI AI Customer Service Deployment"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_ID="purlstores-za"
REGION="africa-south1"

echo -e "${BLUE}📦 Step 1: Extracting deployment package...${NC}"
if [ -f "vapi-deployment.zip" ]; then
    unzip -q vapi-deployment.zip
    cd vapi-deployment
    echo -e "${GREEN}✅ Package extracted${NC}"
else
    echo -e "${RED}❌ Error: vapi-deployment.zip not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔧 Step 2: Setting up Firebase project...${NC}"
firebase use $PROJECT_ID
echo -e "${GREEN}✅ Project set to $PROJECT_ID${NC}"

echo ""
echo -e "${BLUE}🔑 Step 3: Checking secrets...${NC}"
echo "Secrets should already be created:"
echo "  - VAPI_PRIVATE_KEY"
echo "  - VAPI_PUBLIC_KEY"
echo -e "${YELLOW}⚠️  If not created, run:${NC}"
echo "  firebase functions:secrets:set VAPI_PRIVATE_KEY"
echo "  firebase functions:secrets:set VAPI_PUBLIC_KEY"
read -p "Press Enter to continue..."

echo ""
echo -e "${BLUE}📝 Step 4: Creating Firestore configuration...${NC}"
echo "Running setup scripts..."
cd functions
node lib/scripts/setupVapiConfig.js
echo -e "${GREEN}✅ VAPI config created${NC}"

echo ""
echo -e "${BLUE}📞 Step 5: Populating DID pool...${NC}"
node lib/scripts/populateDids.js
echo -e "${GREEN}✅ DIDs populated${NC}"

echo ""
echo -e "${BLUE}🚀 Step 6: Deploying Cloud Functions...${NC}"
cd ..
firebase deploy --only functions --project $PROJECT_ID
echo -e "${GREEN}✅ Functions deployed${NC}"

echo ""
echo -e "${BLUE}📊 Step 7: Deploying Firestore indexes...${NC}"
firebase deploy --only firestore:indexes --project $PROJECT_ID
echo -e "${GREEN}✅ Indexes deployed${NC}"

echo ""
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo "================================================"
echo ""
echo "✅ All 17 Cloud Functions deployed"
echo "✅ Firestore configuration created"
echo "✅ DID pool populated"
echo "✅ Indexes deployed"
echo ""
echo "📋 Next Steps:"
echo "1. Test enableAIService function with a test store"
echo "2. Make a test call to verify webhook"
echo "3. Check call logs in Firestore"
echo "4. Proceed with Flutter integration"
echo ""
echo "🔗 Useful Links:"
echo "  Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo "  Functions: https://console.firebase.google.com/project/$PROJECT_ID/functions"
echo "  Firestore: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo ""
