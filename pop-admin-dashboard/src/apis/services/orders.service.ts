import { orderBy } from "firebase/firestore";
import { FirestoreService } from "./firestore.service";

export interface Order {
  id: string;
  orderNumber: string;
  customerName?: string;
  customerPhone?: string;
  storeName?: string;
  storeId?: string;
  userId?: string;
  items?: any[];
  total: number;
  commission: number;
  commissionRate?: number;
  sellerPayout?: number;
  paymentMethod?: string;
  paymentStatus?: string;
  status: string;
  createdAt: any;
}

export const OrdersService = {
  async getOrders(pagination?: any) {
    // Orders are stored in subcollections under stores/{storeId}/orders
    // Use collectionGroup to query across all stores
    try {
      const orders = await FirestoreService.getAllFromCollectionGroup<any>(
        'orders',
        [orderBy('createdAt', 'desc')]
      );
      
      // Map and provide defaults matching the columns structure
      const mappedOrders = orders.map(order => ({
        ...order,
        orderNumber: order.orderNumber || order.id || 'N/A',
        customerName: order.customerName || order.buyerName || 'Unknown',
        customerPhone: order.customerPhone || order.buyerPhone || '',
        storeName: order.storeName || 'Unknown Store',
        items: order.items?.length || order.itemCount || 0,
        total: order.total || order.totalAmount || 0,
        commission: order.commission || 0,
        commissionRate: order.commissionRate || 10,
        sellerPayout: order.sellerPayout || ((order.total || 0) - (order.commission || 0)),
        paymentMethod: order.paymentMethod || 'unknown',
        paymentStatus: order.paymentStatus || 'pending',
        status: order.status || 'pending',
      }));
      
      // Apply pagination if provided
      if (pagination) {
        const startIndex = pagination.pageIndex * pagination.pageSize;
        const endIndex = startIndex + pagination.pageSize;
        const paginatedOrders = mappedOrders.slice(startIndex, endIndex);
        
        return {
          data: paginatedOrders,
          total: mappedOrders.length,
          hasMore: endIndex < mappedOrders.length,
        };
      }
      
      return {
        data: mappedOrders.slice(0, 100),
        total: mappedOrders.length,
        hasMore: false,
      };
    } catch (error) {
      console.error('Error fetching orders:', error);
      return {
        data: [],
        total: 0,
        hasMore: false,
      };
    }
  },

  async getOrderStats() {
    const orders = await FirestoreService.getAllFromCollectionGroup<Order>('orders');
    
    return {
      total: orders.length,
      pending: orders.filter(o => ['pending', 'processing', 'confirmed'].includes(o.status)).length,
      delivered: orders.filter(o => o.status === 'delivered').length,
      totalRevenue: orders.reduce((sum, o) => sum + (o.total || 0), 0),
      totalCommission: orders.reduce((sum, o) => sum + (o.commission || 0), 0),
    };
  },

  async getOrder(orderId: string) {
    // Try to find order in collectionGroup
    const orders = await FirestoreService.getAllFromCollectionGroup<any>('orders');
    return orders.find(o => o.id === orderId) || null;
  },
};
