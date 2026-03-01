import { FirestoreService } from "./firestore.service";

export interface FinancialRecord {
  id: string;
  date: string;
  totalRevenue: number;
  commission: number;
  payouts: number;
  netProfit: number;
  orderCount: number;
}

export const FinancialService = {
  async getFinancialRecords() {
    // Aggregate financial data from orders
    const orders = await FirestoreService.getAllFromCollectionGroup<any>('orders');
    
    // Group by date
    const recordsByDate: { [key: string]: FinancialRecord } = {};
    
    orders.forEach(order => {
      const date = order.createdAt?.split('T')[0] || new Date().toISOString().split('T')[0];
      
      if (!recordsByDate[date]) {
        recordsByDate[date] = {
          id: date,
          date,
          totalRevenue: 0,
          commission: 0,
          payouts: 0,
          netProfit: 0,
          orderCount: 0,
        };
      }
      
      recordsByDate[date].totalRevenue += order.total || 0;
      recordsByDate[date].commission += order.commission || 0;
      recordsByDate[date].orderCount += 1;
    });
    
    // Get payouts
    const payouts = await FirestoreService.getAllDocuments<any>('payouts');
    payouts.forEach(payout => {
      if (payout.status === 'completed') {
        const date = payout.processedAt?.split('T')[0] || payout.createdAt?.split('T')[0] || new Date().toISOString().split('T')[0];
        if (recordsByDate[date]) {
          recordsByDate[date].payouts += payout.amount || 0;
        }
      }
    });
    
    // Calculate net profit
    Object.values(recordsByDate).forEach(record => {
      record.netProfit = record.commission - record.payouts;
    });
    
    // Convert to array and sort by date (newest first)
    return Object.values(recordsByDate).sort((a, b) => b.date.localeCompare(a.date));
  },

  async getFinancialSummary() {
    const orders = await FirestoreService.getAllFromCollectionGroup<any>('orders');
    const payouts = await FirestoreService.getAllDocuments<any>('payouts');
    
    const totalRevenue = orders.reduce((sum: number, o: any) => sum + (o.total || 0), 0);
    const totalCommission = orders.reduce((sum: number, o: any) => sum + (o.commission || 0), 0);
    const totalPayouts = payouts
      .filter((p: any) => p.status === 'completed')
      .reduce((sum: number, p: any) => sum + (p.amount || 0), 0);
    
    return {
      totalRevenue,
      totalCommission,
      totalPayouts,
      netProfit: totalCommission - totalPayouts,
      orderCount: orders.length,
    };
  },
};
