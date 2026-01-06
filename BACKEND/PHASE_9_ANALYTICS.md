# Phase 9: Analytics & Reporting

## Overview

Implement analytics dashboards, reporting, and additional premium features using Firebase Analytics and BigQuery.

## Firebase Analytics Setup

### Custom Events

```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  // Product Events
  Future<void> logViewProduct(String productId, String productName, double price) async {
    await _analytics.logViewItem(
      items: [AnalyticsEventItem(
        itemId: productId,
        itemName: productName,
        price: price
      )]
    );
  }
  
  Future<void> logAddToCart(String productId, double price, int quantity) async {
    await _analytics.logAddToCart(
      items: [AnalyticsEventItem(
        itemId: productId,
        price: price,
        quantity: quantity
      )]
    );
  }
  
  Future<void> logPurchase(String orderId, double total, List<CartItem> items) async {
    await _analytics.logPurchase(
      transactionId: orderId,
      value: total,
      currency: 'KES',
      items: items.map((i) => AnalyticsEventItem(
        itemId: i.product.id,
        itemName: i.product.name,
        price: i.product.price,
        quantity: i.quantity
      )).toList()
    );
  }
  
  // Vendor Events
  Future<void> logVendorAction(String action, Map<String, dynamic> params) async {
    await _analytics.logEvent(name: 'vendor_$action', parameters: params);
  }
}
```


## Vendor Analytics Collections

### Daily Stats Collection

```
/vendors/{vendorId}/stats/daily/{date}
├── date: string (YYYY-MM-DD)
├── orders: number
├── revenue: number
├── commission: number
├── netRevenue: number
├── itemsSold: number
├── newCustomers: number
├── returningCustomers: number
├── averageOrderValue: number
├── topProducts: array
│   ├── productId: string
│   ├── name: string
│   ├── quantity: number
│   └── revenue: number
└── updatedAt: timestamp
```

### Monthly Stats Collection

```
/vendors/{vendorId}/stats/monthly/{yearMonth}
├── yearMonth: string (YYYY-MM)
├── orders: number
├── revenue: number
├── commission: number
├── netRevenue: number
├── itemsSold: number
├── uniqueCustomers: number
├── averageOrderValue: number
├── topProducts: array
├── topCategories: array
├── dailyBreakdown: map
└── updatedAt: timestamp
```

## Analytics Cloud Functions

### Update Daily Stats

```typescript
// functions/src/analytics/updateDailyStats.ts
export const updateDailyStats = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only process completed orders
    if (before.status !== 'delivered' && after.status === 'delivered') {
      const vendorId = after.vendorId;
      const date = new Date().toISOString().split('T')[0];
      
      const statsRef = db.collection('vendors').doc(vendorId)
        .collection('stats').doc('daily')
        .collection(date).doc('summary');
      
      await db.runTransaction(async (transaction) => {
        const stats = await transaction.get(statsRef);
        
        if (stats.exists) {
          transaction.update(statsRef, {
            orders: FieldValue.increment(1),
            revenue: FieldValue.increment(after.total),
            commission: FieldValue.increment(after.commission),
            netRevenue: FieldValue.increment(after.netAmount),
            itemsSold: FieldValue.increment(
              after.items.reduce((sum, i) => sum + i.quantity, 0)
            ),
            updatedAt: FieldValue.serverTimestamp()
          });
        } else {
          transaction.set(statsRef, {
            date,
            orders: 1,
            revenue: after.total,
            commission: after.commission,
            netRevenue: after.netAmount,
            itemsSold: after.items.reduce((sum, i) => sum + i.quantity, 0),
            newCustomers: 0,
            returningCustomers: 0,
            averageOrderValue: after.total,
            topProducts: [],
            updatedAt: FieldValue.serverTimestamp()
          });
        }
      });
    }
  });
```

### Generate Monthly Report

```typescript
// functions/src/analytics/generateMonthlyReport.ts
export const generateMonthlyReport = functions.pubsub
  .schedule('0 1 1 * *') // 1 AM on 1st of each month
  .onRun(async () => {
    const lastMonth = new Date();
    lastMonth.setMonth(lastMonth.getMonth() - 1);
    const yearMonth = lastMonth.toISOString().slice(0, 7);
    
    const vendors = await db.collection('vendors').get();
    
    for (const vendor of vendors.docs) {
      const vendorId = vendor.id;
      
      // Get all orders for the month
      const startDate = new Date(yearMonth + '-01');
      const endDate = new Date(startDate);
      endDate.setMonth(endDate.getMonth() + 1);
      
      const orders = await db.collection('orders')
        .where('vendorId', '==', vendorId)
        .where('status', '==', 'delivered')
        .where('deliveredAt', '>=', startDate)
        .where('deliveredAt', '<', endDate)
        .get();
      
      // Calculate stats
      const stats = calculateMonthlyStats(orders.docs.map(d => d.data()));
      
      // Save monthly report
      await db.collection('vendors').doc(vendorId)
        .collection('stats').doc('monthly')
        .collection(yearMonth).doc('summary')
        .set(stats);
    }
  });

function calculateMonthlyStats(orders: any[]) {
  const revenue = orders.reduce((sum, o) => sum + o.total, 0);
  const commission = orders.reduce((sum, o) => sum + o.commission, 0);
  
  // Calculate top products
  const productSales: Record<string, { name: string; quantity: number; revenue: number }> = {};
  orders.forEach(order => {
    order.items.forEach(item => {
      if (!productSales[item.productId]) {
        productSales[item.productId] = { name: item.name, quantity: 0, revenue: 0 };
      }
      productSales[item.productId].quantity += item.quantity;
      productSales[item.productId].revenue += item.subtotal;
    });
  });
  
  const topProducts = Object.entries(productSales)
    .map(([id, data]) => ({ productId: id, ...data }))
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 10);
  
  return {
    orders: orders.length,
    revenue,
    commission,
    netRevenue: revenue - commission,
    itemsSold: orders.reduce((sum, o) => 
      sum + o.items.reduce((s, i) => s + i.quantity, 0), 0),
    uniqueCustomers: new Set(orders.map(o => o.buyerId)).size,
    averageOrderValue: orders.length > 0 ? revenue / orders.length : 0,
    topProducts,
    updatedAt: FieldValue.serverTimestamp()
  };
}
```


## Dashboard API Endpoints

### Get Dashboard Stats

```typescript
// functions/src/analytics/getDashboardStats.ts
export const getDashboardStats = functions.https.onCall(async (data, context) => {
  const vendorId = context.auth?.uid;
  const { period = '7d' } = data;
  
  const endDate = new Date();
  const startDate = new Date();
  
  switch (period) {
    case '7d': startDate.setDate(startDate.getDate() - 7); break;
    case '30d': startDate.setDate(startDate.getDate() - 30); break;
    case '90d': startDate.setDate(startDate.getDate() - 90); break;
  }
  
  // Get orders in period
  const orders = await db.collection('orders')
    .where('vendorId', '==', vendorId)
    .where('createdAt', '>=', startDate)
    .where('createdAt', '<=', endDate)
    .get();
  
  const orderData = orders.docs.map(d => d.data());
  
  // Calculate metrics
  const totalOrders = orderData.length;
  const pendingOrders = orderData.filter(o => o.status === 'pending').length;
  const completedOrders = orderData.filter(o => o.status === 'delivered').length;
  const totalRevenue = orderData
    .filter(o => o.paymentStatus === 'completed')
    .reduce((sum, o) => sum + o.total, 0);
  const totalCommission = orderData
    .filter(o => o.paymentStatus === 'completed')
    .reduce((sum, o) => sum + o.commission, 0);
  
  // Get low stock products
  const lowStock = await db.collection('products')
    .where('vendorId', '==', vendorId)
    .where('trackInventory', '==', true)
    .where('stock', '<=', 10)
    .get();
  
  return {
    totalOrders,
    pendingOrders,
    completedOrders,
    totalRevenue,
    totalCommission,
    netRevenue: totalRevenue - totalCommission,
    lowStockCount: lowStock.size,
    period
  };
});
```

### Get Sales Chart Data

```typescript
export const getSalesChartData = functions.https.onCall(async (data, context) => {
  const vendorId = context.auth?.uid;
  const { period = '7d' } = data;
  
  const days = period === '7d' ? 7 : period === '30d' ? 30 : 90;
  const chartData: Array<{ date: string; orders: number; revenue: number }> = [];
  
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    const dateStr = date.toISOString().split('T')[0];
    
    const dayStart = new Date(dateStr);
    const dayEnd = new Date(dateStr);
    dayEnd.setDate(dayEnd.getDate() + 1);
    
    const orders = await db.collection('orders')
      .where('vendorId', '==', vendorId)
      .where('paymentStatus', '==', 'completed')
      .where('createdAt', '>=', dayStart)
      .where('createdAt', '<', dayEnd)
      .get();
    
    const revenue = orders.docs.reduce((sum, d) => sum + d.data().total, 0);
    
    chartData.push({
      date: dateStr,
      orders: orders.size,
      revenue
    });
  }
  
  return { chartData };
});
```

## Implementation Checklist

- [ ] Set up Firebase Analytics
- [ ] Configure BigQuery export
- [ ] Create stats collections
- [ ] Implement daily stats updates
- [ ] Implement monthly report generation
- [ ] Build dashboard API endpoints
- [ ] Build analytics UI in vendor app
- [ ] Test all analytics flows

---

> **Note:** Social features (Posts, Stories, Followers) are now documented in [PHASE_8_SOCIAL_FEED.md](./PHASE_8_SOCIAL_FEED.md)
> **Note:** Wishlist is documented in [PHASE_10_ADDITIONAL_FEATURES.md](./PHASE_10_ADDITIONAL_FEATURES.md)
