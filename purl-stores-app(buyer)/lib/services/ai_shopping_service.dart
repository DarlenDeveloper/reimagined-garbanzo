import 'package:cloud_functions/cloud_functions.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}

class AIShoppingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'africa-south1');
  final List<ChatMessage> _conversationHistory = [];

  List<ChatMessage> get conversationHistory => List.unmodifiable(_conversationHistory);

  Future<AIShoppingResponse> searchProducts(String query, {String? userId}) async {
    try {
      print('🤖 Sending query to AI: $query');
      print('📜 Conversation history: ${_conversationHistory.length} messages');
      
      final result = await _functions.httpsCallable('aiShoppingAssistant').call({
        'query': query,
        'conversationHistory': _conversationHistory.map((m) => m.toJson()).toList(),
        if (userId != null) 'userId': userId,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      
      if (data['success'] == true) {
        final response = AIShoppingResponse.fromJson(data);
        
        // Add to conversation history
        _conversationHistory.add(ChatMessage(role: 'user', content: query));
        _conversationHistory.add(ChatMessage(role: 'assistant', content: response.response));
        
        // Keep only last 20 messages (10 exchanges)
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 20);
        }
        
        return response;
      } else {
        throw Exception('AI search failed');
      }
    } catch (e) {
      print('❌ AI Shopping Service Error: $e');
      rethrow;
    }
  }

  void clearHistory() {
    _conversationHistory.clear();
    print('🗑️ Conversation history cleared');
  }
}

class AIShoppingResponse {
  final String response;
  final List<AIProduct> products;
  final Map<String, dynamic> searchParams;

  AIShoppingResponse({
    required this.response,
    required this.products,
    required this.searchParams,
  });

  factory AIShoppingResponse.fromJson(Map<String, dynamic> json) {
    print('📦 Raw response data: $json');
    
    final productsData = json['products'] as List?;
    final productsList = productsData?.map((p) {
      final productMap = Map<String, dynamic>.from(p as Map);
      return AIProduct.fromJson(productMap);
    }).toList() ?? [];
    
    final searchParamsData = json['searchParams'];
    final searchParams = searchParamsData != null 
        ? Map<String, dynamic>.from(searchParamsData as Map)
        : <String, dynamic>{};
    
    // Handle response - it might be a string or an object
    String responseText = '';
    final responseData = json['response'];
    if (responseData is String) {
      responseText = responseData;
    } else if (responseData is Map) {
      // If it's a map, try to extract text from it
      responseText = responseData['text']?.toString() ?? 
                     responseData['content']?.toString() ?? 
                     'I found some products for you!';
    } else {
      responseText = responseData?.toString() ?? 'I found some products for you!';
    }
    
    return AIShoppingResponse(
      response: responseText,
      products: productsList,
      searchParams: searchParams,
    );
  }
}

class AIProduct {
  final String id;
  final String storeId;
  final String name;
  final double price;
  final String currency;
  final String? imageUrl;
  final String? storeName;
  final String? storeLogoUrl;
  final String? verificationStatus;

  AIProduct({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    required this.currency,
    this.imageUrl,
    this.storeName,
    this.storeLogoUrl,
    this.verificationStatus,
  });

  factory AIProduct.fromJson(Map<String, dynamic> json) {
    // Handle imageUrl - it might be a string or an object with url field
    String? imageUrl;
    final imageData = json['imageUrl'];
    if (imageData is String) {
      imageUrl = imageData;
    } else if (imageData is Map) {
      imageUrl = imageData['url']?.toString();
    }
    
    return AIProduct(
      id: json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      imageUrl: imageUrl,
      storeName: json['storeName'] as String?,
      storeLogoUrl: json['storeLogoUrl'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
    );
  }

  bool get isVerified => verificationStatus == 'verified';
}
