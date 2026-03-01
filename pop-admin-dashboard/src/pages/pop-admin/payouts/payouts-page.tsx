import { DataTable } from "@components/data-table/data-table";
import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Wallet, Clock, CheckCircle, XCircle } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@components/ui/tabs";
import { storeColumns } from "./components/store-columns";
import { courierColumns } from "./components/courier-columns";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { usePayouts, usePayoutStats } from "@apis/queries/usePayouts";

export function PayoutsPage() {
  const [storePagination, setStorePagination] = useState<PaginationState>({ pageIndex: 0, pageSize: 10 });
  const [courierPagination, setCourierPagination] = useState<PaginationState>({ pageIndex: 0, pageSize: 10 });

  const { data: storePayoutsData, isLoading: storeLoading } = usePayouts(storePagination, 'store');
  const { data: courierPayoutsData, isLoading: courierLoading } = usePayouts(courierPagination, 'courier');
  const { data: storeStats } = usePayoutStats('store');
  const { data: courierStats } = usePayoutStats('courier');

  const totalPending = (storeStats?.pendingAmount || 0) + (courierStats?.pendingAmount || 0);
  const totalCompleted = (storeStats?.completedAmount || 0) + (courierStats?.completedAmount || 0);

  const stats = [
    { title: "Pending Payouts", value: `UGX ${(totalPending / 1000000).toFixed(1)}M`, icon: Clock, description: `${(storeStats?.pending || 0) + (courierStats?.pending || 0)} requests` },
    { title: "Processing", value: "UGX 0M", icon: Wallet, description: "0 requests" },
    { title: "Completed (Month)", value: `UGX ${(totalCompleted / 1000000).toFixed(1)}M`, icon: CheckCircle, description: `${(storeStats?.completed || 0) + (courierStats?.completed || 0)} payouts` },
    { title: "Rejected", value: "UGX 0K", icon: XCircle, description: "0 requests" },
  ];

  return (
    <div className="space-y-4">
      <PageTitle title="Payout Management" desc="Process store and courier payout requests" />

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

      <Tabs defaultValue="stores" className="space-y-4">
        <TabsList>
          <TabsTrigger value="stores">Store Payouts</TabsTrigger>
          <TabsTrigger value="couriers">Courier Payouts</TabsTrigger>
        </TabsList>
        
        <TabsContent value="stores">
          <Card>
            <CardHeader>
              <CardTitle>Store Payout Requests</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={storePayoutsData?.data || []}
                columns={storeColumns}
                manualPagination={true}
                paginationState={storePagination}
                onPaginationChange={setStorePagination}
                rowCount={storePayoutsData?.total || 0}
                loading={storeLoading}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="couriers">
          <Card>
            <CardHeader>
              <CardTitle>Courier Payout Requests</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={courierPayoutsData?.data || []}
                columns={courierColumns}
                manualPagination={true}
                paginationState={courierPagination}
                onPaginationChange={setCourierPagination}
                rowCount={courierPayoutsData?.total || 0}
                loading={courierLoading}
              />
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
