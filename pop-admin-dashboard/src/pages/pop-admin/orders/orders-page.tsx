import { DataTable } from "@components/data-table/data-table";
import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { ShoppingCart, Clock, CheckCircle, TrendingUp } from "lucide-react";
import { columns } from "./components/columns";
import { useState } from "react";
import type { PaginationState } from "@tanstack/react-table";
import { useOrders, useOrderStats } from "@apis/queries/useOrders";

export function OrdersPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: ordersData, isLoading: ordersLoading } = useOrders(paginationState);
  const { data: statsData } = useOrderStats();

  const stats = [
    { title: "Total Orders", value: (statsData?.total || 0).toLocaleString(), icon: ShoppingCart, description: "All platform orders" },
    { title: "Pending", value: (statsData?.pending || 0).toLocaleString(), icon: Clock, description: "Awaiting confirmation" },
    { title: "Delivered", value: (statsData?.delivered || 0).toLocaleString(), icon: CheckCircle, description: `${statsData?.total ? Math.round((statsData.delivered / statsData.total) * 100) : 0}% success rate` },
    { title: "Total Revenue", value: `UGX ${((statsData?.totalRevenue || 0) / 1000000).toFixed(1)}M`, icon: TrendingUp, description: `Commission: UGX ${((statsData?.totalCommission || 0) / 1000000).toFixed(1)}M` },
  ];

  return (
    <div className="space-y-4">
      <PageTitle title="Order Management" desc="Monitor and manage all platform orders" />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground">{stat.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Orders</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={ordersData?.data || []}
            columns={columns}
            manualPagination={true}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={ordersData?.total || 0}
            loading={ordersLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
