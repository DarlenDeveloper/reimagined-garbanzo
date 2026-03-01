import { DataTable } from "@components/data-table/data-table";
import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Truck, Clock, CheckCircle } from "lucide-react";
import { columns } from "./components/columns";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { usePendingCourierVerifications, useCourierStats } from "@apis/queries/useCouriers";

export function CourierVerificationPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: pendingCouriers, isLoading } = usePendingCourierVerifications();
  const { data: statsData } = useCourierStats();

  const stats = [
    { title: "Pending", value: (pendingCouriers?.length || 0).toString(), icon: Clock, description: "Awaiting review" },
    { title: "Active Couriers", value: (statsData?.active || 0).toString(), icon: CheckCircle, description: "Verified & active" },
    { title: "Online Now", value: (statsData?.online || 0).toString(), icon: Truck, description: "Currently available" },
    { title: "Total Couriers", value: (statsData?.total || 0).toString(), icon: Truck, description: "All registered" },
  ];

  return (
    <div className="space-y-4">
      <PageTitle title="Courier Verification" desc="Review and approve courier applications" />

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
          <CardTitle>Pending Applications</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={pendingCouriers || []}
            columns={columns}
            manualPagination={false}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={pendingCouriers?.length || 0}
            loading={isLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
