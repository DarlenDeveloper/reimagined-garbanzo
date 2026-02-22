#!/bin/bash

# 📝 Manual Firestore Setup Script
# Use this if you want to create Firestore documents manually via gcloud

set -e

PROJECT_ID="purlstores-za"

echo "📝 Creating Firestore documents manually..."
echo ""

# Note: This requires gcloud firestore commands
# Alternatively, use Firebase Console UI

echo "⚠️  This script requires gcloud CLI with Firestore access"
echo ""
echo "To create documents manually:"
echo ""
echo "1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo ""
echo "2. Create collection: 'config'"
echo "   Document ID: 'vapi'"
echo "   Fields:"
echo "   {
     structuredOutputIds: [
       'a356b2a9-fecc-49da-9220-85b5d315e2db',
       '01b9a819-68cb-41d6-b626-4426af1e89bb'
     ],
     sipCredentialId: '25718c8b-4388-4b59-ad0c-e2c7b8ea2147',
     voiceId: 'GDzHdQOi6jjf8zaXhCYD',
     voiceModel: 'eleven_turbo_v2_5',
     llmModel: 'gpt-4o-mini',
     subscriptionPlan: {
       name: 'ai_basic',
       monthlyFee: 20,
       currency: 'USD',
       minutesIncluded: 100,
       costPerMinute: 0.20
     },
     createdAt: [timestamp]
   }"
echo ""
echo "3. Create collection: 'dids'"
echo "   For each phone number, create a document:"
echo "   {
     phoneNumber: '+256205479710',
     assigned: false,
     storeId: null,
     vapiPhoneNumberId: null,
     assignedAt: null,
     createdAt: [timestamp]
   }"
echo ""
