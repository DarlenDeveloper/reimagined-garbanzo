import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { DataTable } from "@components/data-table/data-table";
import { columns, Courier } from "./components/columns";
import { Truck, CheckCircle, Ban, TrendingUp } from "lucide-react";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { useCouriers, useCourierStats } from "@apis/queries/useCouriers";

export function CouriersPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: couriersData, isLoading: couriersLoading } = useCouriers(paginationState);
  const { data: statsData } = useCourierStats();

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Couriers</h1>
        <p className="text-muted-foreground">Manage all delivery personnel</p>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Couriers</CardTitle>
            <Truck className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{statsData?.total || 0}</div>
            <p className="text-xs text-muted-foreground">All registered couriers</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Couriers</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{statsData?.active || 0}</div>
            <p className="text-xs text-muted-foreground">{statsData?.total ? Math.round((statsData.active / statsData.total) * 100) : 0}% of total</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Online Now</CardTitle>
            <Truck className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{statsData?.online || 0}</div>
            <p className="text-xs text-muted-foreground">Available for delivery</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Rating</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{(statsData?.avgRating || 0).toFixed(1)}</div>
            <p className="text-xs text-muted-foreground">⭐ Service quality</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Couriers</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={couriersData?.data || []}
            columns={columns}
            manualPagination={true}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={couriersData?.total || 0}
            loading={couriersLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
