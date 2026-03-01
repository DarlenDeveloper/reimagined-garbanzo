import { FirestoreService } from "./firestore.service";
import { OrdersService } from "./orders.service";
import { PaymentsService } from "./payments.service";
import { UsersService } from "./users.service";
import { StoresService } from "./stores.service";
import { CouriersService } from "./couriers.service";

export const AnalyticsService = {
  async getDashboardStats() {
    const [orderStats, paymentStats, userStats, storeStats, courierStats] = await Promise.all([
      OrdersService.getOrderStats(),
      PaymentsService.getPaymentStats(),
      UsersService.getUserStats(),
      StoresService.getStoreStats(),
      CouriersService.getCourierStats(),
    ]);

    return {
      orders: orderStats,
      payments: paymentStats,
      users: userStats,
      stores: storeStats,
      couriers: courierStats,
    };
  },

  async getRevenueData() {
    // Get orders from subcollections using collectionGroup
    const orders = await FirestoreService.getAllFromCollectionGroup<any>('orders');
    
    // Group by date for chart
    const revenueByDate = orders.reduce((acc: any, order: any) => {
      const date = order.createdAt?.split('T')[0] || new Date().toISOString().split('T')[0];
      if (!acc[date]) {
        acc[date] = { date, revenue: 0, orders: 0 };
      }
      acc[date].revenue += order.total || 0;
      acc[date].orders += 1;
      return acc;
    }, {});

    return Object.values(revenueByDate);
  },
};
