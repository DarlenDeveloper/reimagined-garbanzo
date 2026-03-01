import { FirestoreService, PaginationParams } from "./firestore.service";

export interface Payout {
  id: string;
  recipientName: string;
  recipientType: 'store' | 'courier';
  amount: number;
  method: string;
  accountDetails: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  requestedAt: string;
  processedAt?: string;
}

export const PayoutsService = {
  async getPayouts(pagination: PaginationParams, type?: 'store' | 'courier') {
    let allPayouts: any[] = [];
    
    if (type === 'store' || !type) {
      // Get store payouts from subcollections
      const storePayouts = await FirestoreService.getAllFromCollectionGroup<any>('payouts');
      allPayouts = [...allPayouts, ...storePayouts.map(p => ({ ...p, recipientType: 'store' }))];
    }
    
    if (type === 'courier' || !type) {
      // Courier payouts can be left blank as per user request
      // const courierPayouts = await FirestoreService.getAllDocuments<any>('courier_payouts');
      // allPayouts = [...allPayouts, ...courierPayouts];
    }
    
    // Filter by type if specified
    let filteredPayouts = type 
      ? allPayouts.filter(p => p.recipientType === type)
      : allPayouts;
    
    // Sort by requested date (newest first)
    filteredPayouts.sort((a, b) => {
      const dateA = a.requestedAt?.seconds || a.createdAt?.seconds || 0;
      const dateB = b.requestedAt?.seconds || b.createdAt?.seconds || 0;
      return dateB - dateA;
    });
    
    // Map and provide defaults
    const mappedData = filteredPayouts.map(payout => ({
      ...payout,
      recipientName: payout.recipientName || payout.name || payout.storeName || payout.courierName || 'Unknown',
      recipientType: payout.recipientType || 'store',
      amount: payout.amount || 0,
      method: payout.method || payout.paymentMethod || 'bank_transfer',
      accountDetails: payout.accountDetails || payout.account || 'N/A',
      status: payout.status || 'pending',
      requestedAt: payout.requestedAt || payout.createdAt,
      processedAt: payout.processedAt || payout.completedAt,
    }));
    
    // Apply pagination
    const startIndex = pagination.pageIndex * pagination.pageSize;
    const endIndex = startIndex + pagination.pageSize;
    const paginatedData = mappedData.slice(startIndex, endIndex);
    
    return {
      data: paginatedData,
      total: mappedData.length,
      hasMore: endIndex < mappedData.length,
    };
  },

  async updatePayoutStatus(payoutId: string, status: 'processing' | 'completed' | 'failed') {
    return FirestoreService.updateDocument('payouts', payoutId, {
      status,
      processedAt: new Date().toISOString(),
    });
  },

  async getPayoutStats(type?: 'store' | 'courier') {
    let allPayouts: any[] = [];
    
    if (type === 'store' || !type) {
      const storePayouts = await FirestoreService.getAllFromCollectionGroup<any>('payouts');
      allPayouts = [...allPayouts, ...storePayouts.map(p => ({ ...p, recipientType: 'store' }))];
    }
    
    const filteredPayouts = type ? allPayouts.filter(p => p.recipientType === type) : allPayouts;
    
    return {
      pending: filteredPayouts.filter(p => p.status === 'pending').length,
      pendingAmount: filteredPayouts.filter(p => p.status === 'pending').reduce((sum, p) => sum + (p.amount || 0), 0),
      completed: filteredPayouts.filter(p => p.status === 'completed').length,
      completedAmount: filteredPayouts.filter(p => p.status === 'completed').reduce((sum, p) => sum + (p.amount || 0), 0),
    };
  },
};
