import { DataTable } from "@components/data-table/data-table";
import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { DollarSign, CreditCard, Smartphone, AlertCircle } from "lucide-react";
import { columns } from "./components/columns";
import { useState } from "react";
import type { PaginationState } from "@tanstack/react-table";
import { usePayments, usePaymentStats } from "@apis/queries/usePayments";

export function PaymentsPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: paymentsData, isLoading: paymentsLoading } = usePayments(paginationState);
  const { data: statsData } = usePaymentStats();

  const stats = [
    { title: "Total Revenue", value: `UGX ${((statsData?.totalRevenue || 0) / 1000000).toFixed(1)}M`, icon: DollarSign, description: "All completed payments" },
    { title: "Card Payments", value: `UGX ${((statsData?.cardPayments || 0) / 1000000).toFixed(1)}M`, icon: CreditCard, description: `${statsData?.totalRevenue ? Math.round((statsData.cardPayments / statsData.totalRevenue) * 100) : 0}% of total` },
    { title: "Mobile Money", value: `UGX ${((statsData?.mobilePayments || 0) / 1000000).toFixed(1)}M`, icon: Smartphone, description: `${statsData?.totalRevenue ? Math.round((statsData.mobilePayments / statsData.totalRevenue) * 100) : 0}% of total` },
    { title: "Failed Payments", value: (statsData?.failedCount || 0).toLocaleString(), icon: AlertCircle, description: "Failed transactions" },
  ];

  return (
    <div className="space-y-4">
      <PageTitle title="Payment Management" desc="Monitor all payment transactions and revenue" />

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
          <CardTitle>All Payments</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={paymentsData?.data || []}
            columns={columns}
            manualPagination={true}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={paymentsData?.total || 0}
            loading={paymentsLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
