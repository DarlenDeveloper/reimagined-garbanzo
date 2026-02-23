# POP AI Shopping Assistant

## Overview
POP AI is an intelligent shopping assistant that helps buyers find products through natural conversation. It uses AI to understand user intent, generate semantic search keywords, and provide personalized product recommendations.

## Architecture

### Components

1. **Frontend (Flutter)**
   - `ai_shopping_assistant_screen.dart` - Chat UI
   - `ai_shopping_service.dart` - API client with conversation memory

2. **Backend (Cloud Functions)**
   - `aiShoppingAssistant` - Main AI endpoint (africa-south1)
   - Uses Gemini 1.5 Flash via Vertex AI

3. **Database (Firestore)**
   - Products stored at: `/stores/{storeId}/products/{productId}`
   - AI-generated keywords stored in product documents

## Product Data Model

### Core Fields
```typescript
{
  id: string
  storeId: string
  name: string
  description: string
  price: number
  currency: string
  
  // Category hierarchy
  categoryId: string        // e.g., 'apparel'
  subcategoryId: string      // e.g., 'clothing'
  productTypeId: string      // e.g., 'tshirts'
  categoryPath: string       // e.g., 'apparel/clothing/tshirts'
  condition: string          // 'New', 'Used', 'Refurbished'
  
  // Dynamic attributes
  specs: {
    brand?: string
    size?: string | string[]
    color?: string | string[]
    // ... category-specific attributes
  }
  
  // Search (AI-generated)
  searchKeywords: string[]   // Semantic keywords for AI search
  tags: string[]             // Manual tags
  
  // Media
  images: ProductImage[]
  
  // Inventory
  stock: number
  isActive: boolean
  isPublished: boolean
}
```

## AI Keyword Generation

### Purpose
Generate comprehensive search keywords that enable semantic search. Users can describe what they want naturally, and the AI matches it to products.

### Example
**Product:** "Nike Dri-FIT Men's Running Shorts - Black"

**AI-Generated Keywords:**
```json
[
  // Product type variations
  "shorts", "running shorts", "athletic shorts", "sport shorts",
  "gym shorts", "workout shorts", "training shorts",
  
  // Brand
  "nike", "nike shorts", "dri-fit", "dri fit",
  
  // Gender
  "mens", "men", "male", "guys",
  
  // Activity
  "running", "jogging", "fitness", "exercise", "training",
  "gym", "workout", "athletic", "sport", "active",
  
  // Style/Features
  "athletic wear", "activewear", "sportswear", "performance",
  "moisture wicking", "breathable", "lightweight",
  
  // Color
  "black", "dark",
  
  // Category
  "apparel", "clothing", "bottoms", "pants"
]
```

### Keyword Generation Prompt
```
Generate comprehensive search keywords for this product.
Include:
- Product type variations (formal and casual terms)
- Brand name and variations
- Gender/demographic terms
- Activity/use case keywords
- Style and feature descriptors
- Color variations
- Category and subcategory terms
- Common misspellings and abbreviations
- Related search terms users might use

Product: {name}
Description: {description}
Category: {categoryPath}
Specs: {specs}

Return 30-50 keywords as a JSON array.
```

## Search Flow

### 1. User Query
User: "I need black running shorts for men"

### 2. AI Understanding
```typescript
{
  intent: "product_search",
  keywords: ["black", "running", "shorts", "men", "mens"],
  filters: {
    category: "apparel",
    gender: "men",
    color: "black",
    activity: "running"
  }
}
```

### 3. Firestore Query
```typescript
// Query products where searchKeywords array contains any of the user keywords
db.collectionGroup('products')
  .where('isActive', '==', true)
  .where('searchKeywords', 'array-contains-any', ['running', 'shorts', 'mens'])
  .limit(20)
```

### 4. AI Ranking
- Score products based on keyword matches
- Consider price preferences from conversation
- Prioritize verified sellers
- Return top 10 results

### 5. Conversational Response
AI: "I found 8 running shorts for men! 🏃 They range from R250 to R850, with some great options from verified sellers."

## Conversation Memory

### Storage
- Stored locally on device (not in Firestore)
- Last 20 messages (10 exchanges) kept in memory
- Cleared when user closes the chat

### Structure
```typescript
{
  role: 'user' | 'assistant',
  content: string
}
```

### Context Understanding
```
User: "Show me running shoes"
AI: "I found 15 running shoes..."

User: "What about cheaper ones?"
AI: [understands "cheaper ones" refers to running shoes from context]

User: "Do you have them in blue?"
AI: [understands "them" = running shoes, adds color filter]
```

## Implementation Plan

### Phase 1: Keyword Generation System
1. Create Cloud Function: `generateProductKeywords`
2. Integrate with product creation flow in seller app
3. Create backfill script for existing products

### Phase 2: Search Implementation
1. Update `aiShoppingAssistant` function to use keywords
2. Implement semantic matching algorithm
3. Add conversation context understanding

### Phase 3: Ranking & Personalization
1. Score products based on keyword relevance
2. Consider user preferences (price, brand, etc.)
3. Learn from user interactions

## API Endpoints

### Generate Keywords
```typescript
// Cloud Function: generateProductKeywords
POST /generateProductKeywords
{
  productId: string
  storeId: string
  name: string
  description: string
  categoryPath: string
  specs: object
}

Response:
{
  keywords: string[]  // 30-50 AI-generated keywords
}
```

### Search Products
```typescript
// Cloud Function: aiShoppingAssistant
POST /aiShoppingAssistant
{
  query: string
  conversationHistory: Message[]
  userId?: string
}

Response:
{
  success: boolean
  response: string  // AI-generated conversational response
  products: Product[]  // Top 10 matching products
  searchParams: object  // Extracted search parameters
}
```

## Backfill Script

### Purpose
Generate keywords for all existing products in the database.

### Usage
```bash
# Deploy the function
cd functions
npm run build
gcloud functions deploy generateProductKeywords \
  --gen2 \
  --runtime=nodejs20 \
  --region=africa-south1 \
  --entry-point=generateProductKeywords \
  --trigger-http \
  --allow-unauthenticated

# Run the backfill script
node scripts/backfillProductKeywords.js
```

### Process
1. Fetch all products from all stores
2. For each product:
   - Call `generateProductKeywords` function
   - Update product document with keywords
   - Add to `searchKeywords` array field
3. Progress tracking and error handling
4. Rate limiting to avoid quota issues

## Cost Estimation

### Gemini API (Vertex AI)
- **Free tier:** 2M tokens/month
- **Paid:** $0.075 per 1M input tokens
- **Average query:** ~500 tokens (input + output)
- **Cost per 1000 queries:** ~$0.04

### Keyword Generation
- **One-time cost:** Generate keywords for existing products
- **Ongoing:** Generate keywords when products are created/updated
- **Average:** ~300 tokens per product
- **10,000 products:** ~$0.23

### Monthly Estimates (1000 active users)
- 10 searches per user = 10,000 searches
- Cost: ~$0.40/month
- Well within free tier

## Security

### API Access
- Cloud Functions use service account authentication
- No API keys exposed to client
- Rate limiting on function calls

### Data Privacy
- Conversation history stored locally (not in Firestore)
- No PII sent to Gemini
- Product data only (names, descriptions, specs)

## Future Enhancements

1. **Visual Search** - Upload image to find similar products
2. **Voice Search** - Speak your query
3. **Personalization** - Learn user preferences over time
4. **Price Alerts** - Notify when products match criteria
5. **Comparison** - Compare multiple products side-by-side
6. **Reviews Integration** - Include review sentiment in ranking

## Status

**Current:** Coming Soon (UI hidden)
**Next:** Implement keyword generation system
**Timeline:** 2-3 weeks for full implementation
