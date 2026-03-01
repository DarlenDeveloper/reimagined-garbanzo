import { DataTable } from "@components/data-table/data-table";
import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Store, Clock, CheckCircle, XCircle } from "lucide-react";
import { columns } from "./components/columns";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { usePendingStoreVerifications, useStoreStats } from "@apis/queries/useStores";

export function StoreVerificationPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: pendingStores, isLoading } = usePendingStoreVerifications();
  const { data: statsData } = useStoreStats();

  const stats = [
    { title: "Pending", value: (pendingStores?.length || 0).toString(), icon: Clock, description: "Awaiting review" },
    { title: "Verified", value: (statsData?.verified || 0).toString(), icon: CheckCircle, description: "Active stores" },
    { title: "Total Stores", value: (statsData?.total || 0).toString(), icon: Store, description: "All registered" },
    { title: "Unverified", value: (statsData ? statsData.total - statsData.verified : 0).toString(), icon: XCircle, description: "Need verification" },
  ];

  return (
    <div className="space-y-4">
      <PageTitle title="Store Verification" desc="Review and approve store verification requests" />

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
          <CardTitle>Pending Verifications</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={pendingStores || []}
            columns={columns}
            manualPagination={false}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={pendingStores?.length || 0}
            loading={isLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
