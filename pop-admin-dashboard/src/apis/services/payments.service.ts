import { orderBy } from "firebase/firestore";
import { FirestoreService, PaginationParams } from "./firestore.service";

export interface Payment {
  id: string;
  transactionId: string;
  orderNumber: string;
  customerName: string;
  amount: number;
  method: string;
  status: string;
  createdAt: string;
}

export const PaymentsService = {
  async getPayments(pagination: PaginationParams) {
    const result = await FirestoreService.getPaginatedCollection<any>(
      'payments',
      pagination,
      [orderBy('createdAt', 'desc')]
    );
    
    // Map and provide defaults matching the columns structure
    const mappedData = result.data.map(payment => ({
      ...payment,
      txRef: payment.txRef || payment.transactionId || payment.id || 'N/A',
      orderNumber: payment.orderNumber || payment.orderId || 'N/A',
      buyerName: payment.buyerName || payment.customerName || 'Unknown',
      buyerPhone: payment.buyerPhone || payment.customerPhone || '',
      amount: payment.amount || payment.total || 0,
      currency: payment.currency || 'UGX',
      paymentMethod: payment.paymentMethod || payment.method || 'unknown',
      network: payment.network || null,
      status: payment.status || 'pending',
      flwRef: payment.flwRef || payment.flutterwaveRef || 'N/A',
    }));
    
    return {
      ...result,
      data: mappedData,
    };
  },

  async getPaymentStats() {
    const payments = await FirestoreService.getAllDocuments<Payment>('payments');
    return {
      totalRevenue: payments.filter(p => p.status === 'completed').reduce((sum, p) => sum + p.amount, 0),
      cardPayments: payments.filter(p => p.method === 'card').reduce((sum, p) => sum + p.amount, 0),
      mobilePayments: payments.filter(p => p.method === 'mobile_money').reduce((sum, p) => sum + p.amount, 0),
      failedCount: payments.filter(p => p.status === 'failed').length,
    };
  },
};
