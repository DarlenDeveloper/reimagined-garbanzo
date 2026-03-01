import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { DollarSign, ShoppingCart, Users, TrendingUp, Store, Truck } from "lucide-react";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@components/ui/tabs";
import { useOrderStats } from "@apis/queries/useOrders";
import { useUserStats } from "@apis/queries/useUsers";
import { useStoreStats } from "@apis/queries/useStores";
import { useCourierStats } from "@apis/queries/useCouriers";
import { usePaymentStats } from "@apis/queries/usePayments";

export function AnalyticsDashboard() {
  const { data: orderStats } = useOrderStats();
  const { data: userStats } = useUserStats();
  const { data: storeStats } = useStoreStats();
  const { data: courierStats } = useCourierStats();
  const { data: paymentStats } = usePaymentStats();

  const totalRevenue = orderStats?.totalRevenue || 0;
  const totalCommission = orderStats?.totalCommission || 0;

  const stats = [
    { 
      title: "Total Revenue", 
      value: `UGX ${(totalRevenue / 1000000).toFixed(1)}M`, 
      icon: DollarSign, 
      description: "All platform orders", 
      trend: "" 
    },
    { 
      title: "Commission Earned", 
      value: `UGX ${(totalCommission / 1000000).toFixed(1)}M`, 
      icon: TrendingUp, 
      description: `${totalRevenue ? ((totalCommission / totalRevenue) * 100).toFixed(1) : 0}% avg rate`, 
      trend: "" 
    },
    { 
      title: "Total Orders", 
      value: (orderStats?.total || 0).toLocaleString(), 
      icon: ShoppingCart, 
      description: `${orderStats?.delivered || 0} delivered`, 
      trend: "" 
    },
    { 
      title: "Total Users", 
      value: (userStats?.total || 0).toLocaleString(), 
      icon: Users, 
      description: `${userStats?.buyers || 0} buyers, ${userStats?.sellers || 0} sellers`, 
      trend: "" 
    },
    { 
      title: "Active Stores", 
      value: (storeStats?.verified || 0).toLocaleString(), 
      icon: Store, 
      description: "Verified sellers", 
      trend: "" 
    },
    { 
      title: "Active Couriers", 
      value: (courierStats?.online || 0).toLocaleString(), 
      icon: Truck, 
      description: `${courierStats?.total || 0} total couriers`, 
      trend: "" 
    },
  ];

  const cardPaymentPercent = paymentStats?.totalRevenue 
    ? ((paymentStats.cardPayments / paymentStats.totalRevenue) * 100).toFixed(0)
    : "0";
  const mobilePaymentPercent = paymentStats?.totalRevenue 
    ? ((paymentStats.mobilePayments / paymentStats.totalRevenue) * 100).toFixed(0)
    : "0";

  return (
    <div className="space-y-4">
      <PageTitle title="Analytics Dashboard" desc="Platform performance and revenue insights" />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground">{stat.description}</p>
              <p className="text-xs text-green-600 mt-1">{stat.trend}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Tabs defaultValue="revenue" className="space-y-4">
        <TabsList>
          <TabsTrigger value="revenue">Payment Methods</TabsTrigger>
          <TabsTrigger value="orders">Order Analytics</TabsTrigger>
          <TabsTrigger value="stores">Top Stores</TabsTrigger>
        </TabsList>

        <TabsContent value="revenue" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-7">
            <Card className="col-span-7">
              <CardHeader>
                <CardTitle>Payment Methods</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="h-3 w-3 rounded-full bg-blue-500" />
                      <span className="text-sm">Mobile Money</span>
                    </div>
                    <span className="text-sm font-medium">{mobilePaymentPercent}%</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="h-3 w-3 rounded-full bg-purple-500" />
                      <span className="text-sm">Card Payments</span>
                    </div>
                    <span className="text-sm font-medium">{cardPaymentPercent}%</span>
                  </div>
                  <div className="mt-4 pt-4 border-t">
                    <p className="text-xs text-muted-foreground">Total Revenue</p>
                    <p className="text-lg font-bold">UGX {((paymentStats?.totalRevenue || 0) / 1000000).toFixed(1)}M</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="orders">
          <Card>
            <CardHeader>
              <CardTitle>Order Status Breakdown</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between border-b pb-4">
                  <div>
                    <p className="font-medium">Total Orders</p>
                    <p className="text-xs text-muted-foreground">All platform orders</p>
                  </div>
                  <p className="text-2xl font-bold">{orderStats?.total || 0}</p>
                </div>
                <div className="flex items-center justify-between border-b pb-4">
                  <div>
                    <p className="font-medium">Pending Orders</p>
                    <p className="text-xs text-muted-foreground">Awaiting processing</p>
                  </div>
                  <p className="text-2xl font-bold">{orderStats?.pending || 0}</p>
                </div>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">Delivered Orders</p>
                    <p className="text-xs text-muted-foreground">Successfully completed</p>
                  </div>
                  <p className="text-2xl font-bold">{orderStats?.delivered || 0}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="stores">
          <Card>
            <CardHeader>
              <CardTitle>Store Statistics</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between border-b pb-4">
                  <div>
                    <p className="font-medium">Total Stores</p>
                    <p className="text-xs text-muted-foreground">All registered</p>
                  </div>
                  <p className="text-2xl font-bold">{storeStats?.total || 0}</p>
                </div>
                <div className="flex items-center justify-between border-b pb-4">
                  <div>
                    <p className="font-medium">Verified Stores</p>
                    <p className="text-xs text-muted-foreground">Active sellers</p>
                  </div>
                  <p className="text-2xl font-bold">{storeStats?.verified || 0}</p>
                </div>
                <div className="flex items-center justify-between border-b pb-4">
                  <div>
                    <p className="font-medium">AI Service Active</p>
                    <p className="text-xs text-muted-foreground">Using AI assistant</p>
                  </div>
                  <p className="text-2xl font-bold">{storeStats?.withAI || 0}</p>
                </div>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">Premium Stores</p>
                    <p className="text-xs text-muted-foreground">Paid subscriptions</p>
                  </div>
                  <p className="text-2xl font-bold">{storeStats?.premium || 0}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
