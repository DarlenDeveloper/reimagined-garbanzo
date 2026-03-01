import { orderBy } from "firebase/firestore";
import { FirestoreService, PaginationParams } from "./firestore.service";

export interface Store {
  id: string;
  name: string;
  slug: string;
  category: string;
  ownerId: string;
  ownerName: string;
  isVerified: boolean;
  verificationStatus: 'pending' | 'verified' | 'rejected';
  hasAIService?: boolean;
  rating?: number;
  productCount?: number;
  followerCount?: number;
  subscription?: 'free' | 'premium';
  createdAt: string;
}

export const StoresService = {
  async getStores(pagination: PaginationParams) {
    const result = await FirestoreService.getPaginatedCollection<any>(
      'stores',
      pagination,
      [orderBy('createdAt', 'desc')]
    );
    
    // Map and provide defaults for missing fields
    const mappedData = result.data.map(store => ({
      ...store,
      slug: store.slug || store.name?.toLowerCase().replace(/\s+/g, '-') || 'unknown',
      category: store.category || 'Uncategorized',
      ownerName: store.ownerName || store.owner?.name || store.name || 'Unknown',
      isVerified: store.isVerified || store.verified || false,
      verificationStatus: store.verificationStatus || store.status || (store.isVerified ? 'verified' : 'none'),
      hasAIService: store.hasAIService || store.aiServiceEnabled || store.hasAI || false,
      rating: store.rating || store.averageRating || 0,
      productCount: store.productCount || store.products?.length || 0,
      followerCount: store.followerCount || store.followers?.length || 0,
      subscription: store.subscription || store.plan || 'free',
    }));
    
    return {
      ...result,
      data: mappedData,
    };
  },

  async getStore(storeId: string) {
    return FirestoreService.getDocument<Store>('stores', storeId);
  },

  async getStoreStats() {
    const stores = await FirestoreService.getAllDocuments<any>('stores');
    return {
      total: stores.length,
      verified: stores.filter(s => s.isVerified || s.verified).length,
      withAI: stores.filter(s => s.hasAIService || s.aiServiceEnabled || s.hasAI).length,
      premium: stores.filter(s => s.subscription === 'premium' || s.plan === 'premium').length,
    };
  },

  async getPendingVerifications() {
    // Get all stores and filter in memory to avoid composite index requirement
    const allStores = await FirestoreService.getAllDocuments<any>('stores');
    
    // Filter for pending verifications - be more lenient
    const pendingStores = allStores.filter(store => {
      // Check various conditions for pending status
      return (
        store.verificationStatus === 'pending' ||
        store.status === 'pending' ||
        store.verificationStatus === 'none' ||
        (!store.isVerified && !store.verified)
      );
    });
    
    // Sort by creation date (newest first)
    pendingStores.sort((a, b) => {
      const dateA = a.createdAt?.seconds || 0;
      const dateB = b.createdAt?.seconds || 0;
      return dateB - dateA;
    });
    
    // Map with defaults
    return pendingStores.map(store => ({
      ...store,
      slug: store.slug || store.name?.toLowerCase().replace(/\s+/g, '-') || 'unknown',
      category: store.category || 'Uncategorized',
      ownerName: store.ownerName || store.owner?.name || store.name || 'Unknown',
      isVerified: store.isVerified || store.verified || false,
      verificationStatus: store.verificationStatus || 'pending',
      hasAIService: store.hasAIService || store.aiServiceEnabled || store.hasAI || false,
      rating: store.rating || store.averageRating || 0,
      productCount: store.productCount || store.products?.length || 0,
      followerCount: store.followerCount || store.followers?.length || 0,
      subscription: store.subscription || store.plan || 'free',
    }));
  },

  async updateVerificationStatus(storeId: string, status: 'verified' | 'rejected') {
    return FirestoreService.updateDocument('stores', storeId, {
      verificationStatus: status,
      isVerified: status === 'verified',
    });
  },
};
