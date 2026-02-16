#!/bin/bash

# Script to create Android OAuth clients for all three apps

PROJECT_ID="purlstores-za"
SHA1="83:3E:B1:D9:02:FB:F8:6E:E2:95:08:E4:39:21:0B:73:91:27:8D:77"

echo "Creating OAuth clients for project: $PROJECT_ID"
echo "Using SHA-1: $SHA1"
echo ""

# App 1: Purl Courier
echo "1. Creating OAuth client for Purl Courier..."
gcloud alpha iap oauth-brands create \
  --application_title="Purl Courier" \
  --support_email="josdeveloper@icloud.com" \
  --project=$PROJECT_ID 2>/dev/null || echo "Brand already exists"

# App 2: Purl Stores (Buyer)
echo "2. Creating OAuth client for Purl Stores..."

# App 3: Purl Admin (Seller)
echo "3. Creating OAuth client for Purl Admin..."

echo ""
echo "Note: OAuth clients need to be created via Google Cloud Console UI"
echo "Go to: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo ""
echo "Create 3 OAuth clients with these details:"
echo ""
echo "1. Purl Courier:"
echo "   - Type: Android"
echo "   - Package: com.example.purl_courier_app"
echo "   - SHA-1: $SHA1"
echo ""
echo "2. Purl Stores (Buyer):"
echo "   - Type: Android"
echo "   - Package: com.purl.stores"
echo "   - SHA-1: $SHA1"
echo ""
echo "3. Purl Admin (Seller):"
echo "   - Type: Android"
echo "   - Package: com.purl.admin"
echo "   - SHA-1: $SHA1"
