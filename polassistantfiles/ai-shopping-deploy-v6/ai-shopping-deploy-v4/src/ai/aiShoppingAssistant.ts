import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { VertexAI } from '@google-cloud/vertexai';

const db = admin.firestore();

// Initialize Vertex AI (use us-central1 as it's widely available)
const vertexAI = new VertexAI({
  project: process.env.GCLOUD_PROJECT || 'your-project-id',
  location: 'us-central1',
});

const model = vertexAI.getGenerativeModel({
  model: 'gemini-1.5-flash',
});

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

interface SearchParams {
  category?: string;
  priceMin?: number;
  priceMax?: number;
  keywords?: string[];
  color?: string;
  brand?: string;
}

interface Product {
  id: string;
  storeId: string;
  name: string;
  price: number;
  currency: string;
  imageUrl?: string;
  storeName?: string;
  storeLogoUrl?: string;
  verificationStatus?: string;
}

// Deploy to africa-south1
export const aiShoppingAssistant = functions
  .region('africa-south1')
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB',
  })
  .https.onCall(async (data, context) => {
  try {
    const { query, conversationHistory = [], userId } = data;

    if (!query || typeof query !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'Query is required');
    }

    console.log('🤖 POP AI Query:', query);
    console.log('📜 Conversation history:', conversationHistory.length, 'messages');

    // Get user's first name for personalized responses
    let userName = '';
    if (userId) {
      try {
        const userDoc = await db.collection('users').doc(userId).get();
        userName = userDoc.data()?.firstName || '';
      } catch (e) {
        console.log('Could not fetch user name');
      }
    }

    // Step 1: Decide if this needs product search or just conversation
    const needsSearch = await shouldSearchProducts(query, conversationHistory);
    console.log('🔍 Needs product search:', needsSearch);

    let products: Product[] = [];
    let searchParams: SearchParams = {};

    if (needsSearch) {
      // Extract search parameters using AI
      searchParams = await extractSearchParams(query, conversationHistory);
      console.log('📊 Search params:', searchParams);
      
      products = await searchProducts(searchParams);
      console.log(`✅ Found ${products.length} products`);
    }

    // Step 2: Generate conversational AI response with context
    const response = await generateConversationalResponse(
      query,
      conversationHistory,
      products,
      searchParams,
      userName
    );
    console.log('💬 Generated response');

    return {
      success: true,
      response,
      products: products.slice(0, 10),
      searchParams,
    };
  } catch (error: any) {
    console.error('❌ POP AI Error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

async function shouldSearchProducts(query: string, history: Message[]): Promise<boolean> {
  // Always search for products unless it's a pure greeting
  const greetings = ['hi', 'hello', 'hey', 'thanks', 'thank you', 'bye', 'goodbye'];
  const lowerQuery = query.toLowerCase().trim();
  
  // Don't search for simple greetings
  if (greetings.includes(lowerQuery)) {
    return false;
  }
  
  // Search for everything else
  return true;
}

async function extractSearchParams(query: string, history: Message[]): Promise<SearchParams> {
  const contextMessages = history.slice(-4).map(msg => 
    `${msg.role === 'user' ? 'User' : 'POP AI'}: ${msg.content}`
  ).join('\n');

  const prompt = `You are POP AI, a shopping assistant. Extract search parameters from the user's query.

IMPORTANT: Use category taxonomy. Map product types to their parent categories:
- Shirts, pants, dresses, shorts, shoes, jackets → "Fashion & Apparel"
- Phones, laptops, tablets, headphones, cameras → "Electronics"  
- Furniture, decor, kitchen items → "Home & Garden"
- Perfume, makeup, skincare, hair products → "Health & Beauty"
- Books, magazines, music → "Books & Media"
- Sports equipment, gym gear, outdoor gear → "Sports & Outdoors"
- Toys, games, puzzles → "Toys & Games"
- Car parts, accessories → "Automotive"
- Food, drinks, snacks → "Food & Beverages"
- Office supplies, stationery → "Office Supplies"

Conversation context:
${contextMessages || 'First message'}

Current query: "${query}"

Return ONLY a JSON object:
{
  "category": "parent category from list above",
  "priceMin": number or omit,
  "priceMax": number or omit,
  "keywords": ["specific", "search", "terms"],
  "color": "color if mentioned",
  "brand": "brand if mentioned"
}

Examples:
"shorts" → {"category": "Fashion & Apparel", "keywords": ["shorts"]}
"gaming laptop under 50000" → {"category": "Electronics", "priceMax": 50000, "keywords": ["gaming", "laptop"]}
"dior perfume" → {"category": "Health & Beauty", "brand": "dior", "keywords": ["perfume"]}`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    
    console.log('🤖 Gemini extraction response:', text);
    
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    const jsonStr = jsonMatch ? jsonMatch[0] : '{}';
    
    const params = JSON.parse(jsonStr);
    console.log('✅ Parsed params:', params);
    return params;
  } catch (error) {
    console.error('❌ Error extracting params:', error);
    return {
      keywords: query.toLowerCase().split(' ').filter(w => w.length > 2),
    };
  }
}

async function searchProducts(params: SearchParams): Promise<Product[]> {
  try {
    let query = db.collectionGroup('products')
      .where('isActive', '==', true)
      .limit(20);

    // Apply category filter
    if (params.category) {
      query = query.where('categoryId', '==', params.category);
    }

    // Apply price filter (we'll filter in memory since Firestore has limitations)
    const snapshot = await query.get();
    
    let products: Product[] = [];

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const storeId = doc.ref.parent.parent?.id;
      
      if (!storeId) continue;

      // Price filtering
      if (params.priceMin && data.price < params.priceMin) continue;
      if (params.priceMax && data.price > params.priceMax) continue;

      // Keyword filtering
      if (params.keywords && params.keywords.length > 0) {
        const productText = `${data.name} ${data.description || ''}`.toLowerCase();
        const hasKeyword = params.keywords.some(keyword => 
          productText.includes(keyword.toLowerCase())
        );
        if (!hasKeyword) continue;
      }

      // Color filtering
      if (params.color) {
        const productText = `${data.name} ${data.description || ''}`.toLowerCase();
        if (!productText.includes(params.color.toLowerCase())) continue;
      }

      // Get store info
      const storeDoc = await db.collection('stores').doc(storeId).get();
      const storeData = storeDoc.data();

      products.push({
        id: doc.id,
        storeId,
        name: data.name,
        price: data.price,
        currency: data.currency || 'USD',
        imageUrl: Array.isArray(data.images) && data.images.length > 0 
          ? (typeof data.images[0] === 'string' ? data.images[0] : data.images[0]?.url)
          : undefined,
        storeName: storeData?.name,
        storeLogoUrl: storeData?.logoUrl,
        verificationStatus: storeData?.verificationStatus,
      });
    }

    // Sort by relevance (verified stores first, then by price)
    products.sort((a, b) => {
      if (a.verificationStatus === 'verified' && b.verificationStatus !== 'verified') return -1;
      if (a.verificationStatus !== 'verified' && b.verificationStatus === 'verified') return 1;
      return a.price - b.price;
    });

    return products;
  } catch (error) {
    console.error('Error searching products:', error);
    return [];
  }
}

): Promise<string> {
  // Handle greetings
  const greetings = ['hi', 'hello', 'hey'];
  if (greetings.includes(query.toLowerCase().trim()) && products.length === 0) {
    const greeting = userName ? `Hi ${userName}!` : 'Hey there!';
    return `${greeting} 👋 I'm POP AI, your personal shopping assistant. What can I help you find today?`;
  }

  const contextMessages = history.slice(-6).map(msg => 
    `${msg.role === 'user' ? 'User' : 'POP AI'}: ${msg.content}`
  ).join('\n');

  const systemPrompt = `You are POP AI, a friendly shopping assistant for Purl marketplace. 

PERSONALITY:
- Warm, enthusiastic, conversational
- Use emojis sparingly (1-2 per response)
- Keep responses 2-3 sentences max
- Never list products (they're shown as cards)
- Be helpful and suggest alternatives
- Remember conversation context
${userName ? `- User's name is ${userName}, use it naturally` : ''}

CONVERSATION HISTORY:
${contextMessages || 'This is the start of the conversation'}

USER QUERY: "${query}"

SEARCH RESULTS:
${products.length > 0 ? `Found ${products.length} products
Price range: R${Math.min(...products.map(p => p.price))} - R${Math.max(...products.map(p => p.price))}
${products.filter(p => p.verificationStatus === 'verified').length} from verified sellers` : 'No products found'}

Generate a natural, helpful response. Acknowledge what you found and provide context or suggestions.`;

  try {
    const result = await model.generateContent(systemPrompt);
    const response = result.response;
    const text = response.candidates?.[0]?.content?.parts?.[0]?.text || '';
    const cleanText = text.trim();
    
    if (cleanText) {
      console.log('✅ Gemini response:', cleanText);
      return cleanText;
    }
    
    throw new Error('Empty response from Gemini');
  } catch (error) {
    console.error('❌ Gemini error:', error);
    
    // Fallback
    if (products.length === 0) {
      return "I couldn't find exactly what you're looking for 😕 Could you give me more details?";
    }
    return `Great! I found ${products.length} options for you 🛍️`;
  }
}
